use reqwest::Client;
use serde_json::{self, Value};
use tokio;

use sport_log_action_provider_sportstracker_config::Config;
use sport_log_types::ExecutableActionEvent;

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
    println!("{:?}", exec_action_events);

    for action_event in exec_action_events {
        if let Some(()) = get_data(&action_event.username, &action_event.password).await {
            client
                .delete(format!(
                    "{}/v1/ap/action_event/{}",
                    config.base_url, action_event.action_event_id
                ))
                .basic_auth(&config.username, Some(&config.password))
                .send()
                .await
                .unwrap();
        }
    }
}

async fn get_data(username: &str, password: &str) -> Option<()> {
    let credentials = [("l", username), ("p", password)];

    let client = Client::new();

    let login = client
        .post("https://api.sports-tracker.com/apiserver/v1/login")
        .form(&credentials)
        .send()
        .await
        .unwrap()
        .json::<Value>()
        .await
        .unwrap();

    println!("{}", serde_json::to_string_pretty(&login).unwrap());
    let sessionkey = login.get("sessionkey")?.as_str().unwrap();
    let token = ("token", sessionkey);

    let workouts = client
        .get("https://api.sports-tracker.com/apiserver/v1/workouts")
        .query(&[token])
        .send()
        .await
        .unwrap()
        .json::<Value>()
        .await
        .unwrap();

    let payload = &workouts["payload"];
    let body = &payload[0];
    println!("{}", body["startPosition"]);
    println!("{}", body["stopPosition"]);
    println!("{}", body["centerPosition"]);
    println!("{}", body["workoutKey"]);
    println!("{}", body["startTime"]);
    println!("{}", body["stopTime"]);
    println!("{}", body["totalTime"]);
    println!("{}", body["totalTime"]);
    println!("{}", body["totalAscent"]);
    println!("{}", body["totalDescent"]);
    println!("{}", body["totalDistance"]);
    println!("{}", body["stepCount"]);
    println!("{}", body["minAltitude"]);
    println!("{}", body["maxAltitude"]);
    println!("{}", body["energyConsumption"]);
    println!("{}", body["cadence"]);
    println!("{}", body["hrdata"]);
    println!("{}", body["extensions"][0]["temperature"]);

    let workout_id = body["workoutKey"].as_str().unwrap();
    let samples = ("samples", "100000");

    let response = client
        .get(format!(
            "https://api.sports-tracker.com/apiserver/v1/workouts/{}/data",
            workout_id,
        ))
        .query(&[token, samples])
        .send()
        .await
        .unwrap()
        .json::<Value>()
        .await
        .unwrap();

    let payload = &response["payload"];
    let points = &payload["locations"];
    let point0 = &points[0];
    println!("{}", serde_json::to_string_pretty(&point0).unwrap());

    Some(())
}

// get workout stats: https://api.sports-tracker.com/apiserver/v1/workouts/<workout_id>?token=sessionkey
// get gpx: https://api.sports-tracker.com/apiserver/v1/workout/exportGpx/<workout_id>?token=sessionkey
