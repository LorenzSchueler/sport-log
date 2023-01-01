//! **Map Matcher** is an [ActionProvider](sport_log_types::ActionProvider) which matches GPS tracks to the nearest path in OSM.
//!
//! Like all [ActionProvider](sport_log_types::ActionProvider) **Map Matcher** executes [ActionEvents](sport_log_types::ActionEvent).
//! The `arguments` field has to be a valid [CardioSessionId] for which the GPS track should be matched.
//!
//! The resulting path will be converted into a [Route] and compared to all [Routes](Route) of the [User](sport_log_types::User).
//! If no similar [Route] is found the new [Route] will be saved.
//! The `route_id` field of the [CardioSession] will be updated to the id of the new [Route] or a similar existing [Route] if one exists.
//!
//! # Time of execution
//!
//! [ActionEvents](sport_log_types::ActionEvent) will be executed if their `datetime` lies (up to 7 days) in the past.
//!
//! # Usage
//!
//! The **Map Matcher** has do be executed periodically, preferably as a cron job every hour.
//!
//! # Config
//!
//! Please refer to [Config].

use std::{
    env,
    fs::{self, File},
    io::Error as IoError,
    process,
    result::Result as StdResult,
};

use chrono::Duration;
use err_derive::Error as StdError;
use geo_types::Point;
use geoutils::Location as GeoLocation;
use gpx::{self, errors::GpxError, Gpx, GpxVersion, Track, TrackSegment, Waypoint};
use lazy_static::lazy_static;
use rand::Rng;
use reqwest::{Client, Error as ReqwestError};
use serde::{Deserialize, Serialize};
use sport_log_ap_utils::{disable_events, get_events, setup as setup_db};
use sport_log_types::{ActionEventId, CardioSession, CardioSessionId, Position, Route, RouteId};
use tokio::process::Command;
use tracing::{debug, error, info};

pub const CONFIG_FILE: &str = "sport-log-action-provider-map-matcher.toml";
const NAME: &str = "map-matcher";
const DESCRIPTION: &str =
    "Map Matcher will try to match GPX tracks to the closest path that exists in OSM.";
const PLATFORM_NAME: &str = "sport-log";

#[derive(Debug, StdError)]
enum Error {
    #[error(display = "{}", _0)]
    Reqwest(ReqwestError),
    #[error(display = "{}", _0)]
    Io(IoError),
    #[error(display = "{}", _0)]
    Gpx(GpxError),
    #[error(display = "ExecutableActionEvent doesn't contain a valid CardioSessionId")]
    CardioSessionIdMissing(ActionEventId),
    #[error(display = "CardioSession doesn't contain a Track")]
    NoTrack(ActionEventId),
}

type Result<T> = StdResult<T, Error>;

/// The config for [sport-log-action-provider-map-matcher](crate).
///
/// The name of the config file is specified in [CONFIG_FILE].
///
/// `admin_password` is the password for the admin endpoints.
///
/// `base_url` is the left part of the URL (everything before `/<version>/...`)
#[derive(Deserialize)]
pub struct Config {
    password: String,
    base_url: String,
}

lazy_static! {
    pub static ref CONFIG: Config = match fs::read_to_string(CONFIG_FILE) {
        Ok(file) => match toml::from_str(&file) {
            Ok(config) => config,
            Err(error) => {
                error!("Failed to parse {}: {}", CONFIG_FILE, error);
                process::exit(1);
            }
        },
        Err(error) => {
            error!("Failed to read {}: {}", CONFIG_FILE, error);
            process::exit(1);
        }
    };
}

#[derive(Serialize, Debug)]
struct RequestData {
    locations: Vec<Location>,
}

#[derive(Serialize, Debug)]
struct Location {
    latitude: f64,
    longitude: f64,
}

#[derive(Deserialize, Debug)]
struct ResponseData {
    results: Vec<LocationElevation>,
}

#[derive(Deserialize, Debug)]
struct LocationElevation {
    latitude: f64,
    longitude: f64,
    elevation: i32,
}

#[tokio::main]
async fn main() {
    if cfg!(debug_assertions) {
        env::set_var(
            "RUST_LOG",
            "info,sport_log_action_provider_map_matcher=debug",
        );
    } else {
        env::set_var("RUST_LOG", "warn");
    }

    tracing_subscriber::fmt()
        .with_writer(std::io::stderr)
        .init();

    match &env::args().collect::<Vec<_>>()[1..] {
        [] => {
            if let Err(error) = map_match().await {
                error!("map matching failed: {}", error);
            }
        }
        [option] if option == "--setup" => {
            if let Err(error) = setup().await {
                error!("setup failed: {}", error);
            }
        }
        [option] if ["help", "-h", "--help"].contains(&option.as_str()) => help(),
        _ => wrong_use(),
    };
}

async fn setup() -> Result<()> {
    setup_db(
        &CONFIG.base_url,
        NAME,
        &CONFIG.password,
        DESCRIPTION,
        PLATFORM_NAME,
        false,
        &[("match", "Match a gpx track to as OSM path.")],
        168,
        168,
    )
    .await
    .map_err(Error::Reqwest)
}

fn help() {
    println!(
        "Map Matcher\n\n\
        USAGE:\n\
        sport-log-action-provider-map-matcher [OPTIONS]\n\n\
        OPTIONS:\n\
        -h, --help\tprint this help page\n\
        --setup\t\tcreate own actions"
    );
}

fn wrong_use() {
    println!("no such options");
}

async fn map_match() -> Result<()> {
    let client = Client::new();

    let exec_action_events = get_events(
        &client,
        &CONFIG.base_url,
        NAME,
        &CONFIG.password,
        Duration::hours(-168),
        Duration::hours(0),
    )
    .await
    .map_err(Error::Reqwest)?;

    info!("got {} executable action events", exec_action_events.len());

    let mut tasks = vec![];
    for exec_action_event in exec_action_events {
        let client = client.clone();

        tasks.push(tokio::spawn(async move {
            info!("processing {:#?}", exec_action_event);

            let username = format!("{}$id${}", NAME, exec_action_event.user_id.0);

            let cardio_session_id: CardioSessionId = exec_action_event
                .arguments
                .and_then(|arg| arg.parse().ok())
                .map(CardioSessionId)
                .ok_or(Error::CardioSessionIdMissing(
                    exec_action_event.action_event_id,
                ))?;

            let mut cardio_session: CardioSession = client
                .get(format!(
                    "{}/v0.2/cardio_session/{}",
                    CONFIG.base_url, cardio_session_id.0
                ))
                .basic_auth(&username, Some(&CONFIG.password))
                .send()
                .await
                .map_err(Error::Reqwest)?
                .json()
                .await
                .map_err(Error::Reqwest)?;

            let route = match_to_map(&cardio_session, exec_action_event.action_event_id).await?;

            let routes: Vec<Route> = client
                .get(format!("{}/v0.2/route", CONFIG.base_url))
                .basic_auth(&username, Some(&CONFIG.password))
                .send()
                .await
                .map_err(Error::Reqwest)?
                .json()
                .await
                .map_err(Error::Reqwest)?;

            if let Some(route_id) = compare_routes(&route, &routes) {
                cardio_session.route_id = Some(route_id);
            } else {
                client
                    .post(format!("{}/v0.2/route", CONFIG.base_url))
                    .basic_auth(&username, Some(&CONFIG.password))
                    .json(&route)
                    .send()
                    .await
                    .map_err(Error::Reqwest)?;
            }

            client
                .put(format!("{}/v0.2/cardio_session", CONFIG.base_url))
                .basic_auth(&username, Some(&CONFIG.password))
                .json(&cardio_session)
                .send()
                .await
                .map_err(Error::Reqwest)?;

            Result::Ok(exec_action_event.action_event_id)
        }));
    }

    let mut delete_action_event_ids = vec![];
    for task in tasks {
        match task.await {
            Ok(result) => match result {
                Ok(action_event_id) => delete_action_event_ids.push(action_event_id),
                Err(Error::CardioSessionIdMissing(action_event_id)) => {
                    delete_action_event_ids.push(action_event_id)
                }
                Err(Error::NoTrack(action_event_id)) => {
                    delete_action_event_ids.push(action_event_id)
                }
                Err(error) => error!("{}", error),
            },
            Err(join_error) => error!("execution of action event failed: {}", join_error),
        }
    }

    if !delete_action_event_ids.is_empty() {
        disable_events(
            &client,
            &CONFIG.base_url,
            NAME,
            &CONFIG.password,
            &delete_action_event_ids,
        )
        .await
        .map_err(Error::Reqwest)?;
    }

    Ok(())
}

async fn match_to_map(
    cardio_session: &CardioSession,
    action_event_id: ActionEventId,
) -> Result<Route> {
    let track = match &cardio_session.track {
        Some(track) => track,
        None => return Err(Error::NoTrack(action_event_id)),
    };

    let gpx = to_gpx(track);

    let filename = format!("/tmp/map-matcher-{}.gpx", rand::thread_rng().gen::<u64>());
    let filename_result = format!("{}{}", filename, ".res.gpx");
    gpx::write(&gpx, File::create(&filename).map_err(Error::Io)?).map_err(Error::Gpx)?;

    let output = Command::new("java")
        .args([
            "-jar",
            "matching-web/target/graphhopper-map-matching-web-3.0-SNAPSHOT.jar",
            "match",
            "--vehicle",
            "foot",
            &filename,
        ])
        .current_dir("map-matching")
        .output()
        .await
        .map_err(Error::Io)?;

    if !output.status.success() {
        debug!("output: {:?}", output);
    }

    let gpx = gpx::read(File::open(&filename_result).map_err(Error::Io)?).map_err(Error::Gpx)?;

    fs::remove_file(&filename).map_err(Error::Io)?;
    fs::remove_file(&filename_result).map_err(Error::Io)?;

    to_route(gpx, cardio_session).await
}

fn to_gpx(positions: &[Position]) -> Gpx {
    let mut track = Track::new();
    let mut track_segment = TrackSegment::new();
    let waypoints: Vec<_> = positions
        .iter()
        .map(|position| Waypoint::new(Point::new(position.longitude, position.latitude)))
        .collect();
    track_segment.points.extend(waypoints);
    track.segments.push(track_segment);

    Gpx {
        version: GpxVersion::Gpx10,
        creator: None,
        metadata: None,
        waypoints: vec![],
        tracks: vec![track],
        routes: vec![],
    }
}

async fn to_route(gpx: Gpx, cardio_session: &CardioSession) -> Result<Route> {
    let points = &gpx.tracks[0].segments[0].points;

    let locations = points
        .iter()
        .map(|point| {
            let point = point.point();
            Location {
                latitude: point.y(),
                longitude: point.x(),
            }
        })
        .collect();
    let request_data = RequestData { locations };

    let client = Client::new();
    let response_data: ResponseData = client
        .post("https://api.open-elevation.com/api/v1/lookup")
        .json(&request_data)
        .send()
        .await
        .map_err(Error::Reqwest)?
        .json()
        .await
        .map_err(Error::Reqwest)?;

    let mut distance = 0.;
    let mut prev_point = GeoLocation::new(
        response_data.results[0].latitude,
        response_data.results[0].longitude,
    );
    let positions: Vec<_> = response_data
        .results
        .iter()
        .map(|point| {
            let next_point = GeoLocation::new(point.latitude, point.longitude);
            distance += prev_point.haversine_distance_to(&next_point).meters();
            prev_point = next_point;

            Position {
                longitude: point.longitude,
                latitude: point.latitude,
                elevation: point.elevation as f64,
                distance,
                time: 0,
            }
        })
        .collect();

    let (ascent, descent, _) = positions.iter().fold(
        (0.0, 0.0, &positions[0]),
        |(mut ascent, mut descent, prev), next| {
            let diff = prev.elevation - next.elevation;
            if diff > 0.0 {
                descent += diff;
            } else {
                ascent += -diff;
            }
            (ascent, descent, next)
        },
    );

    Ok(Route {
        id: RouteId(rand::thread_rng().gen()),
        user_id: cardio_session.user_id,
        name: format!("{} workout route", cardio_session.datetime),
        distance: positions
            .last()
            .map(|position| position.distance)
            .unwrap_or(0.0)
            .round() as i32,
        ascent: Some(ascent.round() as i32),
        descent: Some(descent.round() as i32),
        track: Some(positions),
        marked_positions: None,
        deleted: false,
    })
}

/// This function relies on the fact that routes generated by the map matcher only contain the coordinates of the path in OSM.
/// Thereby it is possible to compare the points directly without having to bother with more compute intensive comparisons between the routes.
fn compare_routes(route: &Route, routes: &[Route]) -> Option<RouteId> {
    const MAX_MISSES: i32 = 10;
    const MAX_CONT_MISSES: i32 = 20;

    'route_loop: for old_route in routes {
        if let (Some(track), Some(old_track)) = (&route.track, &old_route.track) {
            if (route.distance - old_route.distance).abs() > route.distance / MAX_MISSES {
                continue 'route_loop;
            }
            if (track.len() as i32 - old_track.len() as i32).abs() > track.len() as i32 / MAX_MISSES
            {
                continue 'route_loop;
            }
            let coords: Vec<_> = track
                .iter()
                .map(|position| (position.latitude, position.longitude))
                .collect();
            let old_coords: Vec<_> = old_track
                .iter()
                .map(|position| (position.latitude, position.longitude))
                .collect();
            let mut misses = 0;
            let mut cont_misses = 0;
            let mut idx = 0;
            let mut old_idx = 0;
            'match_loop: loop {
                if misses > track.len() as i32 / MAX_MISSES
                    || cont_misses > track.len() as i32 / MAX_CONT_MISSES
                {
                    continue 'route_loop;
                }
                if idx == coords.len() || old_idx == coords.len() {
                    break 'match_loop;
                }
                if coords[idx] == old_coords[old_idx] {
                    cont_misses = 0;
                    idx += 1;
                    old_idx += 1;
                } else {
                    // find next match within MAX_CONT_MISSES
                    misses += 1;
                    cont_misses += 1;
                    let end = usize::min(
                        idx + coords.len() / MAX_CONT_MISSES as usize,
                        coords.len() - 1,
                    );
                    let old_end = usize::min(
                        old_idx + old_coords.len() / MAX_CONT_MISSES as usize,
                        old_coords.len() - 1,
                    );
                    for (i, coord) in coords[idx..end].iter().enumerate() {
                        for (old_i, old_coord) in old_coords[old_idx..old_end].iter().enumerate() {
                            if coord == old_coord {
                                idx = i;
                                old_idx = old_i;
                                continue 'match_loop;
                            }
                        }
                    }
                    break 'match_loop;
                }
            }
            if misses > track.len() as i32 / MAX_MISSES
                || cont_misses > track.len() as i32 / MAX_CONT_MISSES
            {
                continue 'route_loop;
            } else {
                return Some(old_route.id);
            }
        }
    }

    None
}
