use reqwest::Client;
use serde_json::Value;
use tokio;

#[tokio::main]
async fn main() {
    let username = "sportstracker-fetch";
    let password = "sportstracker-fetch-passwd";

    let client = Client::new();

    // TODO use timespan
    let action_events = client
        .get("http://localhost:8000/v1/ap/executable_action_event")
        .basic_auth(username, Some(password))
        .send()
        .await
        .unwrap()
        .json::<Value>()
        .await
        .unwrap();
    println!("{}", serde_json::to_string_pretty(&action_events).unwrap());

    for action_event in action_events.as_array().unwrap() {
        if let Some(()) = get_data(
            action_event["username"].as_str().unwrap(),
            action_event["password"].as_str().unwrap(),
        )
        .await
        {
            client
                .delete(format!(
                    "http://localhost:8000/v1/ap/action_event/{}",
                    action_event["action_event_id"].to_string()
                ))
                .basic_auth(username, Some(password))
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
    //println!("{}", serde_json::to_string_pretty(&workouts).unwrap());
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
    //println!("{}", serde_json::to_string_pretty(&response).unwrap());
    let payload = &response["payload"];
    let points = &payload["locations"];
    let point0 = &points[0];
    println!("{}", serde_json::to_string_pretty(&point0).unwrap());

    Some(())
}

// get workout stats
//https://api.sports-tracker.com/apiserver/v1/workouts/60cf04fbcee4044c273c0b4a?token=f7oelv8crr39qv517n7lbgevo9v001st

// get gpx
//https://api.sports-tracker.com/apiserver/v1/workout/exportGpx/60cf04fbcee4044c273c0b4a?token=f7oelv8crr39qv517n7lbgevo9v001st
