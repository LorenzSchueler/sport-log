//! **Sport Log Scheduler** is responsible for scheduling [ActionEvents](ActionEvent).
//!
//! **Sport Log Scheduler** creates [ActionEvents](sport_log_types::ActionEvent) from [ActionRules](sport_log_types::ActionRule)
//! and deletes old [ActionEvents](sport_log_types::ActionEvent).
//!
//! [ActionEvents](sport_log_types::ActionEvent) are only created from enabled [ActionRules](sport_log_types::ActionRule).
//!
//! The timespan they are created before their `datetime` is determined by the `create_before` field of the corresponding [Action](sport_log_types::Action).
//!
//! Similarly the timespan they are deleted after their `datetime` is determined by the `delete_after` field of the corresponding [Action](sport_log_types::Action).
//!
//! However most [ActionProvider](sport_log_types::ActionProvider) will delete a [ActionEvents](sport_log_types::ActionEvent) directly after execution.
//!
//! # Usage
//!
//! The **Sport Log Scheduler** has do be executed periodically, perferably as a cron job every hour.
//!
//! # Config
//!
//! The config file must be called `sport-log-scheduler.toml` and must be deserializable to a [Config].

use std::{env, fs};

use chrono::{Datelike, Duration, Utc};
use rand::Rng;
use reqwest::{blocking::Client, Error as ReqwestError};
use serde::Deserialize;
use tracing::{debug, error, info};

use sport_log_types::{
    ActionEvent, ActionEventId, CreatableActionRule, DeletableActionEvent, ADMIN_USERNAME,
};

pub const CONFIG_FILE: &str = "sport-log-scheduler.toml";

/// The config for [sport-log-scheduler](crate).
///
/// The name of the config file is specified in [CONFIG_FILE].
///
/// `admin_password` is the password for the admin endpoints.
///
/// `base_url` is the left part of the URL (everthing before `/<version>/...`)
///
/// `garbage_collection_min_days` is the number of days for which an entry has to been deleted and not changed in order to get hard deleted.
/// If set to `0` garbage collection is disabled.
#[derive(Deserialize)]
pub struct Config {
    pub admin_password: String,
    pub base_url: String,
    pub garbage_collection_min_days: u32,
}

fn main() {
    if cfg!(debug_assertions) {
        env::set_var("RUST_LOG", "info,sport_log_scheduler=debug");
    } else {
        env::set_var("RUST_LOG", "warn");
    }

    tracing_subscriber::fmt::init();

    let config: Config = match fs::read_to_string(CONFIG_FILE) {
        Ok(file) => match toml::from_str(&file) {
            Ok(config) => config,
            Err(error) => {
                error!("Failed to parse {}: {}", CONFIG_FILE, error);
                return;
            }
        },
        Err(error) => {
            error!("Failed to read {}: {}", CONFIG_FILE, error);
            return;
        }
    };

    let client = Client::new();
    if let Err(error) = create_action_events(&client, &config) {
        error!(
            "while creating new action events an error occured: {}",
            error
        );
    }
    if let Err(error) = delete_action_events(&client, &config) {
        error!(
            "while deleting old action events an error occured: {}",
            error
        );
    }

    if let Err(error) = garbage_collection(&client, &config) {
        error!(
            "while running garbage collection an error occured: {}",
            error
        );
    }
}

fn create_action_events(client: &Client, config: &Config) -> Result<(), ReqwestError> {
    let creatable_action_rules: Vec<CreatableActionRule> = client
        .get(format!(
            "{}/v0.2/adm/creatable_action_rule",
            config.base_url
        ))
        .basic_auth(ADMIN_USERNAME, Some(&config.admin_password))
        .send()?
        .error_for_status()?
        .json()?;

    info!(
        "got {} creatable action events",
        creatable_action_rules.len()
    );
    debug!("{:#?}", creatable_action_rules);

    let mut rng = rand::thread_rng();

    let mut action_events = vec![];
    for creatable_action_rule in creatable_action_rules {
        let datetime = Utc::today()
            .checked_add_signed(Duration::days(
                (creatable_action_rule.weekday.to_u32() as i64
                    - Utc::today().weekday().num_days_from_monday() as i64)
                    .rem_euclid(7),
            ))
            .unwrap()
            .and_time(creatable_action_rule.time.time())
            .unwrap();

        for weeks in 0.. {
            let datetime = datetime + Duration::weeks(weeks);
            if Utc::now() >= datetime - Duration::hours(creatable_action_rule.create_before as i64)
            {
                action_events.push(ActionEvent {
                    id: ActionEventId(rng.gen()),
                    user_id: creatable_action_rule.user_id,
                    action_id: creatable_action_rule.action_id,
                    datetime,
                    arguments: creatable_action_rule.arguments.clone(),
                    enabled: true,
                    last_change: Utc::now(),
                    deleted: false,
                });
            } else {
                break;
            }
        }
    }

    info!("creating {} new action events", action_events.len());
    debug!("{:#?}", action_events);

    client
        .post(format!("{}/v0.2/adm/action_events", config.base_url))
        .basic_auth(ADMIN_USERNAME, Some(&config.admin_password))
        .json(&action_events)
        .send()?
        .error_for_status()?;

    info!("creation of action events successful");

    Ok(())
}

fn delete_action_events(client: &Client, config: &Config) -> Result<(), ReqwestError> {
    let deletable_action_events: Vec<DeletableActionEvent> = client
        .get(format!(
            "{}/v0.2/adm/deletable_action_event",
            config.base_url
        ))
        .basic_auth(ADMIN_USERNAME, Some(&config.admin_password))
        .send()?
        .error_for_status()?
        .json()?;

    info!(
        "got {} deletable action events",
        deletable_action_events.len()
    );
    debug!("{:#?}", deletable_action_events);

    let mut action_event_ids = vec![];
    for deletable_action_event in deletable_action_events {
        if Utc::now()
            >= deletable_action_event.datetime
                + Duration::hours(deletable_action_event.delete_after as i64)
        {
            action_event_ids.push(deletable_action_event.action_event_id);
        }
    }

    info!("deleting {} action events", action_event_ids.len());
    debug!("{:#?}", action_event_ids);

    client
        .delete(format!("{}/v0.2/adm/action_events", config.base_url,))
        .basic_auth(ADMIN_USERNAME, Some(&config.admin_password))
        .json(&action_event_ids)
        .send()?
        .error_for_status()?;

    info!("action events have been successfully deleted");

    Ok(())
}

fn garbage_collection(client: &Client, config: &Config) -> Result<(), ReqwestError> {
    if config.garbage_collection_min_days > 0 {
        info!(
            "deleting if older than {} days",
            config.garbage_collection_min_days
        );

        client
            .delete(format!(
                "{}/v0.2/adm/garbage_collection/{}",
                config.base_url,
                Utc::now() - Duration::days(config.garbage_collection_min_days as i64)
            ))
            .basic_auth(ADMIN_USERNAME, Some(&config.admin_password))
            .send()?
            .error_for_status()?;

        info!("old data has been successfully deleted");
    }

    Ok(())
}
