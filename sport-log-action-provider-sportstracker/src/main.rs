use std::{env, fs, process};

use chrono::{DateTime, Duration, NaiveDateTime, Utc};
use err_derive::Error as StdError;
use lazy_static::lazy_static;
use rand::Rng;
use reqwest::{Client, Error as ReqwestError, StatusCode};
use serde::Deserialize;
use tracing::{debug, error, info, warn};

use sport_log_ap_utils::{delete_events, get_events, setup as setup_db};
use sport_log_types::{
    ActionEventId, CardioSession, CardioSessionId, CardioType, Movement, Position,
};

const CONFIG_FILE: &str = "config.toml";
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
    base_url: String,
}

lazy_static! {
    static ref CONFIG: Config = match fs::read_to_string(CONFIG_FILE) {
        Ok(file) => match toml::from_str(&file) {
            Ok(config) => config,
            Err(error) => {
                error!("Failed to parse config.toml.: {}", error);
                process::exit(1);
            }
        },
        Err(error) => {
            error!("Failed to read config.toml.: {}", error);
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
struct Workouts {
    payload: Vec<Workout>,
}

#[derive(Deserialize, Debug)]
struct Workout {
    description: Option<String>,
    #[serde(rename(deserialize = "activityId"))]
    activity_id: u32,
    #[serde(rename(deserialize = "startTime"))]
    start_time: u64,
    #[serde(rename(deserialize = "stopTime"))]
    stop_time: u64,
    #[serde(rename(deserialize = "totalTime"))]
    total_time: f32,
    #[serde(rename(deserialize = "totalDistance"))]
    total_distance: f32,
    #[serde(rename(deserialize = "totalAscent"))]
    total_ascent: f32,
    #[serde(rename(deserialize = "totalDescent"))]
    total_descent: f32,
    #[serde(rename(deserialize = "startPosition"))]
    start_position: StPosition,
    #[serde(rename(deserialize = "stopPosition"))]
    stop_position: StPosition,
    #[serde(rename(deserialize = "centerPosition"))]
    center_position: StPosition,
    #[serde(rename(deserialize = "stepCount"))]
    step_count: u32,
    #[serde(rename(deserialize = "minAltitude"))]
    min_altitude: Option<f32>,
    #[serde(rename(deserialize = "sessionkey"))]
    max_altitude: Option<f32>,
    #[serde(rename(deserialize = "workoutKey"))]
    workout_key: String,
    //hrdata:
    cadence: Cadence,
    #[serde(rename(deserialize = "energyConsumption"))]
    energy_consumption: u16,
}

#[derive(Deserialize, Debug)]
struct StPosition {
    x: f64,
    y: f64,
}

#[derive(Deserialize, Debug)]
struct Cadence {
    max: f32,
    avg: f32,
}

#[derive(Deserialize, Debug)]
struct WorkoutDataWrapper {
    payload: WorkoutData,
}

#[derive(Deserialize, Debug)]
struct WorkoutData {
    locations: Vec<Location>,
}

#[derive(Deserialize, Debug)]
struct Location {
    t: u32,  // seconds since start in 1/100 s
    la: f64, // lat
    ln: f64, // lon
    s: u32,  // meter since start
    h: f32,  // height
    v: u32,  // ???
    d: u64,  // timestamp in 1 / 1000 s
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
        &CONFIG.base_url,
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
        &CONFIG.base_url,
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

                    let workouts = get_workouts(&client, &token)
                        .await
                        .map_err(Error::Reqwest)?;
                    let username = format!("{}$id${}", NAME, exec_action_event.user_id.0);
                    let movements: Vec<Movement> = client
                        .get(format!("{}/v1.0/movement", CONFIG.base_url))
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

                    for workout in workouts {
                        let workout_data = get_workout_data(&client, &token, &workout.workout_key)
                            .await
                            .map_err(Error::Reqwest)?;
                        // TODO find more mappings or api endpoint

                        let activity = match workout.activity_id {
                            1 => "running",
                            22 => "trailrunning",
                            _ => continue,
                        };

                        let movement_id =
                            match movements.iter().find(|movement| movement.name == activity) {
                                Some(movement) => movement.id,
                                None => continue,
                            };

                        let cardio_session = CardioSession {
                            id: CardioSessionId(rand::thread_rng().gen()),
                            user_id: exec_action_event.user_id,
                            cardio_blueprint_id: None,
                            movement_id,
                            cardio_type: CardioType::Training,
                            datetime: DateTime::from_utc(
                                NaiveDateTime::from_timestamp(workout.start_time as i64 / 1000, 0),
                                Utc,
                            ),
                            distance: Some(workout.total_distance as i32),
                            ascent: Some(workout.total_ascent as i32),
                            descent: Some(workout.total_descent as i32),
                            time: Some(workout.total_time as i32),
                            calories: Some(workout.energy_consumption as i32),
                            track: Some(
                                workout_data
                                    .locations
                                    .into_iter()
                                    .map(|location| Position {
                                        latitude: location.la,
                                        longitude: location.ln,
                                        elevation: location.h as i32,
                                        distance: location.s as i32,
                                        time: location.t as i32,
                                    })
                                    .collect(),
                            ),
                            avg_cadence: if workout.cadence.avg > 0. {
                                Some(workout.cadence.avg as i32)
                            } else {
                                None
                            },
                            cadence: None,
                            avg_heart_rate: None,
                            heart_rate: None,
                            route_id: None,
                            comments: workout.description,
                            last_change: Utc::now(),
                            deleted: false,
                        };

                        let response = client
                            .post(format!("{}/v1.0/cardio_session", CONFIG.base_url))
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

    info!("deleting {} action event", delete_action_event_ids.len());
    debug!("delete event ids: {:?}", delete_action_event_ids);

    if !delete_action_event_ids.is_empty() {
        delete_events(
            &client,
            &CONFIG.base_url,
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

    Ok(user.session_key.map(|key| ("token", key)))
}

async fn get_workouts(client: &Client, token: &(&str, &str)) -> Result<Vec<Workout>, ReqwestError> {
    let workouts: Workouts = client
        .get("https://api.sports-tracker.com/apiserver/v1/workouts")
        .query(&[token])
        .send()
        .await?
        .json()
        .await?;

    Ok(workouts.payload)
}

async fn get_workout_data(
    client: &Client,
    token: &(&str, &str),
    workout_key: &str,
) -> Result<WorkoutData, ReqwestError> {
    let samples = &("samples", "100000");

    Ok(client
        .get(format!(
            "https://api.sports-tracker.com/apiserver/v1/workouts/{}/data",
            workout_key
        ))
        .query(&[token, samples])
        .send()
        .await?
        .json::<WorkoutDataWrapper>()
        .await?
        .payload)
}

// workout stats:   https://api.sports-tracker.com/apiserver/v1/workouts/<workout_id>?token=sessionkey
// gpx:             https://api.sports-tracker.com/apiserver/v1/workout/exportGpx/<workout_id>?token=sessionkey
// similar routes:  https://api.sports-tracker.com/apiserver/v1/workouts/similarRoutes/<workout_id>?token=sessionkey
