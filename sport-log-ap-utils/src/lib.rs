//! Collection of functions for use in action providers.

use chrono::{Duration, SecondsFormat, Utc};
use rand::Rng;
use reqwest::{Client, Error, StatusCode};
use sport_log_types::{
    uri::{
        route_max_version, AP_ACTION, AP_ACTION_EVENT, AP_ACTION_PROVIDER,
        AP_EXECUTABLE_ACTION_EVENT, AP_PLATFORM,
    },
    Action, ActionEventId, ActionId, ActionProvider, ActionProviderId, ExecutableActionEvent,
    Platform, PlatformId,
};
use tracing::{debug, error, info};

#[allow(clippy::too_many_arguments)]
pub async fn setup(
    server_url: &str,
    name: &str,
    password: &str,
    description: &str,
    platform_name: &str,
    credential: bool,
    actions: &[(&str, &str)],
    create_before: Duration,
    delete_after: Duration,
) -> Result<(), Error> {
    let client = Client::new();

    let mut rng = rand::thread_rng();

    let platform = Platform {
        id: PlatformId(rng.gen()),
        name: platform_name.to_owned(),
        credential,
        deleted: false,
    };

    let response = client
        .post(route_max_version(server_url, AP_PLATFORM, None))
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
                .get(route_max_version(server_url, AP_PLATFORM, None))
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
        deleted: false,
    };

    let response = client
        .post(route_max_version(server_url, AP_ACTION_PROVIDER, None))
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
                .get(route_max_version(server_url, AP_ACTION_PROVIDER, None))
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
            create_before: create_before.num_milliseconds() as i32,
            delete_after: delete_after.num_milliseconds() as i32,
            deleted: false,
        })
        .collect();

    match client
        .post(route_max_version(server_url, AP_ACTION, None))
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
    let datetime_start = (now + start_offset).to_rfc3339_opts(SecondsFormat::Secs, true);
    let datetime_end = (now + end_offset).to_rfc3339_opts(SecondsFormat::Secs, true);

    let exec_action_events: Vec<ExecutableActionEvent> = client
        .get(route_max_version(
            base_url,
            AP_EXECUTABLE_ACTION_EVENT,
            Some(&[("start", &datetime_start), ("end", &datetime_end)]),
        ))
        .basic_auth(name, Some(&password))
        .send()
        .await?
        .json()
        .await?;

    debug!("got {} executable action events", exec_action_events.len());

    Ok(exec_action_events)
}

pub async fn disable_events(
    client: &Client,
    base_url: &str,
    name: &str,
    password: &str,
    action_event_ids: &[ActionEventId],
) -> Result<(), Error> {
    debug!(
        "disabling {} action events: {:?}",
        action_event_ids.len(),
        action_event_ids
    );

    client
        .delete(route_max_version(base_url, AP_ACTION_EVENT, None))
        .basic_auth(name, Some(&password))
        .json(action_event_ids)
        .send()
        .await?;

    Ok(())
}
