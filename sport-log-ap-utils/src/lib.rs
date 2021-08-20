use chrono::{Duration, Utc};
use rand::Rng;
use reqwest::{Client, StatusCode};

use sport_log_types::{
    Action, ActionEventId, ActionId, ActionProvider, ActionProviderId, ExecutableActionEvent,
    Platform, PlatformId,
};

#[allow(clippy::too_many_arguments)]
pub async fn setup(
    base_url: &str,
    name: &str,
    password: &str,
    description: &str,
    platform_name: &str,
    actions: &[(&str, &str)],
    create_before: i32,
    delete_after: i32,
) {
    let client = Client::new();

    let mut rng = rand::thread_rng();

    let platform = Platform {
        id: PlatformId(rng.gen()),
        name: platform_name.to_owned(),
        last_change: Utc::now(),
        deleted: false,
    };

    let response = client
        .post(format!("{}/v1/ap/platform", base_url))
        .json(&platform)
        .send()
        .await
        .unwrap();

    let platform_id = match response.status() {
        StatusCode::OK => {
            println!("platform created");
            platform.id
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
            platform.id
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

    let action_provider = ActionProvider {
        id: ActionProviderId(rng.gen()),
        name: name.to_owned(),
        password: password.to_owned(),
        platform_id,
        description: Some(description.to_owned()),
        last_change: Utc::now(),
        deleted: false,
    };

    let response = client
        .post(format!("{}/v1/ap/action_provider", base_url))
        .basic_auth(name, Some(&password))
        .json(&action_provider)
        .send()
        .await
        .unwrap();

    let action_provider_id = match response.status() {
        StatusCode::OK => {
            println!("action provider created");
            action_provider.id
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
            action_provider.id
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

    let actions: Vec<Action> = actions
        .iter()
        .map(|action| Action {
            id: ActionId(rng.gen()),
            name: action.0.to_owned(),
            action_provider_id,
            description: Some(action.1.to_owned()),
            create_before,
            delete_after,
            last_change: Utc::now(),
            deleted: false,
        })
        .collect();

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
