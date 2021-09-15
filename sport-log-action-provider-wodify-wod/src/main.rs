use std::{
    env, fs, io::Error as IoError, process, result::Result as StdResult,
    time::Duration as StdDuration,
};

use chrono::{Duration, Local, Utc};
use err_derive::Error as StdError;
use lazy_static::lazy_static;
use rand::Rng;
use reqwest::{Client, Error as ReqwestError, StatusCode};
use serde::Deserialize;
use thirtyfour::{
    error::WebDriverError, http::reqwest_async::ReqwestDriverAsync, prelude::*, GenericWebDriver,
};
use tokio::{process::Command, time};
use tracing::{debug, error, info, warn};

use sport_log_ap_utils::{delete_events, get_events, setup as setup_db};
use sport_log_types::{ActionEventId, ExecutableActionEvent, Wod, WodId};

const CONFIG_FILE: &str = "config.toml";
const NAME: &str = "wodify-wod";
const DESCRIPTION: &str =
    "Wodify Wod can fetch the Workout of the Day and save it in your wods. The action names correspond to the class type the wod should be fetched for.";
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
    #[error(display = "the wod could not be found")]
    WodNotFound(ActionEventId),
}

type Result<T> = StdResult<T, Error>;

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
                error!("Failed to parse config.toml: {}", error);
                process::exit(1);
            }
        },
        Err(error) => {
            error!("Failed to read config.toml: {}", error);
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
            "info,sport_log_action_provider_wodify_wod=debug",
        );
    } else {
        env::set_var("RUST_LOG", "warn");
    }

    tracing_subscriber::fmt::init();

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
        [option] if option == "--setup" => {
            if let Err(error) = setup().await {
                error!("login failed: {}", error);
            }
        }
        [option] if ["help", "-h", "--help"].contains(&option.as_str()) => help(),
        _ => wrong_use(),
    }
}

async fn setup() -> Result<()> {
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
    .map_err(Error::Reqwest)
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
    .await
    .map_err(Error::Reqwest)?;

    info!("got {} executable action events", exec_action_events.len());

    if exec_action_events.is_empty() {
        return Ok(());
    }

    let mut webdriver = Command::new("../geckodriver").spawn().map_err(Error::Io)?;

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

            match (&exec_action_event.username, &exec_action_event.password) {
                (Some(username), Some(password)) => {
                    let driver = WebDriver::new_with_timeout(
                        "http://localhost:4444/",
                        &caps,
                        Some(StdDuration::from_secs(5)),
                    )
                    .await
                    .map_err(Error::WebDriver)?;

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
                    driver.quit().await.map_err(Error::WebDriver)?;

                    result
                }
                _ => {
                    warn!("can not log in: no credential provided");

                    Err(Error::NoCredential(exec_action_event.action_event_id))
                }
            }
        }));
    }

    let mut delete_action_event_ids = vec![];
    for task in tasks {
        match task.await.unwrap() {
            Ok(action_event_id) => delete_action_event_ids.push(action_event_id),
            Err(Error::NoCredential(action_event_id)) => {
                delete_action_event_ids.push(action_event_id)
            }
            Err(Error::LoginFailed(action_event_id)) => {
                delete_action_event_ids.push(action_event_id)
            }
            Err(Error::WodNotFound(action_event_id)) => {
                delete_action_event_ids.push(action_event_id)
            }
            Err(error) => error!("{}", error),
        }
    }

    info!("deleting {} action events", delete_action_event_ids.len());
    debug!("delete event ids: {:?}", delete_action_event_ids);

    if !delete_action_event_ids.is_empty() {
        delete_events(
            &client,
            &CONFIG.base_url,
            NAME,
            &CONFIG.password,
            &delete_action_event_ids,
        )
        .await
        .map_err(Error::Reqwest)?;
    }

    info!("terminating webdriver");
    let _ = webdriver.kill();

    Ok(())
}

async fn try_get_wod(
    driver: &GenericWebDriver<ReqwestDriverAsync>,
    client: &Client,
    username: &str,
    password: &str,
    exec_action_event: &ExecutableActionEvent,
    mode: Mode,
) -> Result<ActionEventId> {
    driver
        .delete_all_cookies()
        .await
        .map_err(Error::WebDriver)?;
    driver
        .get("https://app.wodify.com/WOD/WODEntry.aspx")
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
        .find_element(By::Id("AthleteTheme_wtLayoutNormal_block_wt9_wtLogoutLink"))
        .await
        .is_err()
    {
        warn!("login failed");
        return Err(Error::LoginFailed(exec_action_event.action_event_id));
    }
    debug!("login successful");

    // select wod type
    //let type_picker = driver
    //.find_element(By::Id(
    //"AthleteTheme_wtLayoutNormal_block_wtSubNavigation_wtcbDate",
    //))
    //.await?;
    //type_picker.click().await?;
    //type_picker.send_keys(exec_action_event.action_name).await?; // TODO does not work
    //time::sleep(StdDuration::from_secs(2)).await;

    if let Ok(wod) = driver
        .find_element(By::Id(
            "AthleteTheme_wtLayoutNormal_block_wtMainContent_WOD_UI_wt9_block_wtWODComponentsList",
        ))
        .await
    {
        let elements = wod
            .find_elements(By::ClassName("component_show_wrapper"))
            .await
            .map_err(Error::WebDriver)?;

        let mut description = "".to_owned();
        for element in elements {
            let name = element
                .find_element(By::ClassName("component_name"))
                .await
                .map_err(Error::WebDriver)?
                .inner_html()
                .await
                .map_err(Error::WebDriver)?
                .replace("<br>", "\n")
                .replace("&nbsp;", " ");
            description += &name;
            description += "\n";

            let content = element
                .find_element(By::ClassName("component_wrapper"))
                .await
                .map_err(Error::WebDriver)?
                .inner_html()
                .await
                .map_err(Error::WebDriver)?
                .replace("<br>", "\n")
                .replace("&nbsp;", " ");
            description += &content;
            description += "\n";
        }

        let wod = Wod {
            id: WodId(rand::thread_rng().gen()),
            user_id: exec_action_event.user_id,
            date: Local::today().naive_local(),
            description: Some(description.clone()),
            last_change: Utc::now(),
            deleted: false,
        };

        let response = client
            .post(format!("{}/v1/wod", CONFIG.base_url,))
            .basic_auth(
                format!("{}$id${}", NAME, exec_action_event.user_id.0),
                Some(&CONFIG.password),
            )
            .json(&wod)
            .send()
            .await
            .map_err(Error::Reqwest)?;
        match response.status() {
            StatusCode::CONFLICT => {
                let today = Local::today().naive_local().format("%Y-%m-%d");
                let wods: Vec<Wod> = client
                    .get(format!(
                        "{}/v1/wod/timespan/{}/{}",
                        CONFIG.base_url, today, today
                    ))
                    .basic_auth(
                        format!("{}$id${}", NAME, exec_action_event.user_id.0),
                        Some(&CONFIG.password),
                    )
                    .send()
                    .await
                    .map_err(Error::Reqwest)?
                    .json()
                    .await
                    .map_err(Error::Reqwest)?;
                let mut wod = wods
                    .into_iter()
                    .next()
                    .expect("server returned multiple wods for the same date");
                if let Some(old_description) = wod.description {
                    wod.description = Some(old_description + &description);
                } else {
                    wod.description = Some(description);
                }
                client
                    .put(format!("{}/v1/wod", CONFIG.base_url,))
                    .basic_auth(
                        format!("{}$id${}", NAME, exec_action_event.user_id.0),
                        Some(&CONFIG.password),
                    )
                    .json(&wod)
                    .send()
                    .await
                    .map_err(Error::Reqwest)?;
            }
            StatusCode::OK => {
                info!("new wod created");
            }
            _ => {
                response.json::<Wod>().await.map_err(Error::Reqwest)?; // this will always fail and return the error
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
