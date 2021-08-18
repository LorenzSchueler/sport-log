use chrono::{Duration, Utc};
use reqwest::{Client, StatusCode};

use sport_log_types::{Action, ActionEventId, ActionProvider, ExecutableActionEvent, Platform};

pub async fn setup(
    base_url: &str,
    name: &str,
    password: &str,
    platform_name: &str,
    platform: Platform,
    mut action_provider: ActionProvider,
    mut actions: Vec<Action>,
) {
    let client = Client::new();

    let response = client
        .post(format!("{}/v1/ap/platform", base_url))
        .basic_auth(name, Some(&password))
        .json(&platform)
        .send()
        .await
        .unwrap();

    match response.status() {
        StatusCode::OK => {
            println!("platform created");
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
            let platform = platforms
                .into_iter()
                .find(|platform| platform.name == platform_name)
                .unwrap();
            action_provider.platform_id = platform.id;
        }
        StatusCode::FORBIDDEN => {
            println!("action provider self registration is disabled");
            return;
        }
        status => {
            println!("an error occured (status {})", status);
            return;
        }
    };

    let response = client
        .post(format!("{}/v1/ap/action_provider", base_url))
        .basic_auth(name, Some(&password))
        .json(&action_provider)
        .send()
        .await
        .unwrap();

    match response.status() {
        StatusCode::OK => {
            println!("action provider created");
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
            for mut action in &mut actions {
                action.action_provider_id = action_provider.id;
            }
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

    match client
        .post(format!("{}/v1/ap/actions", base_url))
        .basic_auth(name, Some(&password))
        .json(&actions)
        .send()
        .await
        .unwrap()
        .status()
    {
        StatusCode::OK => println!("action created\nsetup successful"),
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
    let now = Utc::now();
    let datetime_start = (now + start_offset).to_rfc3339();
    let datetime_end = (now + end_offset).to_rfc3339();
    println!("{:?}", datetime_start);
    println!("{:?}", datetime_end);

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
