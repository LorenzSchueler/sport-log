use std::{env, fs, process};

use chrono::{DateTime, Duration, NaiveDateTime, Utc};
use err_derive::Error as StdError;
use lazy_static::lazy_static;
use rand::Rng;
use reqwest::{Client, Error as ReqwestError, StatusCode};
use serde::Deserialize;
use tracing::{debug, error, info, warn};

use sport_log_ap_utils::{disable_events, get_events, setup as setup_db};
use sport_log_types::{
    ActionEventId, CardioSession, CardioSessionId, CardioType, Movement, Position,
};

const CONFIG_FILE: &str = "sport-log-action-provider-sportstracker.toml";
const NAME: &str = "sportstracker-fetch";
const DESCRIPTION: &str = "Sportstracker Fetch can fetch the latests workouts recorded with sportstracker and save them in your cardio sessions.";
const PLATFORM_NAME: &str = "sportstracker";

#[derive(Debug, StdError)]
enum Error {
    #[error(display = "{}", _0)]
    Reqwest(ReqwestError),
    #[error(display = "ExecutableActionEvent doesn't contain credentials")]
    NoCredential(ActionEventId),
    #[error(display = "login failed")]
    LoginFailed(ActionEventId),
}

/// The config for [sport-log-action-provider-sportstracker](crate).
///
/// The name of the config file is specified in [CONFIG_FILE].
///
/// `admin_password` is the password for the admin endpoints.
///
/// `base_url` is the left part of the URL (everthing before `/<version>/...`)
#[derive(Deserialize, Debug)]
struct Config {
    password: String,
    server_url: String,
}

lazy_static! {
    static ref CONFIG: Config = match fs::read_to_string(CONFIG_FILE) {
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

#[derive(Deserialize, Debug)]
struct User {
    #[serde(rename(serialize = "sessionkey", deserialize = "sessionkey"))]
    session_key: Option<String>, // None if login fails
}

#[derive(Deserialize, Debug)]
struct WorkoutKeys {
    payload: Vec<WorkoutKey>,
}

#[derive(Deserialize, Debug)]
struct WorkoutKey {
    #[serde(rename(deserialize = "workoutKey"))]
    workout_key: String,
}

#[derive(Deserialize, Debug)]
struct WorkoutStatsWrapper {
    payload: WorkoutStats,
}

#[derive(Deserialize, Debug)]
struct WorkoutStats {
    description: Option<String>,
    #[serde(rename(deserialize = "activityId"))]
    activity_id: u32,
    #[serde(rename(deserialize = "startTime"))]
    start_time: u64,
    #[serde(rename(deserialize = "totalTime"))]
    total_time: f32,
    #[serde(rename(deserialize = "totalDistance"))]
    total_distance: f32,
    #[serde(rename(deserialize = "totalAscent"))]
    total_ascent: f32,
    #[serde(rename(deserialize = "totalDescent"))]
    total_descent: f32,
    #[serde(rename(deserialize = "stepCount"))]
    step_count: u32,
    #[serde(rename(deserialize = "energyConsumption"))]
    energy_consumption: u16,
}

#[derive(Deserialize, Debug)]
struct WorkoutTrackWrapper {
    payload: WorkoutTrack,
}

#[derive(Deserialize, Debug)]
struct WorkoutTrack {
    locations: Vec<Location>,
}

#[derive(Deserialize, Debug)]
struct Location {
    t: u32,  // seconds since start
    la: f64, // lat
    ln: f64, // lon
    s: u32,  // meter since start
    h: f32,  // height
    #[allow(dead_code)]
    v: u32, // ???
    #[allow(dead_code)]
    d: u64, // timestamp in 1 / 1000 s
}

#[tokio::main]
async fn main() {
    if cfg!(debug_assertions) {
        env::set_var(
            "RUST_LOG",
            "info,sport_log_action_provider_sportstracker=debug",
        );
    } else {
        env::set_var("RUST_LOG", "warn");
    }

    tracing_subscriber::fmt::init();

    match &env::args().collect::<Vec<_>>()[1..] {
        [] => {
            if let Err(error) = fetch().await {
                error!("fetching new workouts failed: {}", error);
            }
        }
        [option] if option == "--setup" => {
            if let Err(error) = setup().await {
                error!("setup failed: {}", error);
            }
        }
        [option] if ["help", "-h", "--help"].contains(&option.as_str()) => help(),
        _ => wrong_use(),
    }
}

async fn setup() -> Result<(), ReqwestError> {
    setup_db(
        &CONFIG.server_url,
        NAME,
        &CONFIG.password,
        DESCRIPTION,
        PLATFORM_NAME,
        true,
        &[("fetch", "Fetch and save new workouts.")],
        168,
        0,
    )
    .await
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

async fn fetch() -> Result<(), ReqwestError> {
    let client = Client::new();

    let exec_action_events = get_events(
        &client,
        &CONFIG.server_url,
        NAME,
        &CONFIG.password,
        Duration::hours(0),
        Duration::hours(1) + Duration::minutes(1),
    )
    .await?;

    info!("got {} executable action events", exec_action_events.len());

    let mut tasks = vec![];
    for exec_action_event in exec_action_events {
        let client = client.clone();

        tasks.push(tokio::spawn(async move {
            info!("processing {:#?}", exec_action_event);

            let (username, password) =
                match (exec_action_event.username, exec_action_event.password) {
                    (Some(username), Some(password)) => (username, password),
                    _ => {
                        warn!("can not log in: no credential provided");
                        return Err(Error::NoCredential(exec_action_event.action_event_id));
                    }
                };

            match get_token(&client, &username, &password)
                .await
                .map_err(Error::Reqwest)?
            {
                Some(token) => {
                    let token = (token.0, token.1.as_str());

                    let workout_keys = get_workout_keys(&client, &token)
                        .await
                        .map_err(Error::Reqwest)?;

                    let username = format!("{}$id${}", NAME, exec_action_event.user_id.0);
                    let movements: Vec<Movement> = client
                        .get(format!("{}/v0.2/movement", CONFIG.server_url))
                        .basic_auth(&username, Some(&CONFIG.password))
                        .send()
                        .await
                        .map_err(Error::Reqwest)?
                        .json::<Vec<Movement>>()
                        .await
                        .map_err(Error::Reqwest)?
                        .into_iter()
                        .map(|mut movement| {
                            movement.name.make_ascii_lowercase();
                            movement.name.retain(|c| !c.is_whitespace() && c != '-');
                            movement
                        })
                        .collect();

                    for workout_key in workout_keys.payload {
                        let workout_stats =
                            get_workout_stats(&client, &token, &workout_key.workout_key)
                                .await
                                .map_err(Error::Reqwest)?;
                        let workout_track =
                            get_workout_track(&client, &token, &workout_key.workout_key)
                                .await
                                .map_err(Error::Reqwest)?;

                        let activity = match workout_stats.activity_id {
                            1 => "running",
                            2 => "biking",
                            11 => "hiking",
                            22 => "trailrunning",
                            31 => "skitouring",
                            _ => continue,
                        };

                        let movement_id =
                            match movements.iter().find(|movement| movement.name == activity) {
                                Some(movement) => movement.id,
                                None => continue,
                            };

                        let avg_cadence = (workout_stats.step_count as f64
                            / (workout_stats.total_time / 60.) as f64)
                            as i32;

                        let cardio_session = CardioSession {
                            id: CardioSessionId(rand::thread_rng().gen()),
                            user_id: exec_action_event.user_id,
                            cardio_blueprint_id: None,
                            movement_id,
                            cardio_type: if activity == "running" || activity == "trailrunning" {
                                CardioType::Training
                            } else {
                                CardioType::Freetime
                            },
                            datetime: DateTime::from_utc(
                                NaiveDateTime::from_timestamp(
                                    workout_stats.start_time as i64 / 1000,
                                    0,
                                ),
                                Utc,
                            ),
                            distance: Some(workout_stats.total_distance as i32),
                            ascent: Some(workout_stats.total_ascent as i32),
                            descent: Some(workout_stats.total_descent as i32),
                            time: Some(workout_stats.total_time as i32 * 1000),
                            calories: Some(workout_stats.energy_consumption as i32),
                            track: Some(
                                workout_track
                                    .locations
                                    .into_iter()
                                    .map(|location| Position {
                                        latitude: location.la,
                                        longitude: location.ln,
                                        elevation: location.h as f64,
                                        distance: location.s as f64,
                                        time: location.t as i32 * 1000,
                                    })
                                    .collect(),
                            ),
                            avg_cadence: if avg_cadence > 0 {
                                Some(avg_cadence)
                            } else {
                                None
                            },
                            cadence: None,
                            avg_heart_rate: None,
                            heart_rate: None,
                            route_id: None,
                            comments: workout_stats.description,
                            last_change: Utc::now(),
                            deleted: false,
                        };

                        let response = client
                            .post(format!("{}/v0.2/cardio_session", CONFIG.server_url))
                            .basic_auth(&username, Some(&CONFIG.password))
                            .json(&cardio_session)
                            .send()
                            .await
                            .map_err(Error::Reqwest)?;

                        match response.status() {
                            status if status.is_success() => {
                                info!("cardio session saved");
                            }
                            StatusCode::CONFLICT => {
                                info!(
                                    "everything up to date for user {}",
                                    exec_action_event.user_id.0
                                );
                                break;
                            }
                            _ => {
                                response.error_for_status().map_err(Error::Reqwest)?; // this will always fail and return the error
                                break;
                            }
                        }
                    }

                    Ok(exec_action_event.action_event_id)
                }
                None => {
                    warn!("login failed!\n");
                    Err(Error::LoginFailed(exec_action_event.action_event_id))
                }
            }
        }));
    }

    let mut delete_action_event_ids = vec![];
    for task in tasks {
        match task.await {
            Ok(result) => match result {
                Ok(action_event_id) => delete_action_event_ids.push(action_event_id),
                Err(Error::NoCredential(action_event_id)) => {
                    delete_action_event_ids.push(action_event_id)
                }
                Err(Error::LoginFailed(action_event_id)) => {
                    delete_action_event_ids.push(action_event_id)
                }
                Err(error) => error!("{}", error),
            },
            Err(join_error) => error!("execution of action event failed: {}", join_error),
        }
    }

    info!("deleting {} action events", delete_action_event_ids.len());
    debug!("delete event ids: {:?}", delete_action_event_ids);

    if !delete_action_event_ids.is_empty() {
        disable_events(
            &client,
            &CONFIG.server_url,
            NAME,
            &CONFIG.password,
            &delete_action_event_ids,
        )
        .await?;
    }

    Ok(())
}

async fn get_token(
    client: &Client,
    username: &str,
    password: &str,
) -> Result<Option<(&'static str, String)>, ReqwestError> {
    let credentials = [("l", username), ("p", password)];
    let user: User = client
        .post("https://api.sports-tracker.com/apiserver/v1/login")
        .form(&credentials)
        .send()
        .await?
        .json()
        .await?;

    debug!("token = {:?}", user.session_key);

    Ok(user.session_key.map(|key| ("token", key)))
}

async fn get_workout_keys(
    client: &Client,
    token: &(&str, &str),
) -> Result<WorkoutKeys, ReqwestError> {
    let limited = &("limited", "true");
    let limit = &("limit", "100000");
    let workouts: WorkoutKeys = client
        .get("https://api.sports-tracker.com/apiserver/v1/workouts")
        .query(&[token, limited, limit])
        .send()
        .await?
        .json()
        .await?;

    Ok(workouts)
}

async fn get_workout_stats(
    client: &Client,
    token: &(&str, &str),
    workout_key: &str,
) -> Result<WorkoutStats, ReqwestError> {
    let samples = &("samples", "100000");

    Ok(client
        .get(format!(
            "https://api.sports-tracker.com/apiserver/v1/workouts/{}",
            workout_key
        ))
        .query(&[token, samples])
        .send()
        .await?
        .json::<WorkoutStatsWrapper>()
        .await?
        .payload)
}

async fn get_workout_track(
    client: &Client,
    token: &(&str, &str),
    workout_key: &str,
) -> Result<WorkoutTrack, ReqwestError> {
    let samples = &("samples", "100000");

    Ok(client
        .get(format!(
            "https://api.sports-tracker.com/apiserver/v1/workouts/{}/data",
            workout_key
        ))
        .query(&[token, samples])
        .send()
        .await?
        .json::<WorkoutTrackWrapper>()
        .await?
        .payload)
}

// workout overview:https://api.sports-tracker.com/apiserver/v1/workouts?token=sessionkey&limited=true&limit=1000000
// workout stats:   https://api.sports-tracker.com/apiserver/v1/workouts/<workout_key>?token=sessionkey
// workout data:    https://api.sports-tracker.com/apiserver/v1/workouts/<workout_key>/data?token=sessionkey
// gpx:             https://api.sports-tracker.com/apiserver/v1/workout/exportGpx/<workout_key>?token=sessionkey
// similar routes:  https://api.sports-tracker.com/apiserver/v1/workouts/similarRoutes/<workout_key>?token=sessionkey
