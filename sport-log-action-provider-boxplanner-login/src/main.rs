use std::{
    env, fs,
    io::Error as IoError,
    process::{ExitCode, Stdio},
    result::Result as StdResult,
    time::Duration as StdDuration,
};

use chrono::{DateTime, Datelike, Days, Duration, Local, Utc, Weekday};
use clap::Parser;
use reqwest::{Client, Error as ReqwestError};
use serde::Deserialize;
use sport_log_ap_utils::{disable_events, get_events, setup as setup_db};
use sport_log_types::{ActionEventId, ExecutableActionEvent};
use sysinfo::System;
use thirtyfour::{error::WebDriverError, prelude::*, WebDriver};
use thiserror::Error;
use tokio::{process::Command, task::JoinError, time};
use tracing::{debug, error, info, warn};
use tracing_subscriber::EnvFilter;

const CONFIG_FILE: &str = "sport-log-action-provider-boxplanner-login.toml";
const NAME: &str = "boxplanner-login";
const DESCRIPTION: &str =
    "Boxplanner Login can reserve spots in classes. The action names correspond to the class types.";
const PLATFORM_NAME: &str = "boxplanner";

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
    #[error("can not log in: captcha required")]
    UnknownLoginError(ActionEventId),
    #[error("{1} class at {2} not found within timeout")]
    ClassNotFound(ActionEventId, String, DateTime<Utc>),
}

impl UserError {
    fn action_event_id(&self) -> ActionEventId {
        match self {
            Self::NoCredential(action_event_id)
            | Self::InvalidCredential(action_event_id)
            | Self::UnknownLoginError(action_event_id)
            | Self::ClassNotFound(action_event_id, ..) => *action_event_id,
        }
    }
}

type UserResult<T> = StdResult<T, UserError>;

/// The config for [`sport-log-action-provider-boxplanner-login`](crate).
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

/// Boxplanner Login Action Provider
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
    if env::var("RUST_LOG").is_err() {
        if cfg!(debug_assertions) {
            env::set_var(
                "RUST_LOG",
                "info,sport_log_action_provider_boxplanner_login=debug",
            );
        } else {
            env::set_var(
                "RUST_LOG",
                "warn,sport_log_action_provider_boxplanner_login=info",
            );
        }
    }

    tracing_subscriber::fmt()
        .with_writer(std::io::stderr)
        .with_env_filter(EnvFilter::from_default_env())
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
        &[("Weightlifting", "Reserve a spot in a Weightlifting class.")],
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
        Duration::try_days(2).unwrap() + Duration::try_minutes(2).unwrap(),
    )
    .await?;

    if exec_action_events.is_empty() {
        return Ok(());
    }

    for p in System::new_all().processes_by_name(GECKODRIVER) {
        p.kill();
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

    let mut tasks = vec![];
    for exec_action_event in exec_action_events {
        let caps = caps.clone();

        tasks.push(tokio::spawn(async move {
            debug!("processing {:#?}", exec_action_event);

            let (Some(username), Some(password)) =
                (&exec_action_event.username, &exec_action_event.password)
            else {
                return Ok(Err(UserError::NoCredential(
                    exec_action_event.action_event_id,
                )));
            };

            let driver = WebDriver::new(WEBDRIVER_ADDRESS, caps).await?;

            let result =
                boxplanner_login(&driver, username, password, &exec_action_event, mode).await;

            debug!("closing browser");
            driver.quit().await?;

            result
        }));
    }

    let mut disable_action_event_ids = vec![];
    for task in tasks {
        match task.await?? {
            Ok(action_event_id) => disable_action_event_ids.push(action_event_id),
            Err(error) => {
                info!("{error}");
                disable_action_event_ids.push(error.action_event_id());
            }
        }
    }

    if !disable_action_event_ids.is_empty() {
        disable_events(
            &client,
            &config.server_url,
            NAME,
            &config.password,
            &disable_action_event_ids,
        )
        .await?;
    }

    debug!("terminating webdriver");
    webdriver.kill().await?;

    Ok(())
}

async fn boxplanner_login(
    driver: &WebDriver,
    username: &str,
    password: &str,
    exec_action_event: &ExecutableActionEvent,
    mode: Mode,
) -> Result<UserResult<ActionEventId>> {
    let time = exec_action_event
        .datetime
        .with_timezone(&Local)
        .format("%-H:%M")
        .to_string();
    let date = exec_action_event.datetime.format("%Y%m%d").to_string();

    driver.delete_all_cookies().await?;
    driver
        .goto("https://www.box-planner.com/External/PublicLogin/#/Login/")
        .await?;

    time::sleep(StdDuration::from_secs(3)).await;

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
    driver
        .find(By::Name("loginForm"))
        .await?
        .find(By::Tag("button"))
        .await?
        .click()
        .await?;

    time::sleep(StdDuration::from_secs(5)).await;

    if let Ok(feedback) = driver.find(By::ClassName("bootbox-body")).await {
        if feedback.inner_html().await? == "Invalid user name or password" {
            return Ok(Err(UserError::InvalidCredential(
                exec_action_event.action_event_id,
            )));
        }
    }

    if driver
        .find(By::ClassName("BoxPlannerIcon-CalendarMonth"))
        .await
        .is_err()
    {
        return Ok(Err(UserError::UnknownLoginError(
            exec_action_event.action_event_id,
        )));
    }

    debug!("login successful");

    driver
        .goto("https://www.box-planner.com/App#/Calendar")
        .await?;

    time::sleep(StdDuration::from_secs(5)).await;

    let current_month = exec_action_event.datetime.date_naive().month();
    let next_week_month = exec_action_event
        .datetime
        .date_naive()
        .checked_add_days(Days::new(7))
        .unwrap()
        .week(Weekday::Mon)
        .first_day()
        .month();

    if current_month < next_week_month {
        let buttons = driver
            .find(By::Id("calcontainer"))
            .await?
            .find_all(By::Tag("button"))
            .await?;
        for button in buttons {
            if button.inner_html().await? == "Next Month" {
                button.click().await?;
            }
        }
    }

    time::sleep(StdDuration::from_secs(5)).await;

    if let Ok(duration) =
        (exec_action_event.datetime - Duration::try_days(2).unwrap() - Utc::now()).to_std()
    {
        time::sleep(duration).await;
    }
    info!("ready"); // info for timing purposes

    for _ in 0..3 {
        driver.refresh().await?;
        info!("reload done"); // info for timing purposes

        let day_column = driver.find(By::Id(&date)).await?;
        let class_spans = day_column.find_all(By::Tag("span")).await?;
        for class in class_spans {
            let inner = class.inner_html().await?;
            if inner.contains(&time) && inner.contains(&exec_action_event.action_name) {
                class.parent().await?.click().await?;

                info!("reservation for {} done", exec_action_event.datetime);

                if mode == Mode::Interactive {
                    time::sleep(StdDuration::from_secs(3)).await;
                }

                return Ok(Ok(exec_action_event.action_event_id));
            }
        }
    }

    Ok(Err(UserError::ClassNotFound(
        exec_action_event.action_event_id,
        exec_action_event.action_name.clone(),
        exec_action_event.datetime,
    )))
}
