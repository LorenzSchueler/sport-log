use std::{
    env, fs, io::Error as IoError, result::Result as StdResult, time::Duration as StdDuration,
};

use chrono::{Duration, Local, Utc};
use err_derive::Error as StdError;
use rand::Rng;
use reqwest::{Client, Error as ReqwestError, StatusCode};
use serde::Deserialize;
use thirtyfour::{error::WebDriverError, prelude::*};
use tokio::{process::Command, time};
use toml::de::Error as TomlError;

use sport_log_ap_utils::{delete_events, get_events, setup as setup_db};
use sport_log_types::{Wod, WodId};

const NAME: &str = "wodify-wod";
const DESCRIPTION: &str =
    "Wodify Wod can fetch the Workout of the Day and save it in your wods. The action names correspond to the class type the wod should be fetched for.";
const PLATFORM_NAME: &str = "wodify";

#[derive(Debug, StdError)]
enum Error {
    #[error(display = "{}", _0)]
    ReqwestError(ReqwestError),
    #[error(display = "{}", _0)]
    IoError(IoError),
    #[error(display = "{}", _0)]
    TomlError(TomlError),
    #[error(display = "{}", _0)]
    WebDriverError(WebDriverError),
}

type Result<T> = StdResult<T, Error>;

#[derive(Deserialize)]
struct Config {
    password: String,
    base_url: String,
}

impl Config {
    fn get() -> Result<Self> {
        Ok(
            toml::from_str(&fs::read_to_string("config.toml").map_err(Error::IoError)?)
                .map_err(Error::TomlError)?,
        )
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    match &env::args().collect::<Vec<_>>()[1..] {
        [] => login().await,
        [option] if option == "--setup" => setup().await,
        [option] if ["help", "-h", "--help"].contains(&option.as_str()) => Ok(help()),
        _ => Ok(wrong_use()),
    }
}

async fn setup() -> Result<()> {
    let config = Config::get()?;

    setup_db(
        &config.base_url,
        NAME,
        &config.password,
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
    .map_err(Error::ReqwestError)
}

fn help() {
    println!(
        "Wodify Wod Action Provider\n\n\

        USAGE:\n\
        sport-log-action-provider-wodify-wod [OPTIONS]\n\n\

        OPTIONS:\n\
        -h, --help\tprint this help page\n\
        --setup\t\tcreate own actions"
    );
}

fn wrong_use() {
    println!("no such options");
}

async fn login() -> Result<()> {
    let config = Config::get()?;

    let client = Client::new();

    let exec_action_events = get_events(
        &client,
        &config.base_url,
        NAME,
        &config.password,
        Duration::hours(0),
        Duration::days(1) + Duration::minutes(1),
    )
    .await
    .map_err(Error::ReqwestError)?;
    println!("executable action events: {}\n", exec_action_events.len());

    if exec_action_events.is_empty() {
        return Ok(());
    }

    let mut rng = rand::thread_rng();

    let mut webdriver = Command::new("../geckodriver")
        .spawn()
        .map_err(Error::IoError)?;

    let caps = DesiredCapabilities::firefox();
    let driver = WebDriver::new_with_timeout(
        "http://localhost:4444/",
        &caps,
        Some(StdDuration::from_secs(5)),
    )
    .await
    .map_err(Error::WebDriverError)?;

    let mut delete_action_event_ids = vec![];
    // TODO execute in parallel
    for exec_action_event in exec_action_events {
        println!("{:#?}", exec_action_event);

        let (username, password) = if let (Some(username), Some(password)) =
            (exec_action_event.username, exec_action_event.password)
        {
            (username, password)
        } else {
            println!("not credential provided");
            continue;
        };

        let time = exec_action_event.datetime.format("%-H:%M").to_string();
        let date = exec_action_event.datetime.format("%m/%d/%Y").to_string();
        println!("time: {}", time);
        println!("date: {}", date);
        println!("name: {}", exec_action_event.action_name);

        driver
            .delete_all_cookies()
            .await
            .map_err(Error::WebDriverError)?;
        driver
            .get("https://app.wodify.com/WOD/WODEntry.aspx")
            .await
            .map_err(Error::WebDriverError)?;

        time::sleep(StdDuration::from_secs(3)).await;

        driver
            .find_element(By::Id("Input_UserName"))
            .await
            .map_err(Error::WebDriverError)?
            .send_keys(&username)
            .await
            .map_err(Error::WebDriverError)?;
        driver
            .find_element(By::Id("Input_Password"))
            .await
            .map_err(Error::WebDriverError)?
            .send_keys(&password)
            .await
            .map_err(Error::WebDriverError)?;
        driver
            .find_element(By::ClassName("signin-btn"))
            .await
            .map_err(Error::WebDriverError)?
            .click()
            .await
            .map_err(Error::WebDriverError)?;
        time::sleep(StdDuration::from_secs(2)).await;

        if driver
            .find_element(By::Id("AthleteTheme_wtLayoutNormal_block_wt9_wtLogoutLink"))
            .await
            .is_err()
        {
            println!("login failed");
            continue;
        }
        println!("login successful");

        // select wod type
        //let type_picker = driver
        //.find_element(By::Id(
        //"AthleteTheme_wtLayoutNormal_block_wtSubNavigation_wtcbDate",
        //))
        //.await?;
        //type_picker.click().await?;
        //type_picker.send_keys(exec_action_event.action_name).await?; // TODO does not work
        //time::sleep(StdDuration::from_secs(2)).await;

        if let Ok(wod) = driver.find_element(By::Id(
            "AthleteTheme_wtLayoutNormal_block_wtMainContent_WOD_UI_wt9_block_wtWODComponentsList",
        )).await {

        let elements = wod
            .find_elements(By::ClassName("component_show_wrapper"))
            .await
            .map_err(Error::WebDriverError)?;

        let mut description = "".to_owned();
        for element in elements {
            let name = element
                .find_element(By::ClassName("component_name"))
                .await
                .map_err(Error::WebDriverError)?
                .inner_html()
                .await
                .map_err(Error::WebDriverError)?
                .replace("<br>", "\n")
                .replace("&nbsp;", " ");
                description += &name;
                description += "\n";

            let content = element
                .find_element(By::ClassName("component_wrapper"))
                .await
                .map_err(Error::WebDriverError)?
                .inner_html()
                .await
                .map_err(Error::WebDriverError)?
                .replace("<br>", "\n")
                .replace("&nbsp;", " ");
                description += &content;
                description += "\n";
        }
        println!("{}", description);
        let wod = Wod {
            id: WodId(rng.gen()),
            user_id: exec_action_event.user_id,
            date: Local::today().naive_local(),
            description: Some(description.clone()),
            last_change: Utc::now(),
            deleted: false,
        };

        if client
            .post(format!("{}/v1/wod", config.base_url,))
            .basic_auth(format!("{}$id${}", NAME , exec_action_event.user_id.0), Some(&config.password))
            .json(&wod)
            .send()
            .await
            .map_err(Error::ReqwestError)?
            .status() == StatusCode::CONFLICT
        {
            let today = Local::today().naive_local().format("%Y-%m-%d");
            let wods: Vec<Wod> = client
                .get(format!("{}/v1/wod/timespan/{}/{}", config.base_url, today, today))
                .basic_auth(format!("{}$id${}", NAME , exec_action_event.user_id.0), Some(&config.password))
                .send()
                .await
                .map_err(Error::ReqwestError)?
                .json()
                .await
                .map_err(Error::ReqwestError)?;
            let mut wod = wods
                .into_iter()
                .next()
                .expect("server returned multiple wods for the same date");
            if let Some(old_description) = wod.description {
                wod.description = Some(old_description + &description) ;
            } else {
                wod.description = Some(description);
            }
            client
                .put(format!("{}/v1/wod", config.base_url,))
                .basic_auth(format!("{}$id${}", NAME , exec_action_event.user_id.0), Some(&config.password))
                .json(&wod)
                .send()
                .await
                .map_err(Error::ReqwestError)?;
            }
        } else {
            println!("not wod found");
        }
        delete_action_event_ids.push(exec_action_event.action_event_id);
    }

    println!("delete event ids: {:?}", delete_action_event_ids);
    if !delete_action_event_ids.is_empty() {
        delete_events(
            &client,
            &config.base_url,
            NAME,
            &config.password,
            &delete_action_event_ids,
        )
        .await
        .map_err(Error::ReqwestError)?;
    }

    println!("closing browser");
    driver.quit().await.map_err(Error::WebDriverError)?;

    println!("terminating webdriver");
    let _ = webdriver.kill();

    Ok(())
}
