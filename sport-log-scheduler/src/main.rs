//! **Sport Log Scheduler** is responsible for scheduling [`ActionEvents`](ActionEvent).
//!
//! **Sport Log Scheduler** creates [`ActionEvents`](sport_log_types::ActionEvent) from
//! [`ActionRules`](sport_log_types::ActionRule) and deletes old
//! [`ActionEvents`](sport_log_types::ActionEvent).
//!
//! [`ActionEvents`](sport_log_types::ActionEvent) are only created from enabled
//! [`ActionRules`](sport_log_types::ActionRule).
//!
//! The timespan they are created before their `datetime` is determined by the `create_before` field
//! of the corresponding [`Action`](sport_log_types::Action).
//!
//! Similarly the timespan they are deleted after their `datetime` is determined by the
//! `delete_after` field of the corresponding [`Action`](sport_log_types::Action).
//!
//! However most [`ActionProvider`](sport_log_types::ActionProvider) will delete a
//! [`ActionEvents`](sport_log_types::ActionEvent) directly after execution.
//!
//! # Usage
//!
//! The **Sport Log Scheduler** has do be executed periodically, preferably as a cron job every
//! hour.
//!
//! # Config
//!
//! The config file must be called `sport-log-scheduler.toml` and must be deserializable to a
//! [`Config`].

use std::{fs, process::ExitCode};

use chrono::{DateTime, Datelike, Days, Duration, Utc};
use rand::Rng;
use reqwest::{Error as ReqwestError, blocking::Client};
use serde::Deserialize;
use sport_log_types::{
    ADMIN_USERNAME, ActionEvent, ActionEventId, CreatableActionRule, DeletableActionEvent,
    uri::{
        ADM_ACTION_EVENT, ADM_CREATABLE_ACTION_RULE, ADM_DELETABLE_ACTION_EVENT, route_max_version,
    },
};
use tracing::{debug, error, info};
use tracing_subscriber::EnvFilter;

pub const CONFIG_FILE: &str = "sport-log-scheduler.toml";

/// The config for [`sport-log-scheduler`](crate).
///
/// The name of the config file is specified in [`CONFIG_FILE`].
///
/// `admin_password` is the password for the admin endpoints.
///
/// `server_url` is the left part of the URL (everything before `/<version>/...`)
#[derive(Deserialize)]
struct Config {
    admin_password: String,
    server_url: String,
}

fn main() -> ExitCode {
    tracing_subscriber::fmt()
        .with_writer(std::io::stderr)
        .with_env_filter(EnvFilter::try_from_default_env().unwrap_or_else(|_| {
            EnvFilter::new(if cfg!(debug_assertions) {
                "warn,sport_log_scheduler=debug"
            } else {
                "warn"
            })
        }))
        .init();

    let config_file = match fs::read_to_string(CONFIG_FILE) {
        Ok(file) => file,
        Err(error) => {
            error!("failed to read {CONFIG_FILE}: {error}");
            return ExitCode::FAILURE;
        }
    };
    let config = match toml::from_str(&config_file) {
        Ok(config) => config,
        Err(error) => {
            error!("failed to parse {CONFIG_FILE}: {error}");
            return ExitCode::FAILURE;
        }
    };

    let client = Client::new();
    if let Err(error) = create_action_events(&client, &config) {
        error!("failed to create new action events: {error}");
        return ExitCode::FAILURE;
    };
    if let Err(error) = delete_action_events(&client, &config) {
        error!("failed to delete old action events: {error}");
        return ExitCode::FAILURE;
    }

    ExitCode::SUCCESS
}

fn create_action_events(client: &Client, config: &Config) -> Result<(), ReqwestError> {
    let creatable_action_rules: Vec<CreatableActionRule> = client
        .get(route_max_version(
            &config.server_url,
            ADM_CREATABLE_ACTION_RULE,
            None,
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

    let mut rng = rand::rng();

    let mut action_events = vec![];
    for creatable_action_rule in creatable_action_rules {
        for datetime in datetimes_for_rule(&creatable_action_rule) {
            action_events.push(ActionEvent {
                id: ActionEventId(rng.random()),
                user_id: creatable_action_rule.user_id,
                action_id: creatable_action_rule.action_id,
                datetime,
                arguments: creatable_action_rule.arguments.clone(),
                enabled: true,
                deleted: false,
            });
        }
    }

    info!("creating {} new action events", action_events.len());
    debug!("{action_events:#?}");

    client
        .post(route_max_version(
            &config.server_url,
            ADM_ACTION_EVENT,
            None,
        ))
        .basic_auth(ADMIN_USERNAME, Some(&config.admin_password))
        .json(&action_events)
        .send()?
        .error_for_status()?;

    info!("creation of action events successful");

    Ok(())
}

fn datetimes_for_rule(creatable_action_rule: &CreatableActionRule) -> Vec<DateTime<Utc>> {
    datetimes_for_rule_from_start(creatable_action_rule, Utc::now())
}

fn datetimes_for_rule_from_start(
    creatable_action_rule: &CreatableActionRule,
    mut start: DateTime<Utc>,
) -> Vec<DateTime<Utc>> {
    if start.time() > creatable_action_rule.time.time() {
        start += Duration::try_days(1).unwrap();
    }
    let first_datetime = DateTime::from_naive_utc_and_offset(
        start
            .date_naive()
            .and_time(creatable_action_rule.time.time())
            + Days::new(
                (creatable_action_rule.weekday.to_u32() as i64
                    - start.weekday().num_days_from_monday() as i64)
                    .rem_euclid(7) as u64,
            ),
        Utc,
    );

    let mut datetimes = vec![];
    for weeks in 0.. {
        let datetime = first_datetime + Duration::try_weeks(weeks).unwrap();
        if datetime
            <= start
                + Duration::try_milliseconds(creatable_action_rule.create_before as i64).unwrap()
        {
            datetimes.push(datetime);
        } else {
            break;
        }
    }

    datetimes
}

fn delete_action_events(client: &Client, config: &Config) -> Result<(), ReqwestError> {
    let deletable_action_events: Vec<DeletableActionEvent> = client
        .get(route_max_version(
            &config.server_url,
            ADM_DELETABLE_ACTION_EVENT,
            None,
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
                + Duration::try_milliseconds(deletable_action_event.delete_after as i64).unwrap()
        {
            action_event_ids.push(deletable_action_event.action_event_id);
        }
    }

    info!("deleting {} action events", action_event_ids.len());
    debug!("{action_event_ids:#?}");

    client
        .delete(route_max_version(
            &config.server_url,
            ADM_ACTION_EVENT,
            None,
        ))
        .basic_auth(ADMIN_USERNAME, Some(&config.admin_password))
        .json(&action_event_ids)
        .send()?
        .error_for_status()?;

    info!("action events have been successfully deleted");

    Ok(())
}

#[cfg(test)]
mod tests {
    use std::str::FromStr;

    use chrono::{DateTime, Duration, NaiveDateTime, Utc};
    use sport_log_types::{ActionId, ActionRuleId, CreatableActionRule, UserId, Weekday};

    fn datetime(datetime: &str) -> DateTime<Utc> {
        DateTime::from_naive_utc_and_offset(NaiveDateTime::from_str(datetime).unwrap(), Utc)
    }

    #[test]
    fn datetimes_for_rule_from_start() {
        use super::datetimes_for_rule_from_start;
        let rule = CreatableActionRule {
            action_rule_id: ActionRuleId(1),
            user_id: UserId(1),
            action_id: ActionId(1),
            weekday: Weekday::Monday,
            time: datetime("2000-01-01T12:00:00"),
            arguments: None,
            create_before: Duration::try_days(14).unwrap().num_milliseconds() as i32,
        };

        // next day and in 8 days
        let datetimes = datetimes_for_rule_from_start(&rule, datetime("2023-01-01T00:00:00"));
        // 2023-01-01 is Sunday
        assert_eq!(
            datetimes,
            [
                datetime("2023-01-02T12:00:00"),
                datetime("2023-01-09T12:00:00"),
            ]
        );

        // not on same day but in 7 and 14 days (but earlier time)
        let datetimes = datetimes_for_rule_from_start(&rule, datetime("2023-01-02T12:00:01"));
        // 2023-01-02 is Monday
        assert_eq!(
            datetimes,
            [
                datetime("2023-01-09T12:00:00"),
                datetime("2023-01-16T12:00:00"),
            ]
        );
    }
}
