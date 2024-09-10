use std::{
    env, fs,
    io::Error as IoError,
    process::{ExitCode, Stdio},
    result::Result as StdResult,
    time::Duration as StdDuration,
};

use chrono::{DateTime, Duration, Local, Utc};
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

const CONFIG_FILE: &str = "sport-log-action-provider-wodify-login.toml";
const NAME: &str = "wodify-login";
const DESCRIPTION: &str =
    "Wodify Login can reserve spots in classes. The action names correspond to the class types.";
const PLATFORM_NAME: &str = "wodify";

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
    CaptchaRequired(ActionEventId),
    #[error("can not log in: unknown error")]
    UnknownLoginError(ActionEventId),
    #[error("{1} class at {2} not found within timeout")]
    ClassNotFound(ActionEventId, String, DateTime<Utc>),
}

impl UserError {
    fn action_event_id(&self) -> ActionEventId {
        match self {
            Self::NoCredential(action_event_id)
            | Self::InvalidCredential(action_event_id)
            | Self::CaptchaRequired(action_event_id)
            | Self::UnknownLoginError(action_event_id)
            | Self::ClassNotFound(action_event_id, ..) => *action_event_id,
        }
    }
}

type UserResult<T> = StdResult<T, UserError>;

/// The config for [`sport-log-action-provider-wodify-login`](crate).
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

/// Wodify Login Action Provider
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
                "info,sport_log_action_provider_wodify_login=debug",
            );
        } else {
            env::set_var(
                "RUST_LOG",
                "warn,sport_log_action_provider_wodify_login=info",
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
        &[
            ("CrossFit", "Reserve a spot in a CrossFit class."),
            ("Weightlifting", "Reserve a spot in a Weightlifting class."),
            ("Open Fridge", "Reserve a spot in a Open Fridge class."),
            ("Open Gym", "Reserve a spot in a Open Gym class."),
            ("Gymnastics", "Reserve a spot in a Gymnastics class."),
            ("Strongmen", "Reserve a spot in a Strongmen class."),
            ("Yoga", "Reserve a spot in a Yoga class."),
            ("Swim WOD", "Reserve a spot in a Swim class."),
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
        Duration::try_days(1).unwrap() + Duration::try_minutes(2).unwrap(),
    )
    .await?;

    if exec_action_events.is_empty() {
        return Ok(());
    }

    for p in System::new_all().processes_by_name(GECKODRIVER.as_ref()) {
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

            let result = wodify_login(&driver, username, password, &exec_action_event, mode).await;

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
                match error {
                    UserError::NoCredential(_) | UserError::InvalidCredential(_) => {
                        disable_action_event_ids.push(error.action_event_id());
                    }
                    UserError::CaptchaRequired(_)
                    | UserError::UnknownLoginError(_)
                    | UserError::ClassNotFound(_, _, _) => {
                        info!("trying again on next invocation");
                    }
                }
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

async fn wodify_login(
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
    let date = exec_action_event.datetime.format("%m/%d/%Y").to_string();

    driver.delete_all_cookies().await?;
    driver.goto("https://app.wodify.com").await?;

    time::sleep(StdDuration::from_secs(3)).await;

    driver
        .find(By::Id("Input_UserName"))
        .await?
        .send_keys(username)
        .await?;
    driver
        .find(By::Id("Input_Password"))
        .await?
        .send_keys(password)
        .await?;
    driver
        .find(By::ClassName("signin-btn"))
        .await?
        .click()
        .await?;

    time::sleep(StdDuration::from_secs(5)).await;

    if let Ok(feedback) = driver.find(By::ClassName("feedback-message-text")).await {
        if feedback.inner_html().await? == "Invalid email or password." {
            return Ok(Err(UserError::InvalidCredential(
                exec_action_event.action_event_id,
            )));
        }
    }

    if let Ok(button) = driver.find(By::Id("recaptcha-verify-button")).await {
        if button.is_clickable().await? {
            return Ok(Err(UserError::CaptchaRequired(
                exec_action_event.action_event_id,
            )));
        }
    }

    if driver.find(By::LinkText("Logout")).await.is_err() {
        return Ok(Err(UserError::UnknownLoginError(
            exec_action_event.action_event_id,
        )));
    }

    debug!("login successful");

    driver
        .goto("https://app.wodify.com/Schedule/CalendarListViewEntry.aspx")
        .await?;

    if let Ok(duration) =
        (exec_action_event.datetime - Duration::try_days(1).unwrap() - Utc::now()).to_std()
    {
        time::sleep(duration).await;
    }
    info!("ready"); // info for timing purposes

    driver.refresh().await?;
    info!("reload done"); // info for timing purposes

    let table = driver
        .find(By::ClassName("TableRecords"))
        .await?
        .find(By::Tag("tbody"))
        .await?;

    let rows = table.find_all(By::Tag("tr")).await?;

    let mut start_row_number = rows.len();
    for (i, row) in rows.iter().enumerate() {
        if let Ok(day) = row
            .find(By::XPath("./td[1]/span[contains(@class, \"h3\")]"))
            .await
        {
            if day.inner_html().await?.contains(&date) {
                start_row_number = i + 1;
                break;
            }
        }
    }

    let mut end_row_number = rows.len();
    for (i, row) in rows[start_row_number..].iter().enumerate() {
        if row
            .find(By::XPath("./td[1]/span[contains(@class, \"h3\")]"))
            .await
            .is_ok()
        {
            end_row_number = start_row_number + i;
            break;
        }
    }

    for row in &rows[start_row_number..end_row_number] {
        let row_matches = row
            .find(By::XPath("./td[1]/div/span"))
            .await?
            .attr("title")
            .await?
            .map_or(false, |title| {
                title.contains(&exec_action_event.action_name) && title.contains(&time)
            });

        if row_matches {
            let icon = row.find(By::XPath("./td[3]/div")).await?;
            icon.scroll_into_view().await?;
            icon.click().await?;
            info!("reservation for {} done", exec_action_event.datetime);

            if mode == Mode::Interactive {
                time::sleep(StdDuration::from_secs(3)).await;
            }

            return Ok(Ok(exec_action_event.action_event_id));
        }
    }

    Ok(Err(UserError::ClassNotFound(
        exec_action_event.action_event_id,
        exec_action_event.action_name.clone(),
        exec_action_event.datetime,
    )))
}
