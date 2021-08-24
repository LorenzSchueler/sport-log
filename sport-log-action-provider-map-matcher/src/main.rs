use std::{
    env,
    fs::{self, File},
    io::Error as IoError,
    result::Result as StdResult,
};

use chrono::{Duration, Utc};
use err_derive::Error as StdError;
use geo_types::Point;
use geoutils::Location as GeoLocation;
use gpx::{self, errors::Error as GpxError, Gpx, GpxVersion, Track, TrackSegment, Waypoint};
use rand::Rng;
use reqwest::{Client, Error as ReqwestError};
use serde::{Deserialize, Serialize};
use toml::de::Error as TomlError;

use sport_log_ap_utils::{delete_events, get_events, setup as setup_db};
use sport_log_types::{CardioSession, CardioSessionId, Position, Route, RouteId};
use tokio::process::Command;

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
    Toml(TomlError),
    #[error(display = "{}", _0)]
    Gpx(GpxError),
}

type Result<T> = StdResult<T, Error>;

#[derive(Deserialize)]
struct Config {
    password: String,
    base_url: String,
}

impl Config {
    fn get() -> Result<Self> {
        toml::from_str(&fs::read_to_string("config.toml").map_err(Error::Io)?).map_err(Error::Toml)
    }
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
async fn main() -> Result<()> {
    match &env::args().collect::<Vec<_>>()[1..] {
        [] => map_match().await,
        [option] if option == "--setup" => setup().await,
        [option] if ["help", "-h", "--help"].contains(&option.as_str()) => {
            help();
            Ok(())
        }
        _ => {
            wrong_use();
            Ok(())
        }
    }
}

async fn setup() -> Result<()> {
    let config = Config::get()?;

    setup_db(
        &config.base_url,
        NAME,
        &config.password,
        DESCRIPTION,
        PLATFORM_NAME,
        false,
        &[("match", "Match a gpx track to as OSM path.")],
        168,
        0,
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
    let config = Config::get()?;

    let client = Client::new();

    let exec_action_events = get_events(
        &client,
        &config.base_url,
        NAME,
        &config.password,
        Duration::hours(0),
        Duration::hours(1),
    )
    .await
    .map_err(Error::Reqwest)?;
    println!("executable action events: {}\n", exec_action_events.len());

    let mut delete_action_event_ids = vec![];
    for exec_action_event in exec_action_events {
        println!("{:#?}", exec_action_event);

        let username = format!("{}$id${}", NAME, exec_action_event.user_id.0);
        let cardio_session_id: CardioSessionId = match exec_action_event
            .arguments
            .map(|arg| arg.parse().ok())
            .flatten()
        {
            Some(arg) => CardioSessionId(arg),
            None => {
                println!("action event has no cardion session id as argument");
                delete_action_event_ids.push(exec_action_event.action_event_id);
                continue;
            }
        };

        let mut cardio_session: CardioSession = client
            .get(format!(
                "{}/v1/cardio_session/{}",
                config.base_url, cardio_session_id.0
            ))
            .basic_auth(&username, Some(&config.password))
            .send()
            .await
            .map_err(Error::Reqwest)?
            .json()
            .await
            .map_err(Error::Reqwest)?;

        let route = match_to_map(&cardio_session).await?;

        let routes: Vec<Route> = client
            .get(format!("{}/v1/route", config.base_url))
            .basic_auth(&username, Some(&config.password))
            .send()
            .await
            .map_err(Error::Reqwest)?
            .json()
            .await
            .map_err(Error::Reqwest)?;

        if let Some(route_id) = compare_routes(&route, &routes) {
            cardio_session.route_id = Some(route_id);
        } else {
            match client
                .post(format!("{}/v1/route", config.base_url))
                .basic_auth(&username, Some(&config.password))
                .json(&route)
                .send()
                .await
                .map_err(Error::Reqwest)?
                .status()
            {
                status if status.is_success() => {
                    println!("route saved");
                }
                status => {
                    println!("error (status {:?})", status);
                    break;
                }
            }
        }

        match client
            .put(format!("{}/v1/cardio_session", config.base_url))
            .basic_auth(&username, Some(&config.password))
            .json(&cardio_session)
            .send()
            .await
            .map_err(Error::Reqwest)?
            .status()
        {
            status if status.is_success() => {
                println!("cardio session saved");
            }
            status => {
                println!("error (status {:?})", status);
                break;
            }
        }
        delete_action_event_ids.push(exec_action_event.action_event_id);
    }
    if !delete_action_event_ids.is_empty() {
        delete_events(
            &client,
            &config.base_url,
            NAME,
            &config.password,
            &delete_action_event_ids,
        )
        .await
        .map_err(Error::Reqwest)?;
    }
    Ok(())
}

async fn match_to_map(cardio_session: &CardioSession) -> Result<Route> {
    let gpx = to_gpx(cardio_session.track.as_ref().unwrap()); // function only called if track is not None

    let mut rng = rand::thread_rng();
    let filename = format!("/tmp/map-matcher-{}.gpx", rng.gen::<u64>());
    let filename_result = format!("{}{}", filename, ".res.gpx");
    gpx::write(&gpx, File::create(&filename).map_err(Error::Io)?).map_err(Error::Gpx)?;

    let output = Command::new("java")
        .args(&[
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
        println!("{:?}", output);
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
                latitude: point.lat(),
                longitude: point.lng(),
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
                elevation: point.elevation,
                distance: distance as i32,
                time: 0,
            }
        })
        .collect();

    let (ascent, descent, _) = positions.iter().fold(
        (0, 0, &positions[0]),
        |(mut ascent, mut descent, prev), next| {
            let diff = prev.elevation - next.elevation;
            if diff > 0 {
                descent += diff;
            } else {
                ascent += -diff;
            }
            (ascent, descent, next)
        },
    );

    let mut rng = rand::thread_rng();
    Ok(Route {
        id: RouteId(rng.gen()),
        user_id: cardio_session.user_id,
        name: format!("{} workout route", cardio_session.datetime),
        distance: positions.last().unwrap().distance,
        ascent: Some(ascent as i32),
        descent: Some(descent as i32),
        track: positions,
        last_change: Utc::now(),
        deleted: false,
    })
}

/// This function relies on the fact that routes generated by the map matcher only contain the coordinates of the path in OSM.
/// Thereby it is possible to compare the points directly without having to bother with more compute internsive comparisons between the routes.
fn compare_routes(route: &Route, routes: &[Route]) -> Option<RouteId> {
    const MAX_MISSES: i32 = 10;
    const MAX_CONT_MISSES: i32 = 20;

    'route_loop: for old_route in routes {
        if (route.distance - old_route.distance).abs() > route.distance / MAX_MISSES {
            continue 'route_loop;
        }
        if (route.track.len() as i32 - old_route.track.len() as i32).abs()
            > route.track.len() as i32 / MAX_MISSES
        {
            continue 'route_loop;
        }
        let coords: Vec<_> = route
            .track
            .iter()
            .map(|position| (position.latitude, position.longitude))
            .collect();
        let old_coords: Vec<_> = old_route
            .track
            .iter()
            .map(|position| (position.latitude, position.longitude))
            .collect();
        let mut hits = 0;
        let mut misses = 0;
        let mut cont_misses = 0;
        let mut idx = 0;
        let mut old_idx = 0;
        'match_loop: loop {
            if misses > route.track.len() as i32 / MAX_MISSES
                || cont_misses > route.track.len() as i32 / MAX_CONT_MISSES
            {
                continue 'route_loop;
            }
            if idx == coords.len() || old_idx == coords.len() {
                break 'match_loop;
            }
            if coords[idx] == old_coords[old_idx] {
                hits += 1;
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
        println!("misses: {}", misses);
        println!("cont misses: {}", cont_misses);
        println!("hits: {}", hits);
        if misses > route.track.len() as i32 / MAX_MISSES
            || cont_misses > route.track.len() as i32 / MAX_CONT_MISSES
        {
            continue 'route_loop;
        } else {
            return Some(old_route.id);
        }
    }
    None
}
