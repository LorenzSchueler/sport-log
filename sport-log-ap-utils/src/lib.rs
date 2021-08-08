use chrono::{Duration, Local};
use reqwest::{Client, StatusCode};

use sport_log_types::{
    ActionEventId, ActionProvider, ExecutableActionEvent, NewAction, NewActionProvider,
    NewPlatform, Platform,
};

pub async fn setup(
    base_url: &str,
    name: &str,
    password: &str,
    platform: NewPlatform,
    mut action_provider: NewActionProvider,
    mut action: NewAction,
) {
    let client = Client::new();

    let response = client
        .post(format!("{}/v1/ap/platform", base_url))
        .basic_auth(name, Some(&password))
        .json(&platform)
        .send()
        .await
        .unwrap();

    let platform = match response.status() {
        StatusCode::OK => {
            println!("platform created");
            response.json().await.unwrap()
        }
        StatusCode::CONFLICT => {
            println!("platform already exists");
            let platforms: Vec<Platform> = client
                .get(format!("{}/v1/ap/platform", base_url))
                .send()
                .await
                .unwrap()
                .json()
                .await
                .unwrap();
            platforms
                .into_iter()
                .find(|platform| platform.name == name)
                .unwrap()
        }
        StatusCode::FORBIDDEN => {
            println!("action provider self registration disabled");
            return;
        }
        status => {
            println!("an error occured (status {})", status);
            return;
        }
    };

    // TODO remove if random id implemented
    action_provider.platform_id = platform.id;

    let response = client
        .post(format!("{}/v1/ap/action_provider", base_url))
        .basic_auth(name, Some(&password))
        .json(&action_provider)
        .send()
        .await
        .unwrap();

    let action_provider: ActionProvider = match response.status() {
        StatusCode::OK => {
            println!("action provider created");
            response.json().await.unwrap()
        }
        StatusCode::CONFLICT => {
            println!("action provider already exists");
            let action_provider: ActionProvider = client
                .get(format!("{}/v1/ap/action_provider", base_url))
                .basic_auth(name, Some(&password))
                .send()
                .await
                .unwrap()
                .json()
                .await
                .unwrap();
            action_provider
        }
        StatusCode::FORBIDDEN => {
            println!("action provider self registration disabled");
            return;
        }
        status => {
            println!("an error occured (status {})", status);
            return;
        }
    };

    // TODO remove if random id implemented
    action.action_provider_id = action_provider.id;

    match client
        .post(format!("{}/v1/ap/action", base_url))
        .basic_auth(name, Some(&password))
        .json(&action)
        .send()
        .await
        .unwrap()
        .status()
    {
        StatusCode::OK => println!("action created.\nsetup successful"),
        StatusCode::CONFLICT => println!("action already exists\nsetup successful"),
        status => println!("an error occured (status {})", status),
    }
}

pub async fn get_events(
    client: &Client,
    base_url: &str,
    name: &str,
    password: &str,
    start_offset: Duration,
    end_offset: Duration,
) -> Vec<ExecutableActionEvent> {
    let now = Local::now().naive_local();
    let datetime_start = (now + start_offset).format("%Y-%m-%dT%H:%M:%S");
    let datetime_end = (now + end_offset).format("%Y-%m-%dT%H:%M:%S");

    let exec_action_events: Vec<ExecutableActionEvent> = client
        .get(format!(
            "{}/v1/ap/executable_action_event/timespan/{}/{}",
            base_url, datetime_start, datetime_end
        ))
        .basic_auth(name, Some(&password))
        .send()
        .await
        .unwrap()
        .json()
        .await
        .unwrap();
    exec_action_events
}

pub async fn delete_events(
    client: &Client,
    base_url: &str,
    name: &str,
    password: &str,
    action_event_ids: &[ActionEventId],
) {
    client
        .delete(format!("{}/v1/ap/action_events", base_url,))
        .basic_auth(name, Some(&password))
        .json(action_event_ids)
        .send()
        .await
        .unwrap();
}
