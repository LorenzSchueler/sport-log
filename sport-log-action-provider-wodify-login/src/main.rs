use std::{
    env, fs, io::Error as IoError, process, result::Result as StdResult,
    time::Duration as StdDuration,
};

use chrono::{Duration, Local, Utc};
use err_derive::Error as StdError;
use lazy_static::lazy_static;
use reqwest::{Client, Error as ReqwestError};
use serde::Deserialize;
use thirtyfour::{error::WebDriverError, prelude::*};
use tracing::{debug, error, info, warn};

use sport_log_ap_utils::{delete_events, get_events, setup as setup_db};
use tokio::{process::Command, time};

const CONFIG_FILE: &str = "config.toml";
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
}

type Result<T> = StdResult<T, Error>;

#[derive(Deserialize)]
struct Config {
    password: String,
    base_url: String,
}

lazy_static! {
    static ref CONFIG: Config = match fs::read_to_string(CONFIG_FILE) {
        Ok(file) => match toml::from_str(&file) {
            Ok(config) => config,
            Err(error) => {
                error!("Failed to parse config.toml.: {}", error);
                process::exit(1);
            }
        },
        Err(error) => {
            error!("Failed to read config.toml.: {}", error);
            process::exit(1);
        }
    };
}

#[tokio::main]
async fn main() {
    if cfg!(debug_assertions) {
        env::set_var(
            "RUST_LOG",
            "info,sport_log_action_provider_wodify_login=debug",
        );
    } else {
        env::set_var("RUST_LOG", "warn");
    }

    tracing_subscriber::fmt::init();

    match &env::args().collect::<Vec<_>>()[1..] {
        [] => {
            if let Err(error) = login().await {
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
        &CONFIG.base_url,
        NAME,
        &CONFIG.password,
        DESCRIPTION,
        PLATFORM_NAME,
        true,
        &[
            ("CrossFit", "Reserve a spot in a CrossFit class."),
            ("Weightlifting", "Reserve a spot in a Weightlifting class."),
            ("Open Fridge", "Reserve a spot in a Open Fridge class."),
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
        --setup\t\tcreate own actions"
    );
}

fn wrong_use() {
    println!("no such options");
}

async fn login() -> Result<()> {
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

    let caps = DesiredCapabilities::firefox();
    let driver = WebDriver::new_with_timeout(
        "http://localhost:4444/",
        &caps,
        Some(StdDuration::from_secs(5)),
    )
    .await
    .map_err(Error::WebDriver)?;

    let mut delete_action_event_ids = vec![];
    // TODO execute in parallel
    for exec_action_event in exec_action_events {
        info!("processing {:#?}", exec_action_event);

        let (username, password) = if let (Some(username), Some(password)) =
            (exec_action_event.username, exec_action_event.password)
        {
            (username, password)
        } else {
            warn!("can not log in: no credential provided");
            continue;
        };

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
            .send_keys(&username)
            .await
            .map_err(Error::WebDriver)?;
        driver
            .find_element(By::Id("Input_Password"))
            .await
            .map_err(Error::WebDriver)?
            .send_keys(&password)
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
            warn!("login failed");
            continue;
        }
        info!("login successful");

        if let Ok(duration) = (exec_action_event.datetime - Duration::days(1) - Utc::now()).to_std()
        {
            time::sleep(duration).await;
        }
        debug!("ready");

        'event_loop: while Utc::now() < exec_action_event.datetime
        // - Duration::days(1) + Duration::minutes(1) // TODO
        {
            driver.refresh().await.map_err(Error::WebDriver)?; // TODO can this be removed?

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
                    let title = label
                        .get_attribute("title")
                        .await
                        .map_err(Error::WebDriver)?
                        .unwrap();
                    if title.contains(&exec_action_event.action_name) && title.contains(&time) {
                        row.find_element(By::XPath("./td[3]/div"))
                            .await
                            .map_err(Error::WebDriver)?
                            .click()
                            .await
                            .map_err(Error::WebDriver)?;
                        info!("reserved");
                        time::sleep(StdDuration::from_secs(2)).await; // TODO remove

                        delete_action_event_ids.push(exec_action_event.action_event_id);
                        break 'event_loop;
                    }
                }
            }
        }
    }

    info!("deleting {} action event", delete_action_event_ids.len());
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

    info!("closing browser");
    driver.quit().await.map_err(Error::WebDriver)?;

    info!("terminating webdriver");
    let _ = webdriver.kill();

    Ok(())
}
