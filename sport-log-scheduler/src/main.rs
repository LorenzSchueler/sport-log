//! The Sport Log Scheduler creates [ActionEvents](sport_log_types::ActionEvent) from [ActionRules](sport_log_types::ActionRule) and deletes old [ActionEvents](sport_log_types::ActionEvent).
//!
//! [ActionEvents](sport_log_types::ActionEvent) are only created from enabled [ActionRules](sport_log_types::ActionRule).
//!
//! The timespan they are created before their `datetime` is determined by the `create_before` field of the corresponding [Action](sport_log_types::Action).
//!
//! Similarly the timespan they are deleted after their `datetime` is determined by the `delete_after` field of the corresponding [Action](sport_log_types::Action).
//!
//! However most [ActionProvider](sport_log_types::ActionProvider) will delete an [ActionEvent](sport_log_types::ActionEvent) after it has been executed.
//!
//! # Usage
//!
//! The Sport Log Scheduler has do be executed periodically, perferably as a cron job every hour.
//!
//! # Config
//!
//! The config file must be called `sport-log-scheduler.toml` and must be deserializable to a [Config].

use std::fs;

use chrono::{Datelike, Duration, Utc};
use rand::Rng;
use reqwest::blocking::Client;
use serde::Deserialize;

use sport_log_types::{ActionEvent, ActionEventId, CreatableActionRule, DeletableActionEvent};

#[derive(Deserialize)]
pub struct Config {
    pub admin_password: String,
    pub base_url: String,
}

impl Config {
    pub fn get() -> Self {
        toml::from_str(&fs::read_to_string("sport-log-scheduler.toml").unwrap()).unwrap()
    }
}

fn main() {
    let config = Config::get();
    let username = "admin";

    let client = Client::new();

    let creatable_action_rules: Vec<CreatableActionRule> = client
        .get(format!("{}/v1/adm/creatable_action_rule", config.base_url))
        .basic_auth(username, Some(&config.admin_password))
        .send()
        .unwrap()
        .json()
        .unwrap();

    println!("{:#?}", creatable_action_rules);

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
                    enabled: true,
                    last_change: Utc::now(),
                    deleted: false,
                });
            } else {
                break;
            }
        }
    }

    println!("{:#?}", action_events);

    client
        .post(format!("{}/v1/adm/action_events", config.base_url))
        .basic_auth(username, Some(&config.admin_password))
        .json(&action_events)
        .send()
        .unwrap();

    let deletable_action_events: Vec<DeletableActionEvent> = client
        .get(format!("{}/v1/adm/deletable_action_event", config.base_url))
        .basic_auth(username, Some(&config.admin_password))
        .send()
        .unwrap()
        .json()
        .unwrap();

    println!("{:#?}", deletable_action_events);

    let mut action_event_ids = vec![];
    for deletable_action_event in deletable_action_events {
        if Utc::now()
            >= deletable_action_event.datetime
                + Duration::hours(deletable_action_event.delete_after as i64)
        {
            action_event_ids.push(deletable_action_event.action_event_id);
        }
    }

    println!("{:#?}", action_event_ids);

    client
        .delete(format!("{}/v1/adm/action_event", config.base_url,))
        .basic_auth(username, Some(&config.admin_password))
        .json(&action_event_ids)
        .send()
        .unwrap();
}
