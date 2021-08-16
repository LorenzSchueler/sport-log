use std::{env, fs};

use chrono::{DateTime, Duration, NaiveDateTime, Utc};
use rand::Rng;
use reqwest::{Client, StatusCode};
use serde::Deserialize;

use sport_log_ap_utils::{delete_events, get_events, setup as setup_db};
use sport_log_types::{
    Action, ActionId, ActionProvider, ActionProviderId, CardioSession, CardioSessionId, CardioType,
    Movement, Platform, PlatformId, Position, Route, RouteId,
};

const NAME: &str = "sportstracker-fetch";
const DESCRIPTION: &str = "Sportstracker Fetch can fetch the latests workouts recorded with sportstracker and save them in your cardio sessions.";
const PLATFORM_NAME: &str = "sportstracker";

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

#[derive(Deserialize, Debug)]
struct Workout {
    description: Option<String>,
    #[serde(rename(deserialize = "activityId"))]
    activity_id: u32,
    #[serde(rename(deserialize = "startTime"))]
    start_time: u64,
}

#[tokio::main]
async fn main() {
    match &env::args().collect::<Vec<_>>()[1..] {
        [] => fetch().await,
        [option] if option == "--setup" => setup().await,
        [option] if ["help", "-h", "--help"].contains(&option.as_str()) => help(),
        _ => wrong_use(),
    }
}

async fn setup() {
    let config = Config::get();

    let mut rng = rand::thread_rng();

    let platform = Platform {
        id: PlatformId(rng.gen()),
        name: PLATFORM_NAME.to_owned(),
        last_change: Utc::now(),
        deleted: false,
    };

    let action_provider = ActionProvider {
        id: ActionProviderId(rng.gen()),
        name: NAME.to_owned(),
        password: config.password.clone(),
        platform_id: platform.id,
        description: Some(DESCRIPTION.to_owned()),
        last_change: Utc::now(),
        deleted: false,
    };

    let actions = vec![Action {
        id: ActionId(rng.gen()),
        name: "fetch".to_owned(),
        action_provider_id: action_provider.id,
        description: Some("Fetch and save new workouts.".to_owned()),
        create_before: 168,
        delete_after: 0,
        last_change: Utc::now(),
        deleted: false,
    }];

    setup_db(
        &config.base_url,
        NAME,
        &config.password,
        PLATFORM_NAME,
        platform,
        action_provider,
        actions,
    )
    .await;
}

fn help() {
    println!(
        "Sportstracker Action Provider\n\n\

        USAGE:\n\
        sport-log-action-provider-sportstracker [OPTIONS]\n\n\

        OPTIONS:\n\
        -h, --help\tprint this help page\n\
        --setup\t\tcreate own actions"
    );
}

fn wrong_use() {
    println!("no such options");
}

// TODO handle connection errors and ignore everything else errors
async fn fetch() {
    let config = Config::get();

    let client = Client::new();

    let exec_action_events = get_events(
        &client,
        &config.base_url,
        NAME,
        &config.password,
        Duration::hours(0),
        Duration::hours(1) + Duration::minutes(1),
    )
    .await;
    println!("executable action events: {}\n", exec_action_events.len());

    let mut rng = rand::thread_rng();

    let mut delete_action_event_ids = vec![];
    for exec_action_event in exec_action_events {
        println!("{:#?}", exec_action_event);

        let username = format!("{}$id${}", NAME, exec_action_event.user_id.0);

        // get cardio session
        let cardio_session: CardioSession = client
            .get(format!("{}/v1/cardio_session", config.base_url))
            .basic_auth(&username, Some(&config.password))
            .send()
            .await
            .unwrap()
            .json()
            .await
            .unwrap();

        let route = match_to_map(&client, cardio_session).await;

        // as route id to cardio session

        // send route to server

        match client
            .post(format!("{}/v1/cardio_session", config.base_url))
            .basic_auth(&username, Some(&config.password))
            .json(&route)
            .send()
            .await
            .unwrap()
            .status()
        {
            status if status.is_success() => {
                println!("cardio session saved");
            }
            StatusCode::CONFLICT => {
                println!(
                    "everything up to date for user {}",
                    exec_action_event.user_id.0
                );
                break;
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
        .await;
    }
}

async fn match_to_map(client: &Client, cardio_session: CardioSession) -> Option<Route> {
    let xml = to_xml(cardio_session);

    let args = [("profile", "foot"), ("type", "gpx")];
    Some(
        client
            .post("localhost:8989/match")
            .query(&args)
            .body(xml)
            .send()
            .await
            .ok()?
            .json::<Route>()
            .await
            .ok()?,
    )
}

fn to_xml(cardio_session: CardioSession) -> String {
    "".to_owned()
}

fn to_route(xml: String, cardio_session: CardioSession) -> Route {
    let mut rng = rand::thread_rng();
    let track = vec![];

    Route {
        id: RouteId(rng.gen()),
        user_id: cardio_session.user_id,
        name: format!("{} workout route", cardio_session.datetime),
        distance: cardio_session.distance.unwrap(), // calc new
        ascent: cardio_session.ascent,              // calc new
        descent: cardio_session.descent,            // calc new
        track: Some(track),
        last_change: Utc::now(),
        deleted: false,
    }
}
