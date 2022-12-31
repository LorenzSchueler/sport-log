//! Collection of functions for use in action providers.

use chrono::{Duration, Utc};
use rand::Rng;
use reqwest::{Client, Error, StatusCode};
use sport_log_types::{
    Action, ActionEventId, ActionId, ActionProvider, ActionProviderId, ExecutableActionEvent,
    Platform, PlatformId,
};
use tracing::{error, info};

#[allow(clippy::too_many_arguments)]
pub async fn setup(
    base_url: &str,
    name: &str,
    password: &str,
    description: &str,
    platform_name: &str,
    credential: bool,
    actions: &[(&str, &str)],
    create_before: i32,
    delete_after: i32,
) -> Result<(), Error> {
    let client = Client::new();

    let mut rng = rand::thread_rng();

    let platform = Platform {
        id: PlatformId(rng.gen()),
        name: platform_name.to_owned(),
        credential,
        last_change: Utc::now(),
        deleted: false,
    };

    let response = client
        .post(format!("{}/v0.2/ap/platform", base_url))
        .json(&platform)
        .send()
        .await?;

    let platform_id = match response.status() {
        StatusCode::OK => {
            info!("platform created");
            platform.id
        }
        StatusCode::CONFLICT => {
            info!("platform already exists");
            let platforms: Vec<Platform> = client
                .get(format!("{}/v0.2/ap/platform", base_url))
                .send()
                .await?
                .json()
                .await?;
            let platform = platforms
                .into_iter()
                .find(|platform| platform.name == platform_name)
                .expect("platform name already exists but server response contains no platform with this name");
            platform.id
        }
        StatusCode::FORBIDDEN => {
            error!("action provider self registration is disabled");
            response.json::<Platform>().await?.id // this will always fail and return the error
        }
        status => {
            error!("an error occurred (status {})", status);
            response.json::<Platform>().await?.id // this will always fail and return the error
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
        .post(format!("{}/v0.2/ap/action_provider", base_url))
        .basic_auth(name, Some(&password))
        .json(&action_provider)
        .send()
        .await?;

    let action_provider_id = match response.status() {
        StatusCode::OK => {
            info!("action provider created");
            action_provider.id
        }
        StatusCode::CONFLICT => {
            info!("action provider already exists");
            let action_provider: ActionProvider = client
                .get(format!("{}/v0.2/ap/action_provider", base_url))
                .basic_auth(name, Some(&password))
                .send()
                .await?
                .json()
                .await?;
            action_provider.id
        }
        StatusCode::FORBIDDEN => {
            error!("action provider self registration disabled");
            response.json::<ActionProvider>().await?.id // this will always fail and return the error
        }
        status => {
            error!("an error occurred (status {})", status);
            response.json::<ActionProvider>().await?.id // this will always fail and return the error
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
        .post(format!("{}/v0.2/ap/actions", base_url))
        .basic_auth(name, Some(&password))
        .json(&actions)
        .send()
        .await?
        .status()
    {
        StatusCode::OK => info!("action created\nsetup successful"),
        StatusCode::CONFLICT => info!("action already exists\nsetup successful"),
        status => error!("an error occurred (status {})", status),
    }
    Ok(())
}

pub async fn get_events(
    client: &Client,
    base_url: &str,
    name: &str,
    password: &str,
    start_offset: Duration,
    end_offset: Duration,
) -> Result<Vec<ExecutableActionEvent>, Error> {
    let now = Utc::now();
    let datetime_start = (now + start_offset).to_rfc3339();
    let datetime_end = (now + end_offset).to_rfc3339();

    let exec_action_events: Vec<ExecutableActionEvent> = client
        .get(format!(
            "{}/v0.2/ap/executable_action_event/timespan/{}/{}",
            base_url, datetime_start, datetime_end
        ))
        .basic_auth(name, Some(&password))
        .send()
        .await?
        .json()
        .await?;
    Ok(exec_action_events)
}

pub async fn disable_events(
    client: &Client,
    base_url: &str,
    name: &str,
    password: &str,
    action_event_ids: &[ActionEventId],
) -> Result<(), Error> {
    client
        .delete(format!("{}/v0.2/ap/action_events", base_url,))
        .basic_auth(name, Some(&password))
        .json(action_event_ids)
        .send()
        .await?;
    Ok(())
}
