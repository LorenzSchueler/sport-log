use std::{
    env, fs, io::Error as IoError, process, result::Result as StdResult,
    time::Duration as StdDuration,
};

use chrono::Duration;
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
use tokio::{process::Command, time};
use tracing::{debug, error, info};
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
    #[error("ExecutableActionEvent doesn't contain credentials")]
    NoCredential(ActionEventId),
    #[error("login failed")]
    LoginFailed(ActionEventId),
    #[error("the wod could not be found")]
    WodNotFound(ActionEventId),
    #[error("the result for the wod could not be found")]
    ResultNotFound(ActionEventId),
}

type Result<T> = StdResult<T, Error>;

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
        168,
        24,
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

    let mut webdriver = Command::new(GECKODRIVER).spawn()?;

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
                return Err(Error::NoCredential(exec_action_event.action_event_id));
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

    debug!(
        "deleting {} action event ({:?})",
        delete_action_event_ids.len(),
        delete_action_event_ids
    );

    if !delete_action_event_ids.is_empty() {
        disable_events(
            &client,
            &CONFIG.server_url,
            NAME,
            &CONFIG.password,
            &delete_action_event_ids,
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
) -> Result<ActionEventId> {
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
        return Err(Error::LoginFailed(exec_action_event.action_event_id));
    }
    debug!("login successful");

    driver
        .goto("https://app.wodify.com/WOD/WODEntry.aspx")
        .await?;

    let date_input = driver.find(By::Id("AthleteTheme_wtLayoutNormal_block_wtSubNavigation_W_Utils_UI_wt3_block_wtDateInputFrom")).await?;
    date_input.clear().await?;
    date_input.send_keys(&action_date_string).await?;

    time::sleep(StdDuration::from_secs(3)).await;

    let wod = driver
        .find(By::ClassName("ListRecords"))
        .await
        .map_err(|_| Error::WodNotFound(exec_action_event.action_event_id))?
        .find(By::ClassName("component_show_wrapper"))
        .await?;

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

    let result_entry = driver
        .find(By::ClassName("TableRecords"))
        .await
        .map_err(|_| Error::ResultNotFound(exec_action_event.action_event_id))?
        .find(By::Tag("tbody"))
        .await?
        .find(By::Tag("tr"))
        .await?
        .find_all(By::Tag("td"))
        .await?;

    let date = result_entry[0].inner_html().await?;
    if date != action_date_string {
        return Err(Error::ResultNotFound(exec_action_event.action_event_id));
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
            "".to_owned()
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
        time::sleep(StdDuration::from_secs(2)).await;
    }

    Ok(exec_action_event.action_event_id)
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
