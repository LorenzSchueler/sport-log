use std::{fs, process::ExitCode, result::Result as StdResult};

use chrono::{DateTime, Duration, Local, Utc};
use clap::Parser;
use reqwest::{Client, Error as ReqwestError};
use serde::Deserialize;
use serde_json::Error as JsonError;
use sport_log_ap_utils::{ActionSetup, disable_events, get_events, setup as setup_db};
use sport_log_types::ExecutableActionEvent;
use thiserror::Error;
use tracing::{debug, error, info, warn};
use tracing_subscriber::EnvFilter;

use crate::boxbase::{BoxBase, Class};

mod boxbase;

const CONFIG_FILE: &str = "sport-log-action-provider-boxbase-login.toml";
const NAME: &str = "BoxBase Login";
const DESCRIPTION: &str =
    "Boxbase Login can reserve spots in classes. The action names correspond to the class types.";
const PLATFORM_NAME: &str = "BoxBase";

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

/// A result with an [`Error`].
type Result<T> = StdResult<T, Error>;

/// An error caused by the user's data after which the action event is disabled.
#[derive(Debug, Error)]
enum UserError {
    #[error("can not log in: no credentials provided")]
    NoCredential,
    #[error("can not log in: invalid credentials")]
    InvalidCredential,
    #[error("can not reserve class: {0} class at {1} not found")]
    ClassNotFound(String, DateTime<Utc>),
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
#[derive(Deserialize, Debug)]
struct Config {
    password: String,
    server_url: String,
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
                name: "GentleGiants Group",
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
        ],
    )
    .await?;

    Ok(())
}

/// Processes the action events of the next week and disables them unless an [`Error`] occurs.
async fn process_events(config: &Config) -> Result<()> {
    let client = Client::new();

    let exec_action_events = get_events(
        &client,
        &config.server_url,
        NAME,
        &config.password,
        Duration::zero(),
        Duration::try_days(7).unwrap(),
    )
    .await?;
    info!("got {} action events", exec_action_events.len());

    for exec_action_event in exec_action_events {
        debug!("processing {:#?}", exec_action_event);

        match process_event(&exec_action_event).await {
            Ok(Ok(())) => {}
            Ok(Err(error)) => info!("{error}"),
            Err(error) => {
                warn!("{error}, trying again on next invocation");
                continue;
            }
        }

        info!("disabling event");
        disable_events(
            &client,
            &config.server_url,
            NAME,
            &config.password,
            &[exec_action_event.action_event_id],
        )
        .await?;
    }

    Ok(())
}

/// Logs in to BoxBase with the credentials of the event and reserves its class.
async fn process_event(exec_action_event: &ExecutableActionEvent) -> Result<UserResult<()>> {
    let (Some(username), Some(password)) =
        (&exec_action_event.username, &exec_action_event.password)
    else {
        return Ok(Err(UserError::NoCredential));
    };

    let boxbase = match BoxBase::login(username, password).await? {
        Ok(boxbase) => boxbase,
        Err(error) => return Ok(Err(error)),
    };
    info!("login successful");

    reserve_class(&boxbase, exec_action_event).await
}

/// Reserves the class of the event unless it is already reserved.
async fn reserve_class(
    boxbase: &BoxBase,
    exec_action_event: &ExecutableActionEvent,
) -> Result<UserResult<()>> {
    let Some(class) = find_class(boxbase, exec_action_event).await? else {
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

    let class = find_class(boxbase, exec_action_event).await?;
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
