use chrono::NaiveDateTime;
use reqwest::Client;
use serde::{Deserialize, Serialize};

use sport_log_types::{CardioType, ExecutableActionEvent, MovementId, NewCardioSession, Position};

use sport_log_action_provider_sportstracker_config::Config;

#[derive(Serialize, Deserialize, Debug)]
pub struct User {
    sessionkey: Option<String>, // None if login fails
}

#[derive(Serialize, Deserialize, Debug)]
pub struct Workouts {
    payload: Vec<Workout>,
}

#[derive(Serialize, Deserialize, Debug)]
#[allow(non_snake_case)]
pub struct Workout {
    description: Option<String>,
    startTime: u64,
    stopTime: u64,
    totalTime: f32,
    totalDistance: f32,
    totalAscent: f32,
    totalDescent: f32,
    startPosition: StPosition,
    stopPosition: StPosition,
    centerPosition: StPosition,
    stepCount: u32,
    minAltitude: Option<f32>,
    maxAltitude: Option<f32>,
    workoutKey: String,
    //hrdata:
    cadence: Cadence,
    energyConsumption: u16,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct StPosition {
    x: f64,
    y: f64,
}

#[derive(Serialize, Deserialize, Debug)]
struct Cadence {
    max: f32,
    avg: f32,
}

#[derive(Serialize, Deserialize, Debug)]
struct WorkoutData {
    payload: InnerWorkoutData,
}

#[derive(Serialize, Deserialize, Debug)]
struct InnerWorkoutData {
    //description: Option<String>,
    //starttime: u64,
    //totaldistance: u32,
    //totaltime: u32,
    locations: Vec<Location>,
    // heartrate: Vec<>,
}

#[derive(Serialize, Deserialize, Debug)]
struct Location {
    t: u32,  // seconds since start in 1/100 s
    la: f64, // lat
    ln: f64, // lon
    s: u32,  // meter since start
    h: f32,  // height
    v: u32,  // ??? TODO
    d: u64,  // timestamp in 1 / 1000 s
}

#[tokio::main]
async fn main() {
    let config = Config::get();

    let client = Client::new();

    // TODO use timespan
    let exec_action_events: Vec<ExecutableActionEvent> = client
        .get(format!("{}/v1/ap/executable_action_event", config.base_url))
        .basic_auth(&config.username, Some(&config.password))
        .send()
        .await
        .unwrap()
        .json()
        .await
        .unwrap();
    println!("executable action events: {}\n", exec_action_events.len());

    for exec_action_event in exec_action_events {
        println!("{:#?}", exec_action_event);
        // TODO oldest entry
        if let Some(data) = get_data(&exec_action_event.username, &exec_action_event.password).await
        {
            for (workout, inner_workout_data) in data {
                let cardio_session = NewCardioSession {
                    user_id: exec_action_event.user_id,
                    movement_id: MovementId(0), // TODO get movement name from sportstracker and translate into own MovementId
                    cardio_type: CardioType::Training,
                    datetime: NaiveDateTime::from_timestamp(workout.startTime as i64 / 1000, 0),
                    distance: Some(workout.totalDistance as i32),
                    ascent: Some(workout.totalAscent as i32),
                    descent: Some(workout.totalDescent as i32),
                    time: Some(workout.totalTime as i32),
                    calories: Some(workout.energyConsumption as i32),
                    track: Some(
                        inner_workout_data
                            .locations
                            .into_iter()
                            .map(|location| Position {
                                latitude: location.la,
                                longitude: location.ln,
                                elevation: location.h,
                                distance: location.s as i32,
                                time: location.t as i32,
                            })
                            .collect(),
                    ),
                    avg_cycles: Some(workout.cadence.avg as i32),
                    cycles: None,
                    avg_heart_rate: None, // TODO
                    heart_rate: None,
                    route_id: None,

                    comments: workout.description,
                };
                // insert data into db
            }
            //client
            //.delete(format!(
            //"{}/v1/ap/action_event/{}",
            //config.base_url, action_event.action_event_id.0
            //))
            //.basic_auth(&config.username, Some(&config.password))
            //.send()
            //.await
            //.unwrap();
        } else {
            println!("login failed!\n");
        }
    }
}

async fn get_data(username: &str, password: &str) -> Option<Vec<(Workout, InnerWorkoutData)>> {
    let client = Client::new();

    let credentials = [("l", username), ("p", password)];
    let user: User = client
        .post("https://api.sports-tracker.com/apiserver/v1/login")
        .form(&credentials)
        .send()
        .await
        .unwrap()
        .json()
        .await
        .unwrap();

    let sessionkey = user.sessionkey?;
    let token = ("token", sessionkey.as_str());
    let workouts: Workouts = client
        .get("https://api.sports-tracker.com/apiserver/v1/workouts")
        .query(&[token])
        .send()
        .await
        .ok()?
        .json()
        .await
        .ok()?;
    println!("{:#?}", workouts.payload[0]);

    let samples = ("samples", "100000");

    let mut workout_datas = vec![];
    for workout in &workouts.payload {
        workout_datas.push(
            client
                .get(format!(
                    "https://api.sports-tracker.com/apiserver/v1/workouts/{}/data",
                    workout.workoutKey
                ))
                .query(&[token, samples])
                .send()
                .await
                .ok()?
                .json::<WorkoutData>()
                .await
                .ok()?
                .payload,
        );
    }

    let data = workouts.payload.into_iter().zip(workout_datas).collect();

    Some(data)
}

// get workout stats: https://api.sports-tracker.com/apiserver/v1/workouts/<workout_id>?token=sessionkey
// get gpx: https://api.sports-tracker.com/apiserver/v1/workout/exportGpx/<workout_id>?token=sessionkey
