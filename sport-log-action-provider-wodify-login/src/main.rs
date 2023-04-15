use std::{
    env, fs,
    io::Error as IoError,
    process::{self, Stdio},
    result::Result as StdResult,
    time::Duration as StdDuration,
};

use chrono::{Duration, Local, Utc};
use err_derive::Error as StdError;
use lazy_static::lazy_static;
use reqwest::{Client, Error as ReqwestError};
use serde::Deserialize;
use sport_log_ap_utils::{disable_events, get_events, setup as setup_db};
use sport_log_types::{ActionEventId, ExecutableActionEvent};
use sysinfo::{ProcessExt, System, SystemExt};
use thirtyfour::{error::WebDriverError, prelude::*, WebDriver};
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

#[derive(Debug, StdError)]
enum Error {
    #[error(display = "{}", _0)]
    Reqwest(ReqwestError),
    #[error(display = "{}", _0)]
    Io(IoError),
    #[error(display = "{}", _0)]
    WebDriver(WebDriverError),
    #[error(display = "{}", _0)]
    Join(JoinError),
}

type Result<T> = StdResult<T, Error>;

#[derive(Debug, StdError)]
enum UserError {
    #[error(display = "can not log in: no credentials provided")]
    NoCredential(ActionEventId),
    #[error(display = "can not log in: login failed")]
    LoginFailed(ActionEventId),
    #[error(display = "the class could not be found within the timeout")]
    ClassNotFound(ActionEventId),
}

impl UserError {
    fn action_event_id(&self) -> ActionEventId {
        match self {
            Self::NoCredential(action_event_id)
            | Self::LoginFailed(action_event_id)
            | Self::ClassNotFound(action_event_id) => *action_event_id,
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
/// `base_url` is the left part of the URL (everything before `/<version>/...`)
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

#[tokio::main]
async fn main() {
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

    match &env::args().collect::<Vec<_>>()[1..] {
        [] => {
            if let Err(error) = login(Mode::Headless).await {
                warn!("login failed: {}", error);
            }
        }
        [option] if option == "--interactive" => {
            if let Err(error) = login(Mode::Interactive).await {
                warn!("login failed: {}", error);
            }
        }
        [option] if option == "--setup" => setup().await,
        [option] if ["help", "-h", "--help"].contains(&option.as_str()) => help(),
        _ => wrong_use(),
    }
}

async fn setup() {
    setup_db(
        &CONFIG.server_url,
        NAME,
        &CONFIG.password,
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
        168,
        0,
    )
    .await
    .unwrap();
}

fn help() {
    println!(
        "Wodify Login Action Provider\n\n\
        USAGE:\n\
        sport-log-action-provider-wodify-login [OPTIONS]\n\n\
        OPTIONS:\n\
        -h, --help\tprint this help page\n\
        --interactive\tuse interactive webdriver session (with browser window)\n\
        --setup\t\tcreate own actions"
    );
}

fn wrong_use() {
    println!("no such options");
}

async fn login(mode: Mode) -> Result<()> {
    let client = Client::new();

    let exec_action_events = get_events(
        &client,
        &CONFIG.server_url,
        NAME,
        &CONFIG.password,
        Duration::hours(0),
        Duration::days(1) + Duration::minutes(2),
    )
    .await
    .map_err(Error::Reqwest)?;

    debug!("got {} executable action events", exec_action_events.len());

    if exec_action_events.is_empty() {
        return Ok(());
    }

    for p in System::new_all().processes_by_name(GECKODRIVER) {
        p.kill();
    }

    let mut webdriver = Command::new(GECKODRIVER)
        .stdout(Stdio::null())
        .spawn()
        .map_err(Error::Io)?;

    time::sleep(StdDuration::from_secs(1)).await; // make sure geckodriver is available

    let mut caps = DesiredCapabilities::firefox();
    if mode == Mode::Headless {
        caps.set_headless().map_err(Error::WebDriver)?;
    }

    let mut tasks = vec![];
    for exec_action_event in exec_action_events {
        let caps = caps.clone();

        tasks.push(tokio::spawn(async move {
            debug!("processing {:#?}", exec_action_event);

            let (Some(username), Some(password)) =
                (&exec_action_event.username, &exec_action_event.password) else {
                return Ok(Err(UserError::NoCredential(exec_action_event.action_event_id)));
            };

            let driver = WebDriver::new(WEBDRIVER_ADDRESS, caps)
                .await
                .map_err(Error::WebDriver)?;

            let result = wodify_login(&driver, username, password, &exec_action_event, mode).await;

            debug!("closing browser");
            driver.quit().await.map_err(Error::WebDriver)?;

            result
        }));
    }

    let mut disable_action_event_ids = vec![];
    for task in tasks {
        match task.await.map_err(Error::Join)?? {
            Ok(action_event_id) => disable_action_event_ids.push(action_event_id),
            Err(error) => {
                info!("{error}");
                disable_action_event_ids.push(error.action_event_id());
            }
        }
    }

    debug!(
        "deleting {} action events ({:?})",
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
        .await
        .map_err(Error::Reqwest)?;
    }

    debug!("terminating webdriver");
    webdriver.kill().await.map_err(Error::Io)?;

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

    driver
        .delete_all_cookies()
        .await
        .map_err(Error::WebDriver)?;
    driver
        .goto("https://app.wodify.com")
        .await
        .map_err(Error::WebDriver)?;

    time::sleep(StdDuration::from_secs(3)).await;

    driver
        .find(By::Id("Input_UserName"))
        .await
        .map_err(Error::WebDriver)?
        .send_keys(username)
        .await
        .map_err(Error::WebDriver)?;
    driver
        .find(By::Id("Input_Password"))
        .await
        .map_err(Error::WebDriver)?
        .send_keys(password)
        .await
        .map_err(Error::WebDriver)?;
    driver
        .find(By::ClassName("signin-btn"))
        .await
        .map_err(Error::WebDriver)?
        .click()
        .await
        .map_err(Error::WebDriver)?;

    time::sleep(StdDuration::from_secs(5)).await;

    if driver.find(By::LinkText("Logout")).await.is_err() {
        return Ok(Err(UserError::LoginFailed(
            exec_action_event.action_event_id,
        )));
    }
    debug!("login successful");

    driver
        .goto("https://app.wodify.com/Schedule/CalendarListViewEntry.aspx")
        .await
        .map_err(Error::WebDriver)?;

    if let Ok(duration) = (exec_action_event.datetime - Duration::days(1) - Utc::now()).to_std() {
        time::sleep(duration).await;
    }
    info!("ready");

    for _ in 0..3 {
        driver.refresh().await.map_err(Error::WebDriver)?;
        info!("reload done");

        let table = driver
            .find(By::ClassName("TableRecords"))
            .await
            .map_err(Error::WebDriver)?
            .find(By::Tag("tbody"))
            .await
            .map_err(Error::WebDriver)?;

        let rows = table
            .find_all(By::Tag("tr"))
            .await
            .map_err(Error::WebDriver)?;

        let mut start_row_number = rows.len();
        for (i, row) in rows.iter().enumerate() {
            if let Ok(day) = row
                .find(By::XPath("./td[1]/span[contains(@class, \"h3\")]"))
                .await
            {
                if day
                    .inner_html()
                    .await
                    .map_err(Error::WebDriver)?
                    .contains(&date)
                {
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
                .await
                .map_err(Error::WebDriver)?
                .attr("title")
                .await
                .map_err(Error::WebDriver)?
                .map_or(false, |title| {
                    title.contains(&exec_action_event.action_name) && title.contains(&time)
                });

            if row_matches {
                let icon = row
                    .find(By::XPath("./td[3]/div"))
                    .await
                    .map_err(Error::WebDriver)?;
                icon.scroll_into_view().await.map_err(Error::WebDriver)?;
                icon.click().await.map_err(Error::WebDriver)?;
                info!("reservation for {} done", exec_action_event.datetime);

                if mode == Mode::Interactive {
                    time::sleep(StdDuration::from_secs(3)).await;
                }

                return Ok(Ok(exec_action_event.action_event_id));
            }
        }

        info!(
            "no {} class at {} found",
            &exec_action_event.action_name, &exec_action_event.datetime
        );
    }

    Ok(Err(UserError::ClassNotFound(
        exec_action_event.action_event_id,
    )))
}
