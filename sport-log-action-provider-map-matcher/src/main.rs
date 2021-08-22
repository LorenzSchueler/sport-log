use std::{
    env,
    fs::{self, File},
};

use chrono::{Duration, Utc};
use geo_types::Point;
use gpx::{self, Gpx, GpxVersion, Track, TrackSegment, Waypoint};
use rand::Rng;
use reqwest::Client;
use serde::{Deserialize, Serialize};

use sport_log_ap_utils::{delete_events, get_events, setup as setup_db};
use sport_log_types::{CardioSession, Position, Route, RouteId};
use tokio::process::Command;

const NAME: &str = "map-matcher";
const DESCRIPTION: &str =
    "Map Matcher will try to match GPX tracks to the closest path that exists in OSM.";
const PLATFORM_NAME: &str = "sport-log";

#[derive(Deserialize)]
struct Config {
    password: String,
    base_url: String,
}

impl Config {
    fn get() -> Self {
        toml::from_str(&fs::read_to_string("config.toml").unwrap()).unwrap()
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
async fn main() {
    match &env::args().collect::<Vec<_>>()[1..] {
        [] => map_match().await,
        [option] if option == "--setup" => setup().await,
        [option] if ["help", "-h", "--help"].contains(&option.as_str()) => help(),
        _ => wrong_use(),
    }
}

async fn setup() {
    let config = Config::get();

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
    .await;
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

async fn map_match() {
    let config = Config::get();

    let client = Client::new();

    let exec_action_events = get_events(
        &client,
        &config.base_url,
        NAME,
        &config.password,
        Duration::hours(0),
        Duration::hours(1),
    )
    .await;
    println!("executable action events: {}\n", exec_action_events.len());

    let mut delete_action_event_ids = vec![];
    for exec_action_event in exec_action_events {
        println!("{:#?}", exec_action_event);

        let username = format!("{}$id${}", NAME, exec_action_event.user_id.0);

        let mut cardio_sessions: Vec<CardioSession> = client
            .get(format!("{}/v1/cardio_session", config.base_url))
            .basic_auth(&username, Some(&config.password))
            .send()
            .await
            .unwrap()
            .json()
            .await
            .unwrap();

        println!("cardio sessions:\t{}", cardio_sessions.len());

        for cardio_session in &mut cardio_sessions[0..1] {
            let route = match_to_map(cardio_session).await.unwrap();

            let routes: Vec<Route> = client
                .get(format!("{}/v1/route", config.base_url))
                .basic_auth(&username, Some(&config.password))
                .send()
                .await
                .unwrap()
                .json()
                .await
                .unwrap();

            if let Some(route_id) = compare_routes(&route, &routes) {
                cardio_session.route_id = Some(route_id);
            } else {
                match client
                    .post(format!("{}/v1/route", config.base_url))
                    .basic_auth(&username, Some(&config.password))
                    .json(&route)
                    .send()
                    .await
                    .unwrap()
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
                .json(cardio_session)
                .send()
                .await
                .unwrap()
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
        .await;
    }
}

async fn match_to_map(cardio_session: &CardioSession) -> Result<Route, ()> {
    let gpx = to_gpx(cardio_session)?;

    let mut rng = rand::thread_rng();
    let filename = format!("/tmp/map-matcher-{}.gpx", rng.gen::<u64>());
    let filename_result = format!("{}{}", filename, ".res.gpx");
    gpx::write(&gpx, File::create(&filename).unwrap()).unwrap();

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
        .unwrap();

    if !output.status.success() {
        println!("{:?}", output);
        return Err(());
    }

    let gpx = gpx::read(File::open(&filename_result).unwrap()).unwrap();

    fs::remove_file(&filename).unwrap();
    fs::remove_file(&filename_result).unwrap();

    Ok(to_route(gpx, cardio_session).await)
}

fn to_gpx(cardio_session: &CardioSession) -> Result<Gpx, ()> {
    if let Some(positions) = &cardio_session.track {
        let mut track = Track::new();
        let mut track_segment = TrackSegment::new();
        let waypoints: Vec<_> = positions
            .iter()
            .map(|position| Waypoint::new(Point::new(position.longitude, position.latitude)))
            .collect();
        track_segment.points.extend(waypoints);
        track.segments.push(track_segment);
        let gpx = Gpx {
            version: GpxVersion::Gpx10,
            creator: None,
            metadata: None,
            waypoints: vec![],
            tracks: vec![track],
            routes: vec![],
        };
        Ok(gpx)
    } else {
        Err(())
    }
}

async fn to_route(gpx: Gpx, cardio_session: &CardioSession) -> Route {
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
        .unwrap()
        .json()
        .await
        .unwrap();

    let positions: Vec<_> = response_data
        .results
        .iter()
        .map(|point| {
            Position {
                longitude: point.longitude,
                latitude: point.latitude,
                elevation: point.elevation,
                distance: 0, // TODO
                time: 0,     // TODO
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
                ascent += diff;
            }
            (ascent, descent, next)
        },
    );

    let mut rng = rand::thread_rng();
    Route {
        id: RouteId(rng.gen()),
        user_id: cardio_session.user_id,
        name: format!("{} workout route", cardio_session.datetime),
        distance: cardio_session.distance.unwrap(), // calc new
        ascent: Some(ascent as i32),
        descent: Some(descent as i32),
        track: positions,
        last_change: Utc::now(),
        deleted: false,
    }
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
