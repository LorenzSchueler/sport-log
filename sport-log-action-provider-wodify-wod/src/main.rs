use std::{env, fs, process::Command, thread, time::Duration as StdDuration};

use chrono::{Duration, Local};
use reqwest::{Client, StatusCode};
use serde::Deserialize;
use thirtyfour::prelude::*;
use tokio;

use sport_log_ap_utils::{delete_events, get_events, setup};
use sport_log_types::{
    ActionProviderId, NewAction, NewActionProvider, NewPlatform, NewWod, PlatformId, Wod,
};

const NAME: &str = "wodify-wod";
const DESCRIPTION: &str =
    "Wodify Wod can fetch the Workout of the Day and save it in your wods. The action names correspond to the class type the wod should be fetched for.";
const PLATFORM_NAME: &str = "wodify";

#[derive(Deserialize)]
struct Config {
    password: String,
    base_url: String,
}

impl Config {
    fn get() -> Self {
        toml::from_str(&fs::read_to_string("config.toml").unwrap()).unwrap()
    }
}

#[tokio::main]
async fn main() {
    match &env::args().collect::<Vec<_>>()[1..] {
        [] => login().await.unwrap(),
        [option] if option == "--setup" => {
            let config = Config::get();

            let platform = NewPlatform {
                name: PLATFORM_NAME.to_owned(),
            };

            let action_provider = NewActionProvider {
                name: NAME.to_owned(),
                password: config.password.clone(),
                platform_id: PlatformId(0), // TODO use generated id from platform
                description: Some(DESCRIPTION.to_owned()),
            };

            let actions = vec![
                NewAction {
                    name: "CrossFit".to_owned(),
                    action_provider_id: ActionProviderId(0), // TODO use generated id from action provider
                    description: Some(
                        "Fetch and save the CrossFit wod for the current day.".to_owned(),
                    ),
                    create_before: 168,
                    delete_after: 0,
                },
                NewAction {
                    name: "Weightlifting".to_owned(),
                    action_provider_id: ActionProviderId(0), // TODO use generated id from action provider
                    description: Some(
                        "Fetch and save the Weightlifting wod for the current day.".to_owned(),
                    ),
                    create_before: 168,
                    delete_after: 0,
                },
                NewAction {
                    name: "Open Fridge".to_owned(),
                    action_provider_id: ActionProviderId(0), // TODO use generated id from action provider
                    description: Some(
                        "Fetch and save the Open Fridge wod for the current day.".to_owned(),
                    ),
                    create_before: 168,
                    delete_after: 0,
                },
            ];

            setup(
                &config.base_url,
                NAME,
                &config.password,
                PLATFORM_NAME,
                platform,
                action_provider,
                actions,
            )
            .await;
        }
        [option] if ["help", "-h", "--help"].contains(&option.as_str()) => help(),
        _ => wrong_use(),
    }
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

async fn login() -> WebDriverResult<()> {
    let config = Config::get();

    let client = Client::new();

    let exec_action_events = get_events(
        &client,
        &config.base_url,
        NAME,
        &config.password,
        Duration::hours(0),
        Duration::days(1) + Duration::minutes(1),
    )
    .await;
    println!("executable action events: {}\n", exec_action_events.len());

    if exec_action_events.is_empty() {
        return Ok(());
    }

    let mut webdriver = Command::new("../geckodriver").spawn().unwrap();

    let caps = DesiredCapabilities::firefox();
    let driver = WebDriver::new_with_timeout(
        "http://localhost:4444/",
        &caps,
        Some(StdDuration::from_secs(5)),
    )
    .await?;

    let mut delete_action_event_ids = vec![];
    // TODO execute in parallel
    for exec_action_event in exec_action_events {
        println!("{:#?}", exec_action_event);

        let time = exec_action_event.datetime.format("%-H:%M").to_string();
        let date = exec_action_event.datetime.format("%m/%d/%Y").to_string();
        println!("time: {}", time);
        println!("date: {}", date);
        println!("name: {}", exec_action_event.action_name);

        driver.delete_all_cookies().await?;
        driver
            .get("https://app.wodify.com/WOD/WODEntry.aspx")
            .await?;

        thread::sleep(StdDuration::from_secs(3));

        driver
            .find_element(By::Id("Input_UserName"))
            .await?
            .send_keys(&exec_action_event.username)
            .await?;
        driver
            .find_element(By::Id("Input_Password"))
            .await?
            .send_keys(&exec_action_event.password)
            .await?;
        driver
            .find_element(By::ClassName("signin-btn"))
            .await?
            .click()
            .await?;
        thread::sleep(StdDuration::from_secs(2));

        if let Err(_) = driver
            .find_element(By::Id("AthleteTheme_wtLayoutNormal_block_wt9_wtLogoutLink"))
            .await
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
        //thread::sleep(StdDuration::from_secs(3));

        if let Ok(wod) = driver.find_element(By::Id(
            "AthleteTheme_wtLayoutNormal_block_wtMainContent_WOD_UI_wt9_block_wtWODComponentsList",
        )).await {

        let elements = wod
            .find_elements(By::ClassName("component_show_wrapper"))
            .await?;

            let mut description = "".to_owned();
        for element in elements {
            let name = element
                .find_element(By::ClassName("component_name"))
                .await?
                .inner_html()
                .await?
                .replace("<br>", "\n")
                .replace("&nbsp;", " ");
                description += &name;
                description += "\n";

            let content = element
                .find_element(By::ClassName("component_wrapper"))
                .await?
                .inner_html()
                .await?
                .replace("<br>", "\n")
                .replace("&nbsp;", " ");
                description += &content;
                description += "\n";
        }
        println!("{}", description);
        // insert into db
        let wod = NewWod {
            user_id: exec_action_event.user_id,
            date: Local::today().naive_local(),
            description: Some(description.clone())
        };
        // TODO append
        if client
            .post(format!("{}/v1/wod", config.base_url,))
            .basic_auth(format!("{}$id${}", NAME , exec_action_event.user_id.0), Some(&config.password))
            .json(&wod )
            .send()
            .await
            .unwrap().status() == StatusCode::CONFLICT {

                let today = Local::today().naive_local().format("%Y-%m-%d");
                let wods: Vec<Wod> = client
            .get(format!("{}/v1/wod/timespan/{}/{}", config.base_url,today, today))
            .basic_auth(format!("{}$id${}", NAME , exec_action_event.user_id.0), Some(&config.password))
            .send()
            .await
            .unwrap()
            .json().await.unwrap();
            let mut wod = wods.into_iter().next().unwrap();
            if let Some(old_description) = wod.description {

            wod.description = Some(old_description + &description) ;
            } else {
                wod.description = Some(description);
            }
                client
            .put(format!("{}/v1/wod", config.base_url,))
            .basic_auth(format!("{}$id${}", NAME , exec_action_event.user_id.0), Some(&config.password))
            .json(&wod )
            .send()
            .await
            .unwrap();}
        } else {
            println!("not wod found");
        }
        //delete_action_event_ids.push(exec_action_event.action_event_id);
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
        .await;
    }

    println!("closing browser");
    driver.quit().await?;

    println!("terminating webdriver");
    let _ = webdriver.kill();

    Ok(())
}
