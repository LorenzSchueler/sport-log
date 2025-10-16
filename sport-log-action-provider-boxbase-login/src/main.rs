use std::{
    fs,
    io::Error as IoError,
    process::{ExitCode, Stdio},
    result::Result as StdResult,
    time::Duration as StdDuration,
};

use chrono::{DateTime, Datelike, Duration, Local, Utc};
use clap::Parser;
use reqwest::{Client, Error as ReqwestError};
use serde::Deserialize;
use sport_log_ap_utils::{disable_events, get_events, setup as setup_db};
use sport_log_types::{ActionEventId, ExecutableActionEvent};
use sysinfo::System;
use thirtyfour::{WebDriver, error::WebDriverError, prelude::*};
use thiserror::Error;
use tokio::{process::Command, task::JoinError, time};
use tracing::{debug, error, info, warn};
use tracing_subscriber::EnvFilter;

const CONFIG_FILE: &str = "sport-log-action-provider-boxbase-login.toml";
const NAME: &str = "boxbase-login";
const DESCRIPTION: &str =
    "Boxbase Login can reserve spots in classes. The action names correspond to the class types.";
const PLATFORM_NAME: &str = "BoxBase";

const GECKODRIVER: &str = "geckodriver";
const WEBDRIVER_ADDRESS: &str = "http://localhost:4444/";

#[derive(Debug, Error)]
enum Error {
    #[error("{0}")]
    Reqwest(#[from] ReqwestError),
    #[error("{0}")]
    Io(#[from] IoError),
    #[error("{0}")]
    WebDriver(#[from] WebDriverError),
    #[error("{0}")]
    Join(#[from] JoinError),
}

type Result<T> = StdResult<T, Error>;

#[derive(Debug, Error)]
enum UserError {
    #[error("can not log in: no credentials provided")]
    NoCredential(ActionEventId),
    #[error("can not log in: invalid credentials")]
    InvalidCredential(ActionEventId),
    #[error("can not log in: unknown error")]
    UnknownLoginError(ActionEventId),
    #[error("can not reserve class: {1} class at {2} not found")]
    ClassNotFound(ActionEventId, String, DateTime<Utc>),
    #[error("can not reserve class: failed to reserve {1} class at {2}")]
    ReservationFailed(ActionEventId, String, DateTime<Utc>),
}

impl UserError {
    fn action_event_id(&self) -> ActionEventId {
        match self {
            Self::NoCredential(action_event_id)
            | Self::InvalidCredential(action_event_id)
            | Self::UnknownLoginError(action_event_id)
            | Self::ClassNotFound(action_event_id, ..)
            | Self::ReservationFailed(action_event_id, ..) => *action_event_id,
        }
    }
}

type UserResult<T> = StdResult<T, UserError>;

/// The config for [`sport-log-action-provider-boxbase-login`](crate).
///
/// The name of the config file is specified in [`CONFIG_FILE`].
///
/// `admin_password` is the password for the admin endpoints.
///
/// `server_url` is the left part of the URL (everything before `/<version>/...`)
#[derive(Deserialize, Debug)]
struct Config {
    password: String,
    server_url: String,
}

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
enum Mode {
    Headless,
    Interactive,
}

/// Boxbase Login Action Provider
#[derive(Parser, Debug)]
#[command( about, long_about = None)]
struct Args {
    /// create own actions
    #[arg(short, long)]
    setup: bool,

    /// use interactive webdriver session (with browser window)
    #[arg(short, long)]
    interactive: bool,
}

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
    } else {
        let mode = if args.interactive {
            Mode::Interactive
        } else {
            Mode::Headless
        };
        if let Err(error) = login(&config, mode).await {
            warn!("login failed: {error}");
        }
    }

    ExitCode::SUCCESS
}

async fn setup(config: &Config) -> Result<()> {
    setup_db(
        &config.server_url,
        NAME,
        &config.password,
        DESCRIPTION,
        PLATFORM_NAME,
        true,
        &[
            ("GentleGiants Group", "Reserve a spot in a group class."),
            (
                "GentleGiants OG",
                "Reserve a spot in a Open Gym class in the main gym.",
            ),
            (
                "GentleGiants OG 2",
                "Reserve a spot in a Open Gym class in gym 2.",
            ),
        ],
        Duration::try_days(7).unwrap(),
        Duration::zero(),
    )
    .await?;

    Ok(())
}

async fn login(config: &Config, mode: Mode) -> Result<()> {
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

    if exec_action_events.is_empty() {
        return Ok(());
    }

    for p in System::new_all().processes_by_name(GECKODRIVER.as_ref()) {
        p.kill_and_wait().unwrap();
    }

    let mut webdriver = Command::new(GECKODRIVER)
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .spawn()?;

    time::sleep(StdDuration::from_secs(1)).await; // make sure geckodriver is available

    let mut caps = DesiredCapabilities::firefox();
    if mode == Mode::Headless {
        caps.set_headless()?;
    }

    for exec_action_event in exec_action_events {
        debug!("processing {:#?}", exec_action_event);

        let result = if let (Some(username), Some(password)) =
            (&exec_action_event.username, &exec_action_event.password)
        {
            let driver = WebDriver::new(WEBDRIVER_ADDRESS, caps.clone()).await?;

            let result = boxbase_login(&driver, username, password, &exec_action_event, mode).await;

            debug!("closing browser");
            driver.quit().await?;

            result
        } else {
            Ok(Err(UserError::NoCredential(
                exec_action_event.action_event_id,
            )))
        };

        match result? {
            Ok(action_event_id) => {
                info!("disabling event");
                disable_events(
                    &client,
                    &config.server_url,
                    NAME,
                    &config.password,
                    &[action_event_id],
                )
                .await?;
            }
            Err(error) => {
                info!("{error}");
                match error {
                    UserError::NoCredential(_) | UserError::InvalidCredential(_) => {
                        info!("disabling event");
                        disable_events(
                            &client,
                            &config.server_url,
                            NAME,
                            &config.password,
                            &[error.action_event_id()],
                        )
                        .await?;
                    }
                    UserError::UnknownLoginError(_)
                    | UserError::ClassNotFound(_, _, _)
                    | UserError::ReservationFailed(_, _, _) => {
                        info!("trying again on next invocation");
                    }
                }
            }
        }
    }

    debug!("terminating webdriver");
    webdriver.kill().await?;

    Ok(())
}

async fn boxbase_login(
    driver: &WebDriver,
    username: &str,
    password: &str,
    exec_action_event: &ExecutableActionEvent,
    mode: Mode,
) -> Result<UserResult<ActionEventId>> {
    let time = exec_action_event
        .datetime
        .with_timezone(&Local)
        .format("%H:%M")
        .to_string();

    let event_date = exec_action_event.datetime;
    let day = exec_action_event.datetime.day();

    let now = Utc::now();
    let next_week =
        event_date.iso_week().week() > now.iso_week().week() || event_date.year() > now.year();

    info!("loading website");

    driver.delete_all_cookies().await?;
    driver.goto("https://admin.boxbase.app/classes").await?;

    time::sleep(StdDuration::from_secs(2)).await;

    info!("entering credentials");

    driver
        .find(By::Id("email"))
        .await?
        .send_keys(username)
        .await?;
    driver
        .find(By::Id("password"))
        .await?
        .send_keys(password)
        .await?;

    let buttons = driver
        .find(By::Id("password"))
        .await?
        .parent()
        .await?
        .find_all(By::Tag("button"))
        .await?;

    for button in buttons {
        if button.inner_html().await? == "Log in" {
            button.click().await?;
            break;
        }
    }

    time::sleep(StdDuration::from_secs(5)).await;

    if let Ok(p) = driver.find(By::Tag("p")).await
        && p.inner_html().await? == "These credentials do not match our records."
    {
        return Ok(Err(UserError::InvalidCredential(
            exec_action_event.action_event_id,
        )));
    }

    if driver
        .find(By::XPath("//a[@href='https://admin.boxbase.app/profile']"))
        .await
        .is_err()
    {
        return Ok(Err(UserError::UnknownLoginError(
            exec_action_event.action_event_id,
        )));
    }

    info!("login successful");

    if next_week {
        let next_week_button = driver
            .find(By::XPath("//main/div[1]/div[1]/button[2]"))
            .await?;
        next_week_button.click().await?;

        time::sleep(StdDuration::from_secs(5)).await;
    }

    let day_button = driver
        .find(By::XPath(format!(
            "//main/div[1]/div[1]/div[1]/button[div/div/span[text()='{day}']]",
        )))
        .await?;
    day_button.click().await?;

    time::sleep(StdDuration::from_secs(5)).await;

    let class_container = driver
        .find(By::XPath(
            "//main/div[2]/div[2]/div[1]/div[1]/div[1]/div[1]",
        ))
        .await?;

    let classes = class_container.find_all(By::XPath("./div")).await?;

    for class in classes {
        let class_time = class
            .find(By::XPath("./div[1]/div[1]/span[1]"))
            .await?
            .inner_html()
            .await?;
        let class_name = class
            .find(By::XPath("./div[1]/div[2]/div[2]"))
            .await?
            .inner_html()
            .await?;

        if class_time.starts_with(&format!("{time} - "))
            && class_name == exec_action_event.action_name
        {
            info!("class found");

            let class_symbol = class
                .find(By::XPath("./div[3]/div/*[local-name()='svg'][1]"))
                .await?;
            match class_symbol.class_name().await?.as_deref() {
                Some("text-semantic-green-foreground" | "text-semantic-brown-foreground") => {
                    info!("class already reserved");
                    return Ok(Ok(exec_action_event.action_event_id));
                }
                Some("text-bblack-700") => info!("class not yet reserved"),
                _ => panic!("unexpected class status symbol"),
            }

            class.click().await?;

            time::sleep(StdDuration::from_secs(1)).await;

            driver
                .find(By::XPath("/html/body/div[3]/div[4]/div/button"))
                .await?
                .click()
                .await?;

            time::sleep(StdDuration::from_secs(1)).await;

            let class_symbol = class
                .find(By::XPath("./div[3]/div[1]/*[local-name()='svg'][1]"))
                .await?;
            match class_symbol.class_name().await?.as_deref() {
                Some("text-semantic-green-foreground" | "text-semantic-brown-foreground") => {
                    info!("reservation successful");

                    if mode == Mode::Interactive {
                        time::sleep(StdDuration::from_secs(5)).await;
                    }

                    return Ok(Ok(exec_action_event.action_event_id));
                }
                Some("text-bblack-700") => {
                    return Ok(Err(UserError::ReservationFailed(
                        exec_action_event.action_event_id,
                        exec_action_event.action_name.clone(),
                        exec_action_event.datetime,
                    )));
                }
                _ => panic!("unexpected class status symbol"),
            }
        }
    }

    Ok(Err(UserError::ClassNotFound(
        exec_action_event.action_event_id,
        exec_action_event.action_name.clone(),
        exec_action_event.datetime,
    )))
}
