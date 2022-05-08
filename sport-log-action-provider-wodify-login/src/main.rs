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
use sport_log_types::{ActionEventId, ExecutableActionEvent};
use thirtyfour::{error::WebDriverError, prelude::*, WebDriver};
use tracing::{debug, error, info};

use sport_log_ap_utils::{delete_events, get_events, setup as setup_db};
use tokio::{process::Command, time};

const CONFIG_FILE: &str = "sport-log-action-provider-wodify-login.toml";
const NAME: &str = "wodify-login";
const DESCRIPTION: &str =
    "Wodify Login can reserve spots in classes. The action names correspond to the class types.";
const PLATFORM_NAME: &str = "wodify";

#[derive(Debug, StdError)]
enum Error {
    #[error(display = "{}", _0)]
    Reqwest(ReqwestError),
    #[error(display = "{}", _0)]
    Io(IoError),
    #[error(display = "{}", _0)]
    WebDriver(WebDriverError),
    #[error(display = "ExecutableActionEvent doesn't contain credentials")]
    NoCredential(ActionEventId),
    #[error(display = "login failed")]
    LoginFailed(ActionEventId),
    #[error(display = "the class could not be found within the timeout")]
    Timeout(ActionEventId),
}

type Result<T> = StdResult<T, Error>;

/// The config for [sport-log-action-provider-wodify-login](crate).
///
/// The name of the config file is specified in [CONFIG_FILE].
///
/// `admin_password` is the password for the admin endpoints.
///
/// `base_url` is the left part of the URL (everthing before `/<version>/...`)
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

    tracing_subscriber::fmt()
        .with_writer(std::io::stderr)
        .init();

    match &env::args().collect::<Vec<_>>()[1..] {
        [] => {
            if let Err(error) = login(Mode::Headless).await {
                error!("login failed: {}", error);
            }
        }
        [option] if option == "--interactive" => {
            if let Err(error) = login(Mode::Interactive).await {
                error!("login failed: {}", error);
            }
        }
        [option] if option == "--setup" => {
            if let Err(error) = setup().await {
                error!("setup failed: {}", error);
            }
        }
        [option] if ["help", "-h", "--help"].contains(&option.as_str()) => help(),
        _ => wrong_use(),
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
        &[
            ("CrossFit", "Reserve a spot in a CrossFit class."),
            ("Weightlifting", "Reserve a spot in a Weightlifting class."),
            ("Open Fridge", "Reserve a spot in a Open Fridge class."),
            ("Open Gym", "Reserve a spot in a Open Gym class."),
            ("Gymnastics", "Reserve a spot in a Gymnastics class."),
            ("Strongman", "Reserve a spot in a Strongman class."),
            ("Yoga", "Reserve a spot in a Yoga class."),
            ("Swim WOD", "Reserve a spot in a Swim class."),
        ],
        168,
        0,
    )
    .await
    .map_err(Error::Reqwest)
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

    let mut webdriver = Command::new("geckodriver")
        .stdout(Stdio::null())
        .spawn()
        .map_err(Error::Io)?;

    let mut caps = DesiredCapabilities::firefox();
    if mode == Mode::Headless {
        caps.set_headless().unwrap_or(());
    }

    let mut tasks = vec![];
    for exec_action_event in exec_action_events {
        let caps = caps.clone();

        tasks.push(tokio::spawn(async move {
            debug!("processing {:#?}", exec_action_event);

            match (&exec_action_event.username, &exec_action_event.password) {
                (Some(username), Some(password)) => {
                    let driver = WebDriver::new_with_timeout(
                        "http://localhost:4444/",
                        &caps,
                        Some(StdDuration::from_secs(5)),
                    )
                    .await
                    .map_err(Error::WebDriver)?;

                    let result =
                        try_login(&driver, username, password, &exec_action_event, mode).await;

                    debug!("closing browser");
                    driver.quit().await.map_err(Error::WebDriver)?;

                    result
                }
                _ => Err(Error::NoCredential(exec_action_event.action_event_id)),
            }
        }));
    }

    let mut delete_action_event_ids = vec![];
    for task in tasks {
        match task.await {
            Ok(result) => match result {
                Ok(action_event_id) => delete_action_event_ids.push(action_event_id),
                Err(Error::NoCredential(action_event_id)) => {
                    info!("can not log in: no credential provided");
                    delete_action_event_ids.push(action_event_id)
                }
                Err(Error::LoginFailed(action_event_id)) => {
                    info!("can not log in: login failed");
                    delete_action_event_ids.push(action_event_id)
                }
                Err(Error::Timeout(_)) => {
                    info!("timeout")
                }
                Err(error) => error!("{}", error),
            },
            Err(join_error) => error!("execution of action event failed: {}", join_error),
        }
    }

    debug!("deleting {} action event", delete_action_event_ids.len());
    debug!("delete event ids: {:?}", delete_action_event_ids);

    if !delete_action_event_ids.is_empty() {
        delete_events(
            &client,
            &CONFIG.server_url,
            NAME,
            &CONFIG.password,
            &delete_action_event_ids,
        )
        .await
        .map_err(Error::Reqwest)?;
    }

    info!("terminating webdriver");
    let _ = webdriver.kill().await;

    Ok(())
}

async fn try_login(
    driver: &WebDriver,
    username: &str,
    password: &str,
    exec_action_event: &ExecutableActionEvent,
    mode: Mode,
) -> Result<ActionEventId> {
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
        .get("https://app.wodify.com/Schedule/CalendarListView.aspx")
        .await
        .map_err(Error::WebDriver)?;

    time::sleep(StdDuration::from_secs(3)).await;

    driver
        .find_element(By::Id("Input_UserName"))
        .await
        .map_err(Error::WebDriver)?
        .send_keys(username)
        .await
        .map_err(Error::WebDriver)?;
    driver
        .find_element(By::Id("Input_Password"))
        .await
        .map_err(Error::WebDriver)?
        .send_keys(password)
        .await
        .map_err(Error::WebDriver)?;
    driver
        .find_element(By::ClassName("signin-btn"))
        .await
        .map_err(Error::WebDriver)?
        .click()
        .await
        .map_err(Error::WebDriver)?;

    time::sleep(StdDuration::from_secs(2)).await;

    if driver
        .find_element(By::Id("AthleteTheme_wt6_block_wt9_wtLogoutLink"))
        .await
        .is_err()
    {
        info!("login failed");
        return Err(Error::LoginFailed(exec_action_event.action_event_id));
    }
    debug!("login successful");

    if let Ok(duration) = (exec_action_event.datetime - Duration::days(1) - Utc::now()).to_std() {
        time::sleep(duration).await;
    }
    debug!("ready");

    for _ in 0..10 {
        driver.refresh().await.map_err(Error::WebDriver)?; // TODO can this be removed?
        debug!("reload done");

        let rows = driver
            .find_elements(By::XPath("//table[@class='TableRecords']/tbody/tr"))
            .await
            .map_err(Error::WebDriver)?;

        let mut row_number = rows.len();
        for (i, row) in rows.iter().enumerate() {
            if let Ok(day) = row
                .find_element(By::XPath("./td[1]/span[contains(@class, \"h3\")]"))
                .await
            {
                if day
                    .inner_html()
                    .await
                    .map_err(Error::WebDriver)?
                    .contains(&date)
                {
                    row_number = i;
                    break;
                }
            }
        }

        for row in &rows[row_number + 1..] {
            if let Ok(label) = row.find_element(By::XPath("./td[1]/div/span")).await {
                if let Some(title) = label
                    .get_attribute("title")
                    .await
                    .map_err(Error::WebDriver)?
                {
                    if title.contains(&exec_action_event.action_name) && title.contains(&time) {
                        let icon = row
                            .find_element(By::XPath("./td[3]/div"))
                            .await
                            .map_err(Error::WebDriver)?;
                        icon.scroll_into_view().await.map_err(Error::WebDriver)?;
                        icon.click().await.map_err(Error::WebDriver)?;
                        info!(
                            "reservation for {} at {}",
                            exec_action_event.datetime,
                            Utc::now()
                        );

                        if mode == Mode::Interactive {
                            time::sleep(StdDuration::from_secs(3)).await;
                        }

                        return Ok(exec_action_event.action_event_id);
                    }
                }
            }
        }
    }

    Err(Error::Timeout(exec_action_event.action_event_id))
}
