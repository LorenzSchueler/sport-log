use std::{
    env, fs,
    io::Error as IoError,
    process::{ExitCode, Stdio},
    result::Result as StdResult,
    time::Duration as StdDuration,
};

use chrono::Duration;
use clap::Parser;
use rand::Rng;
use regex::Regex;
use reqwest::{Client, Error as ReqwestError, StatusCode};
use serde::Deserialize;
use sport_log_ap_utils::{disable_events, get_events, setup as setup_db};
use sport_log_types::{
    uri::{route_max_version, WOD},
    ActionEventId, ExecutableActionEvent, Wod, WodId, ID_HEADER,
};
use sysinfo::System;
use thirtyfour::{error::WebDriverError, prelude::*, WebDriver};
use thiserror::Error;
use tokio::{process::Command, task::JoinError, time};
use tracing::{debug, error, info, warn};
use tracing_subscriber::EnvFilter;

const CONFIG_FILE: &str = "sport-log-action-provider-wodify-wod.toml";
const NAME: &str = "wodify-wod";
const DESCRIPTION: &str =
    "Wodify Wod can fetch the Workout of the Day and save it in your wods. The action names correspond to the class type the wod should be fetched for.";
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
    #[error("no wod found")]
    WodNotFound(ActionEventId),
    #[error("no wod result found")]
    ResultNotFound(ActionEventId),
}

impl UserError {
    fn action_event_id(&self) -> ActionEventId {
        match self {
            Self::NoCredential(action_event_id)
            | Self::InvalidCredential(action_event_id)
            | Self::CaptchaRequired(action_event_id)
            | Self::UnknownLoginError(action_event_id)
            | Self::WodNotFound(action_event_id)
            | Self::ResultNotFound(action_event_id) => *action_event_id,
        }
    }
}

type UserResult<T> = StdResult<T, UserError>;

/// The config for [`sport-log-action-provider-wodify-wod`](crate).
///
/// The name of the config file is specified in [`CONFIG_FILE`].
///
/// `admin_password` is the password for the admin endpoints.
///
/// `server_url` is the left part of the URL (everything before `/<version>/...`)
#[derive(Deserialize, Debug, Clone)]
struct Config {
    password: String,
    server_url: String,
}

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
enum Mode {
    Headless,
    Interactive,
}

/// Wodify Wod Action Provider
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
                "info,sport_log_action_provider_wodify_wod=debug",
            );
        } else {
            env::set_var("RUST_LOG", "warn,sport_log_action_provider_wodify_wod=info");
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
        if let Err(error) = get_wod(&config, mode).await {
            warn!("fetching wod failed: {error}");
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
        &[(
            "Metcon",
            "Fetch and save the metcon description and results for the current day.",
        )],
        Duration::try_days(7).unwrap(),
        Duration::try_days(1).unwrap(),
    )
    .await?;

    Ok(())
}

async fn get_wod(config: &Config, mode: Mode) -> Result<()> {
    let client = Client::new();

    let exec_action_events = get_events(
        &client,
        &config.server_url,
        NAME,
        &config.password,
        Duration::try_days(-1).unwrap(),
        Duration::zero(),
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
        let client = client.clone();
        let config = config.clone();
        tasks.push(tokio::spawn(async move {
            debug!("processing: {:#?}", exec_action_event);

            let (Some(username), Some(password)) =
                (&exec_action_event.username, &exec_action_event.password)
            else {
                return Ok(Err(UserError::NoCredential(
                    exec_action_event.action_event_id,
                )));
            };

            let driver = WebDriver::new(WEBDRIVER_ADDRESS, caps).await?;

            let result = try_create_wod(
                &config,
                &driver,
                &client,
                username,
                password,
                &exec_action_event,
                mode,
            )
            .await;

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
                    | UserError::WodNotFound(_)
                    | UserError::ResultNotFound(_) => {
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

async fn try_create_wod(
    config: &Config,
    driver: &WebDriver,
    client: &Client,
    username: &str,
    password: &str,
    exec_action_event: &ExecutableActionEvent,
    mode: Mode,
) -> Result<UserResult<ActionEventId>> {
    let action_date = exec_action_event.datetime.date_naive();
    let action_date_string = action_date.format("%m/%d/%Y").to_string();

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

    time::sleep(StdDuration::from_secs(10)).await;

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
        .goto("https://app.wodify.com/WOD/WODEntry.aspx")
        .await?;

    let date_input = driver.find(By::Id("AthleteTheme_wtLayoutNormal_block_wtSubNavigation_W_Utils_UI_wt3_block_wtDateInputFrom")).await?;
    date_input.clear().await?;
    date_input.send_keys(&action_date_string).await?;

    time::sleep(StdDuration::from_secs(3)).await;

    let Ok(wod) = driver
        .find(By::Id(
            "AthleteTheme_wtLayoutNormal_block_wtMainContent_AthleteTheme_wt9_block_wtWODComponentsList"
        ))
        .await
    else {
        return Ok(Err(UserError::WodNotFound(
            exec_action_event.action_event_id,
        )));
    };

    let name = wod
        .find(By::ClassName("component_name"))
        .await?
        .inner_html()
        .await?;

    let content = wod
        .find(By::ClassName("component_wrapper"))
        .await?
        .inner_html()
        .await?;

    let name = parse_inner_html(&name);
    let content = parse_inner_html(&content);

    driver
        .goto("https://app.wodify.com/Performance/MyPerformance_Metcon.aspx")
        .await?;

    let Ok(result_table) = driver.find(By::ClassName("TableRecords")).await else {
        return Ok(Err(UserError::ResultNotFound(
            exec_action_event.action_event_id,
        )));
    };
    let result_entry = result_table
        .find(By::Tag("tbody"))
        .await?
        .find(By::Tag("tr"))
        .await?
        .find_all(By::Tag("td"))
        .await?;

    let date = result_entry[0].inner_html().await?;
    if date != action_date_string {
        return Ok(Err(UserError::ResultNotFound(
            exec_action_event.action_event_id,
        )));
    }
    let result = result_entry[6].inner_html().await?;
    let rx = result_entry[7]
        .find(By::ClassName("RxOnNoClick"))
        .await
        .is_ok();
    let comments = parse_inner_html(&result_entry[9].inner_html().await?);

    let description = format!(
        "{name}\n{content}\n\nResult: {result} {}{}",
        if rx { "RX" } else { "Scaled" },
        if !comments.is_empty() {
            "\nComments: ".to_owned() + comments.as_str()
        } else {
            String::new()
        }
    );

    let wod = Wod {
        id: WodId(rand::thread_rng().gen()),
        user_id: exec_action_event.user_id,
        date: action_date,
        description: Some(description),
        deleted: false,
    };

    let response = client
        .post(route_max_version(&config.server_url, WOD, None))
        .basic_auth(NAME, Some(&config.password))
        .header(ID_HEADER, exec_action_event.user_id.0)
        .json(&wod)
        .send()
        .await?;

    match response.status() {
        StatusCode::CONFLICT => info!("wod already exists"),
        StatusCode::OK => info!("new wod created"),
        _ => {
            response.error_for_status()?; // this will always fail and return the error
        }
    }

    if mode == Mode::Interactive {
        time::sleep(StdDuration::from_secs(3)).await;
    }

    Ok(Ok(exec_action_event.action_event_id))
}

fn parse_inner_html(inner_html: &str) -> String {
    //static re: LazyCell<Regex> = LazyCell::new(|| Regex::new(r"</*.+?>").unwrap()); // TODO needs
    // LazyCell stabilization
    let content = inner_html
        .replace("<br>", "\n")
        .replace("<p>", "\n")
        .replace("&nbsp;", " ");
    Regex::new(r"</*.+?>")
        .unwrap()
        .replace_all(&content, "")
        .replace("\n\n", "\n")
        .replace("\n ", "\n")
        .trim()
        .to_owned()
}
