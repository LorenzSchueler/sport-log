use std::{
    env,
    fs::{self, File},
};

use chrono::{Duration, Utc};
use geo_types::Point;
use gpx::{self, Gpx, GpxVersion, Track, TrackSegment, Waypoint};
use rand::Rng;
use reqwest::Client;
use serde::Deserialize;

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

        for cardio_session in &mut cardio_sessions[1..2] {
            let route = match_to_map(cardio_session).await.unwrap();

            cardio_session.route_id = Some(route.id);

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
    gpx::write(&gpx, File::create("tracks/trackX.gpx").unwrap()).unwrap();

    let output = Command::new("java")
        .args(&[
            "-jar",
            "matching-web/target/graphhopper-map-matching-web-3.0-SNAPSHOT.jar",
            "match",
            "--vehicle",
            "foot",
            "../tracks/trackX.gpx",
        ])
        .current_dir("map-matching")
        .output()
        .await
        .unwrap();

    if !output.status.success() {
        println!("{:?}", output);
        return Err(());
    }

    //let gpx = gpx::read(Cursor::new(output.stdout)).unwrap();
    let gpx = gpx::read(File::open("tracks/trackX.gpx.res.gpx").unwrap()).unwrap();

    Ok(to_route(gpx, cardio_session))
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

fn to_route(gpx: Gpx, cardio_session: &CardioSession) -> Route {
    let track = &gpx.tracks[0];
    let track_segment = &track.segments[0];
    let points = &track_segment.points;
    let positions = points
        .iter()
        .map(|point| {
            let point = point.point();
            Position {
                longitude: point.lng(),
                latitude: point.lat(),
                elevation: 0., // TODO
                distance: 0,   // TODO
                time: 0,       // TODO
            }
        })
        .collect();

    let mut rng = rand::thread_rng();
    Route {
        id: RouteId(rng.gen()),
        user_id: cardio_session.user_id,
        name: format!("{} workout route", cardio_session.datetime),
        distance: cardio_session.distance.unwrap(), // calc new
        ascent: cardio_session.ascent,              // calc new
        descent: cardio_session.descent,            // calc new
        track: Some(positions),
        last_change: Utc::now(),
        deleted: false,
    }
}
