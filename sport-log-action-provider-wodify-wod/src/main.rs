use std::{
    env, fs, io::Error as IoError, process, result::Result as StdResult,
    time::Duration as StdDuration,
};

use chrono::{Duration, Local, Utc};
use lazy_static::lazy_static;
use rand::Rng;
use reqwest::{Client, Error as ReqwestError, StatusCode};
use serde::Deserialize;
use sport_log_ap_utils::{disable_events, get_events, setup as setup_db};
use sport_log_types::{
    uri::{route_max_version, WOD},
    ActionEventId, ExecutableActionEvent, Wod, WodId, ID_HEADER,
};
use thirtyfour::{error::WebDriverError, prelude::*, WebDriver};
use thiserror::Error;
use tokio::{process::Command, time};
use tracing::{debug, error, info, warn};
use tracing_subscriber::EnvFilter;

const CONFIG_FILE: &str = "sport-log-action-provider-wodify-wod.toml";
const NAME: &str = "wodify-wod";
const DESCRIPTION: &str =
    "Wodify Wod can fetch the Workout of the Day and save it in your wods. The action names correspond to the class type the wod should be fetched for.";
const PLATFORM_NAME: &str = "wodify";

#[derive(Debug, Error)]
enum Error {
    #[error("{0}")]
    Reqwest(#[from] ReqwestError),
    #[error("{0}")]
    Io(#[from] IoError),
    #[error("{0}")]
    WebDriver(#[from] WebDriverError),
    #[error("ExecutableActionEvent doesn't contain credentials")]
    NoCredential(ActionEventId),
    #[error("login failed")]
    LoginFailed(ActionEventId),
    #[error("the wod could not be found")]
    WodNotFound(ActionEventId),
}

type Result<T> = StdResult<T, Error>;

/// The config for [`sport-log-action-provider-wodify-wod`](crate).
///
/// The name of the config file is specified in [`CONFIG_FILE`].
///
/// `admin_password` is the password for the admin endpoints.
///
/// `base_url` is the left part of the URL (everything before `/<version>/...`)
#[derive(Deserialize, Debug)]
struct Config {
    password: String,
    base_url: String,
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
                "info,sport_log_action_provider_wodify_wod=debug",
            );
        } else {
            env::set_var("RUST_LOG", "warn");
        }
    }

    tracing_subscriber::fmt()
        .with_writer(std::io::stderr)
        .with_env_filter(EnvFilter::from_default_env())
        .init();

    match &env::args().collect::<Vec<_>>()[1..] {
        [] => {
            if let Err(error) = get_wod(Mode::Headless).await {
                error!("login failed: {}", error);
            }
        }
        [option] if option == "--interactive" => {
            if let Err(error) = get_wod(Mode::Interactive).await {
                error!("login failed: {}", error);
            }
        }
        [option] if option == "--setup" => setup().await,
        [option] if ["help", "-h", "--help"].contains(&option.as_str()) => help(),
        _ => wrong_use(),
    }
}

async fn setup() {
    setup_db(
        &CONFIG.base_url,
        NAME,
        &CONFIG.password,
        DESCRIPTION,
        PLATFORM_NAME,
        true,
        &[
            (
                "CrossFit",
                "Fetch and save the CrossFit wod for the current day.",
            ),
            (
                "Weightlifting",
                "Fetch and save the Weightlifting wod for the current day.",
            ),
            (
                "Open Fridge",
                "Fetch and save the Open Fridge wod for the current day.",
            ),
        ],
        168,
        0,
    )
    .await
    .unwrap();
}

fn help() {
    println!(
        "Wodify Wod Action Provider\n\n\
        USAGE:\n\
        sport-log-action-provider-wodify-wod [OPTIONS]\n\n\
        OPTIONS:\n\
        -h, --help\tprint this help page\n\
        --interactive\tuse interactive webdriver session (with browser window)\n\
        --setup\t\tcreate own actions"
    );
}

fn wrong_use() {
    println!("no such options");
}

async fn get_wod(mode: Mode) -> Result<()> {
    let client = Client::new();

    let exec_action_events = get_events(
        &client,
        &CONFIG.base_url,
        NAME,
        &CONFIG.password,
        Duration::hours(0),
        Duration::days(1) + Duration::minutes(1),
    )
    .await?;

    info!("got {} executable action events", exec_action_events.len());

    if exec_action_events.is_empty() {
        return Ok(());
    }

    let mut webdriver = Command::new("../geckodriver").spawn()?;

    let mut caps = DesiredCapabilities::firefox();
    if mode == Mode::Headless {
        caps.set_headless().unwrap_or(());
    }

    let mut tasks = vec![];
    for exec_action_event in exec_action_events {
        let caps = caps.clone();
        let client = client.clone();

        tasks.push(tokio::spawn(async move {
            info!("processing: {:#?}", exec_action_event);

            let (Some(username), Some(password)) =
                (&exec_action_event.username, &exec_action_event.password)
            else {
                warn!("can not log in: no credential provided");

                return Err(Error::NoCredential(exec_action_event.action_event_id));
            };

            let driver = WebDriver::new("http://localhost:4444/", caps).await?;

            let result = try_get_wod(
                &driver,
                &client,
                username,
                password,
                &exec_action_event,
                mode,
            )
            .await;

            info!("closing browser");
            driver.quit().await?;

            result
        }));
    }

    let mut delete_action_event_ids = vec![];
    for task in tasks {
        match task.await {
            Ok(result) => match result {
                Ok(action_event_id) => delete_action_event_ids.push(action_event_id),
                Err(
                    Error::NoCredential(action_event_id)
                    | Error::LoginFailed(action_event_id)
                    | Error::WodNotFound(action_event_id),
                ) => {
                    delete_action_event_ids.push(action_event_id);
                }
                Err(error) => error!("{}", error),
            },
            Err(join_error) => error!("execution of action event failed: {}", join_error),
        }
    }

    info!("deleting {} action events", delete_action_event_ids.len());
    debug!("delete event ids: {:?}", delete_action_event_ids);

    if !delete_action_event_ids.is_empty() {
        disable_events(
            &client,
            &CONFIG.base_url,
            NAME,
            &CONFIG.password,
            &delete_action_event_ids,
        )
        .await?;
    }

    info!("terminating webdriver");
    let _ = webdriver.kill().await;

    Ok(())
}

async fn try_get_wod(
    driver: &WebDriver,
    client: &Client,
    username: &str,
    password: &str,
    exec_action_event: &ExecutableActionEvent,
    mode: Mode,
) -> Result<ActionEventId> {
    driver.delete_all_cookies().await?;
    driver
        .goto("https://app.wodify.com/WOD/WODEntry.aspx")
        .await?;

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
    time::sleep(StdDuration::from_secs(2)).await;

    if driver
        .find(By::Id("AthleteTheme_wtLayoutNormal_block_wt9_wtLogoutLink"))
        .await
        .is_err()
    {
        warn!("login failed");
        return Err(Error::LoginFailed(exec_action_event.action_event_id));
    }
    debug!("login successful");

    // select wod type
    //let type_picker = driver
    //.find(By::Id(
    //"AthleteTheme_wtLayoutNormal_block_wtSubNavigation_wtcbDate",
    //))
    //.await?;
    //type_picker.click().await?;
    //type_picker.send_keys(exec_action_event.action_name).await?; // TODO does not work
    //time::sleep(StdDuration::from_secs(2)).await;

    if let Ok(wod) = driver
        .find(By::Id(
            "AthleteTheme_wtLayoutNormal_block_wtMainContent_WOD_UI_wt9_block_wtWODComponentsList",
        ))
        .await
    {
        let elements = wod
            .find_all(By::ClassName("component_show_wrapper"))
            .await?;

        let mut description = String::new();
        for element in elements {
            let name = element
                .find(By::ClassName("component_name"))
                .await?
                .inner_html()
                .await?
                .replace("<br>", "\n")
                .replace("&nbsp;", " ");
            description += name.as_str();
            description += "\n";

            let content = element
                .find(By::ClassName("component_wrapper"))
                .await?
                .inner_html()
                .await?
                .replace("<br>", "\n")
                .replace("&nbsp;", " ");
            description += content.as_str();
            description += "\n";
        }

        let wod = Wod {
            id: WodId(rand::thread_rng().gen()),
            user_id: exec_action_event.user_id,
            date: Utc::now().date_naive(),
            description: Some(description.clone()),
            deleted: false,
        };

        let response = client
            .post(route_max_version(&CONFIG.base_url, WOD, None))
            .basic_auth(NAME, Some(&CONFIG.password))
            .header(ID_HEADER, exec_action_event.user_id.0)
            .json(&wod)
            .send()
            .await?;
        match response.status() {
            StatusCode::CONFLICT => {
                let today = Local::now().date_naive().format("%Y-%m-%d").to_string();
                let wods: Vec<Wod> = client
                    .get(route_max_version(
                        &CONFIG.base_url,
                        WOD,
                        Some(&[("start", &today), ("end", &today)]),
                    ))
                    .basic_auth(NAME, Some(&CONFIG.password))
                    .header(ID_HEADER, exec_action_event.user_id.0)
                    .send()
                    .await?
                    .json()
                    .await?;
                let mut wod = wods
                    .into_iter()
                    .next()
                    .expect("server returned multiple wods for the same date");
                if let Some(old_description) = wod.description {
                    wod.description = Some(old_description + description.as_str());
                } else {
                    wod.description = Some(description);
                }
                client
                    .put(route_max_version(&CONFIG.base_url, WOD, None))
                    .basic_auth(NAME, Some(&CONFIG.password))
                    .header(ID_HEADER, exec_action_event.user_id.0)
                    .json(&wod)
                    .send()
                    .await?;
            }
            StatusCode::OK => {
                info!("new wod created");
            }
            _ => {
                response.error_for_status()?; // this will always fail and return the error
            }
        }

        if mode == Mode::Interactive {
            time::sleep(StdDuration::from_secs(2)).await;
        }

        Ok(exec_action_event.action_event_id)
    } else {
        Err(Error::WodNotFound(exec_action_event.action_event_id))
    }
}
