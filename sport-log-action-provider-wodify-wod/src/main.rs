use std::{
    env, fs,
    io::Error as IoError,
    process::{self, Stdio},
    result::Result as StdResult,
    time::Duration as StdDuration,
};

use chrono::Duration;
use clap::Parser;
use lazy_static::lazy_static;
use rand::Rng;
use regex::Regex;
use reqwest::{Client, Error as ReqwestError, StatusCode};
use serde::Deserialize;
use sport_log_ap_utils::{disable_events, get_events, setup as setup_db};
use sport_log_types::{
    uri::{route_max_version, WOD},
    ActionEventId, ExecutableActionEvent, Wod, WodId,
};
use sysinfo::{ProcessExt, System, SystemExt};
use thirtyfour::{error::WebDriverError, prelude::*, WebDriver};
use thiserror::Error;
use tokio::{process::Command, task::JoinError, time};
use tracing::{debug, error, info, warn};
use tracing_subscriber::EnvFilter;

const ID_HEADER: &str = "id"; // TODO use ID_HEADER from sport-log-types

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
    #[error("can not log in: login failed")]
    LoginFailed(ActionEventId),
    #[error("the wod could not be found")]
    WodNotFound(ActionEventId),
    #[error("the result for the wod could not be found")]
    ResultNotFound(ActionEventId),
}

impl UserError {
    fn action_event_id(&self) -> ActionEventId {
        match self {
            Self::NoCredential(action_event_id)
            | Self::LoginFailed(action_event_id)
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
#[derive(Deserialize, Debug)]
struct Config {
    password: String,
    server_url: String,
}

lazy_static! {
    static ref CONFIG: Config = match fs::read_to_string(CONFIG_FILE) {
        Ok(file) => match toml::from_str(&file) {
            Ok(config) => config,
            Err(error) => {
                error!("Failed to parse {}: {}", CONFIG_FILE, error);
                process::exit(1);
            }
        },
        Err(error) => {
            error!("Failed to read {}: {}", CONFIG_FILE, error);
            process::exit(1);
        }
    };
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
async fn main() {
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

    if args.setup {
        if let Err(error) = setup().await {
            warn!("setup failed: {}", error);
        }
    } else {
        let mode = if args.interactive {
            Mode::Interactive
        } else {
            Mode::Headless
        };
        if let Err(error) = get_wod(mode).await {
            warn!("fetching wod failed: {}", error);
        }
    }
}

async fn setup() -> Result<()> {
    setup_db(
        &CONFIG.server_url,
        NAME,
        &CONFIG.password,
        DESCRIPTION,
        PLATFORM_NAME,
        true,
        &[(
            "Metcon",
            "Fetch and save the metcon description and results for the current day.",
        )],
        Duration::hours(168),
        Duration::hours(24),
    )
    .await?;

    Ok(())
}

async fn get_wod(mode: Mode) -> Result<()> {
    let client = Client::new();

    let exec_action_events = get_events(
        &client,
        &CONFIG.server_url,
        NAME,
        &CONFIG.password,
        Duration::days(-1),
        Duration::zero(),
    )
    .await?;

    debug!("got {} executable action events", exec_action_events.len());

    if exec_action_events.is_empty() {
        return Ok(());
    }

    for p in System::new_all().processes_by_name(GECKODRIVER) {
        p.kill();
    }

    let mut webdriver = Command::new(GECKODRIVER).stdout(Stdio::null()).spawn()?;

    time::sleep(StdDuration::from_secs(1)).await; // make sure geckodriver is available

    let mut caps = DesiredCapabilities::firefox();
    if mode == Mode::Headless {
        caps.set_headless()?;
    }

    let mut tasks = vec![];
    for exec_action_event in exec_action_events {
        let caps = caps.clone();
        let client = client.clone();

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
                disable_action_event_ids.push(error.action_event_id());
            }
        }
    }

    debug!(
        "deleting {} action event ({:?})",
        disable_action_event_ids.len(),
        disable_action_event_ids
    );

    if !disable_action_event_ids.is_empty() {
        disable_events(
            &client,
            &CONFIG.server_url,
            NAME,
            &CONFIG.password,
            &disable_action_event_ids,
        )
        .await?;
    }

    debug!("terminating webdriver");
    webdriver.kill().await?;

    Ok(())
}

async fn try_create_wod(
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

    time::sleep(StdDuration::from_secs(5)).await;

    if driver.find(By::LinkText("Logout")).await.is_err() {
        return Ok(Err(UserError::LoginFailed(
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

    let Ok(wod) = driver.find(By::ClassName("ListRecords")).await else {
        return Ok(Err(UserError::WodNotFound(
            exec_action_event.action_event_id,
        )));
    };
    let wod = wod.find(By::ClassName("component_show_wrapper")).await?;

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
            "\nComments: ".to_owned() + &comments
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
        .post(route_max_version(&CONFIG.server_url, WOD, None))
        .basic_auth(NAME, Some(&CONFIG.password))
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
    //static re: LazyCell<Regex> = LazyCell::new(|| Regex::new(r"</*.+?>").unwrap());
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
