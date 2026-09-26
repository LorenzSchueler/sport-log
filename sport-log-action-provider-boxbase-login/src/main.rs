use std::{fs, process::ExitCode, result::Result as StdResult};

use chrono::{DateTime, Duration, Local, NaiveDate, Utc};
use clap::Parser;
use rand::RngExt;
use reqwest::{Client, Error as ReqwestError, StatusCode};
use serde::Deserialize;
use serde_json::Error as JsonError;
use sport_log_ap_utils::{ActionSetup, disable_events, get_events, setup as setup_db};
use sport_log_types::{
    ExecutableActionEvent, ID_HEADER, Wod, WodId,
    uri::{WOD, route_max_version},
};
use thiserror::Error;
use tracing::{debug, error, info, warn};
use tracing_subscriber::EnvFilter;

use crate::boxbase::{BoxBase, Class, RegistrationStatus};

mod boxbase;
mod wod;

const CONFIG_FILE: &str = "sport-log-action-provider-boxbase-login.toml";
const NAME: &str = "BoxBase Login";
const DESCRIPTION: &str = concat!(
    "Boxbase Login can reserve spots in classes and save the wod of reserved classes. ",
    "The action names correspond to the class types."
);
const PLATFORM_NAME: &str = "BoxBase";

const WOD_ACTION_NAME: &str = "GentleGiants Group Wod";
const GROUP_CLASS_NAME: &str = "GentleGiants Group";

/// An error not caused by the user's data. Action events failing with it are retried on the next
/// invocation.
#[derive(Debug, Error)]
enum Error {
    #[error("{0}")]
    Reqwest(#[from] ReqwestError),
    #[error("{0}")]
    Json(#[from] JsonError),
    #[error("unexpected response: {0}")]
    UnexpectedResponse(String),
    #[error("failed to reserve {0} class at {1}")]
    ReservationFailed(String, DateTime<Utc>),
}

/// A result with an [`enum@Error`].
type Result<T> = StdResult<T, Error>;

/// An error caused by the user's data after which the action event is disabled, except for
/// [`UserError::NoReservation`].
#[derive(Debug, Error)]
enum UserError {
    #[error("can not log in: no credentials provided")]
    NoCredential,
    #[error("can not log in: invalid credentials")]
    InvalidCredential,
    #[error("can not reserve class: {0} class at {1} not found")]
    ClassNotFound(String, DateTime<Utc>),
    /// The action event is retried on the next invocation since the class can still be reserved.
    #[error("can not save wod: no {GROUP_CLASS_NAME} class reserved today")]
    NoReservation,
}

/// A result with a [`UserError`].
type UserResult<T> = StdResult<T, UserError>;

/// The config for [`sport-log-action-provider-boxbase-login`](crate).
///
/// The name of the config file is specified in [`CONFIG_FILE`].
///
/// `password` is the password of the action provider.
///
/// `server_url` is the left part of the URL (everything before `/<version>/...`)
///
/// `wod_username` and `wod_password` are the credentials for the GentleGiants wod website.
#[derive(Deserialize, Debug)]
struct Config {
    password: String,
    server_url: String,
    wod_username: String,
    wod_password: String,
}

/// Boxbase Login Action Provider
#[derive(Parser, Debug)]
#[command( about, long_about = None)]
struct Args {
    /// create own actions
    #[arg(short, long)]
    setup: bool,
}

/// Reads the config and either sets up the actions or processes the action events.
#[tokio::main]
async fn main() -> ExitCode {
    tracing_subscriber::fmt()
        .with_writer(std::io::stderr)
        .with_env_filter(EnvFilter::try_from_default_env().unwrap_or_else(|_| {
            EnvFilter::new(if cfg!(debug_assertions) {
                "info,sport_log_action_provider_boxbase_login=debug"
            } else {
                "warn,sport_log_action_provider_boxbase_login=info"
            })
        }))
        .init();

    let args = Args::parse();

    let config_file = match fs::read_to_string(CONFIG_FILE) {
        Ok(file) => file,
        Err(error) => {
            error!("failed to read {CONFIG_FILE}: {error}");
            return ExitCode::FAILURE;
        }
    };
    let config = match toml::from_str(&config_file) {
        Ok(config) => config,
        Err(error) => {
            error!("failed to parse {CONFIG_FILE}: {error}");
            return ExitCode::FAILURE;
        }
    };

    if args.setup {
        if let Err(error) = setup(&config).await {
            warn!("setup failed: {error}");
        }
    } else if let Err(error) = process_events(&config).await {
        warn!("processing action events failed: {error}");
    }

    ExitCode::SUCCESS
}

/// Creates the platform, the action provider and its actions.
async fn setup(config: &Config) -> Result<()> {
    let create_before = Duration::try_days(14).unwrap();
    let delete_after = Duration::zero();

    setup_db(
        &config.server_url,
        NAME,
        &config.password,
        DESCRIPTION,
        PLATFORM_NAME,
        true,
        &[
            ActionSetup {
                name: GROUP_CLASS_NAME,
                description: "Reserve a spot in a group class.",
                create_before,
                delete_after,
            },
            ActionSetup {
                name: "GentleGiants OG",
                description: "Reserve a spot in a Open Gym class in the main gym.",
                create_before,
                delete_after,
            },
            ActionSetup {
                name: "GentleGiants OG 2",
                description: "Reserve a spot in a Open Gym class in gym 2.",
                create_before,
                delete_after,
            },
            ActionSetup {
                name: WOD_ACTION_NAME,
                description: "Save the wod if a spot in a group class is reserved on this day. The time of the rule is ignored.",
                create_before: Duration::try_days(2).unwrap(),
                delete_after: Duration::try_days(1).unwrap(),
            },
        ],
    )
    .await?;

    Ok(())
}

/// Processes the reservation events of the next week and the wod events of today and disables
/// them once they are done.
async fn process_events(config: &Config) -> Result<()> {
    let client = Client::new();

    let now = Utc::now();
    let today = Local::now().date_naive();

    let exec_action_events = get_events(
        &client,
        &config.server_url,
        NAME,
        &config.password,
        Duration::try_days(-1).unwrap(),
        Duration::try_days(7).unwrap(),
    )
    .await?;

    let reservation_events: Vec<_> = exec_action_events
        .iter()
        .filter(|exec_action_event| {
            exec_action_event.action_name != WOD_ACTION_NAME && exec_action_event.datetime >= now
        })
        .collect();
    let wod_events: Vec<_> = exec_action_events
        .iter()
        .filter(|exec_action_event| {
            exec_action_event.action_name == WOD_ACTION_NAME
                && exec_action_event
                    .datetime
                    .with_timezone(&Local)
                    .date_naive()
                    == today
        })
        .collect();

    info!(
        "got {} reservation and {} wod action events",
        reservation_events.len(),
        wod_events.len()
    );

    for exec_action_event in reservation_events {
        debug!("processing {:#?}", exec_action_event);
        let result = reserve_class(exec_action_event).await;
        finish_event(&client, config, exec_action_event, result).await?;
    }

    if wod_events.is_empty() {
        return Ok(());
    }

    let wod = wod::fetch_wod(&config.wod_username, &config.wod_password, today).await;
    let description = match wod {
        Ok(Some(description)) => description,
        Ok(None) => {
            info!("no wod found for {today}, trying again on next invocation");
            return Ok(());
        }
        Err(error) => {
            warn!("failed to fetch wod: {error}, trying again on next invocation");
            return Ok(());
        }
    };

    for exec_action_event in wod_events {
        debug!("processing {:#?}", exec_action_event);
        let result = save_wod(&client, config, exec_action_event, today, &description).await;
        finish_event(&client, config, exec_action_event, result).await?;
    }

    Ok(())
}

/// Logs the result of processing the event and disables the event unless it is retried.
async fn finish_event(
    client: &Client,
    config: &Config,
    exec_action_event: &ExecutableActionEvent,
    result: Result<UserResult<()>>,
) -> Result<()> {
    match result {
        Ok(Ok(())) => {}
        Ok(Err(error @ UserError::NoReservation)) => {
            info!("{error}, trying again on next invocation");
            return Ok(());
        }
        Ok(Err(error)) => info!("{error}"),
        Err(error) => {
            warn!("{error}, trying again on next invocation");
            return Ok(());
        }
    }

    info!("disabling event");
    disable_events(
        client,
        &config.server_url,
        NAME,
        &config.password,
        &[exec_action_event.action_event_id],
    )
    .await?;

    Ok(())
}

/// Logs in to BoxBase with the credentials of the event.
async fn login(exec_action_event: &ExecutableActionEvent) -> Result<UserResult<BoxBase>> {
    let (Some(username), Some(password)) =
        (&exec_action_event.username, &exec_action_event.password)
    else {
        return Ok(Err(UserError::NoCredential));
    };

    match BoxBase::login(username, password).await? {
        Ok(boxbase) => {
            info!("login successful");
            Ok(Ok(boxbase))
        }
        Err(error) => Ok(Err(error)),
    }
}

/// Logs in to BoxBase and reserves the class of the event unless it is already reserved.
async fn reserve_class(exec_action_event: &ExecutableActionEvent) -> Result<UserResult<()>> {
    let boxbase = match login(exec_action_event).await? {
        Ok(boxbase) => boxbase,
        Err(error) => return Ok(Err(error)),
    };

    let Some(class) = find_class(&boxbase, exec_action_event).await? else {
        return Ok(Err(UserError::ClassNotFound(
            exec_action_event.action_name.clone(),
            exec_action_event.datetime,
        )));
    };
    info!("class found");

    if class.is_reserved() {
        info!("class already reserved");
        return Ok(Ok(()));
    }
    info!("class not yet reserved");

    boxbase.register(&class).await?;

    let class = find_class(&boxbase, exec_action_event).await?;
    if class.as_ref().is_some_and(Class::is_reserved) {
        info!("reservation successful");
        Ok(Ok(()))
    } else {
        Err(Error::ReservationFailed(
            exec_action_event.action_name.clone(),
            exec_action_event.datetime,
        ))
    }
}

/// Finds the class with the name and local start time of the event.
async fn find_class(
    boxbase: &BoxBase,
    exec_action_event: &ExecutableActionEvent,
) -> Result<Option<Class>> {
    let datetime = exec_action_event.datetime.with_timezone(&Local);
    let time = datetime.format("%H:%M").to_string();

    Ok(boxbase
        .classes(datetime.date_naive())
        .await?
        .into_iter()
        .find(|class| class.name == exec_action_event.action_name && class.starts_at == time))
}

/// Logs in to BoxBase and saves the wod if a [`GROUP_CLASS_NAME`] class is reserved at `date`.
/// Being on the waiting list does not count.
async fn save_wod(
    client: &Client,
    config: &Config,
    exec_action_event: &ExecutableActionEvent,
    date: NaiveDate,
    description: &str,
) -> Result<UserResult<()>> {
    let boxbase = match login(exec_action_event).await? {
        Ok(boxbase) => boxbase,
        Err(error) => return Ok(Err(error)),
    };

    let reserved = boxbase.classes(date).await?.iter().any(|class| {
        class.name == GROUP_CLASS_NAME
            && class.registration_status == Some(RegistrationStatus::Registered)
    });
    if !reserved {
        return Ok(Err(UserError::NoReservation));
    }
    info!("reserved class found");

    let wod = Wod {
        id: WodId(rand::rng().random()),
        user_id: exec_action_event.user_id,
        date,
        description: Some(description.to_owned()),
        deleted: false,
    };

    let response = client
        .post(route_max_version(&config.server_url, WOD, None))
        .basic_auth(NAME, Some(&config.password))
        .header(ID_HEADER, exec_action_event.user_id.0)
        .json(&wod)
        .send()
        .await?;

    if response.status() == StatusCode::CONFLICT {
        info!("wod already exists");
    } else {
        response.error_for_status()?;
        info!("wod created");
    }

    Ok(Ok(()))
}
