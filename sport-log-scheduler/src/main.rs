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

use chrono::{DateTime, Datelike, Days, Duration, Local, TimeZone, Utc};
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
    start: DateTime<Utc>,
) -> Vec<DateTime<Utc>> {
    let date_monday_this_week =
        start.date_naive() - Days::new(start.weekday().num_days_from_monday() as u64);
    let target_date_this_week =
        date_monday_this_week + Days::new(creatable_action_rule.weekday.to_u32() as u64);
    let target_datetime_this_week = Local
        .from_local_datetime(
            &target_date_this_week
                .and_time(creatable_action_rule.time.with_timezone(&Local).time()),
        )
        .unwrap();

    let create_before =
        Duration::try_milliseconds(creatable_action_rule.create_before as i64).unwrap();

    (0..)
        .map(|i| target_datetime_this_week + Days::new(i * 7))
        .skip_while(|datetime| *datetime < start)
        .take_while(|datetime| *datetime <= start + create_before)
        .map(|d| DateTime::to_utc(&d))
        .collect()
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

    let action_event_ids: Vec<_> = deletable_action_events
        .into_iter()
        .filter(|deletable| {
            let delete_after = Duration::try_milliseconds(deletable.delete_after as i64).unwrap();
            deletable.datetime + delete_after <= Utc::now()
        })
        .map(|deletable| deletable.action_event_id)
        .collect();

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

    use chrono::{DateTime, Duration, NaiveDateTime};
    use sport_log_types::{ActionId, ActionRuleId, CreatableActionRule, UserId, Weekday};

    use super::*;

    fn datetime(datetime: &str) -> DateTime<Utc> {
        Local
            .from_local_datetime(&NaiveDateTime::from_str(datetime).unwrap())
            .unwrap()
            .to_utc()
    }

    #[test]
    fn datetimes_for_rule_from_start_produce_datetimes_in_interval_at_correct_weekday_and_time() {
        // Tuesday at 12:00 up to 14 day in advance
        let rule = CreatableActionRule {
            action_rule_id: ActionRuleId(1),
            user_id: UserId(1),
            action_id: ActionId(1),
            weekday: Weekday::Tuesday,
            time: datetime("2000-01-01T12:00:00"),
            arguments: None,
            create_before: Duration::try_days(14).unwrap().num_milliseconds() as i32,
        };

        // 2023-01-01 is Sunday
        // in 2 and 9 days
        assert_eq!(
            datetimes_for_rule_from_start(&rule, datetime("2023-01-01T11:00:00")),
            [
                datetime("2023-01-03T12:00:00"),
                datetime("2023-01-10T12:00:00"),
            ]
        );

        // 2023-01-01 is Sunday
        // in 2 and 9 days
        assert_eq!(
            datetimes_for_rule_from_start(&rule, datetime("2023-01-01T13:00:00")),
            [
                datetime("2023-01-03T12:00:00"),
                datetime("2023-01-10T12:00:00"),
            ]
        );

        // 2023-01-02 is Monday
        // in 1 and 8 days
        assert_eq!(
            datetimes_for_rule_from_start(&rule, datetime("2023-01-02T11:00:00")),
            [
                datetime("2023-01-03T12:00:00"),
                datetime("2023-01-10T12:00:00"),
            ]
        );

        // 2023-01-02 is Monday
        // in 1 and 8 days
        assert_eq!(
            datetimes_for_rule_from_start(&rule, datetime("2023-01-02T13:00:00")),
            [
                datetime("2023-01-03T12:00:00"),
                datetime("2023-01-10T12:00:00"),
            ]
        );

        // 2023-01-03 is Tuesday
        // today at later time and in 7 days
        assert_eq!(
            datetimes_for_rule_from_start(&rule, datetime("2023-01-03T11:00:00")),
            [
                datetime("2023-01-03T12:00:00"),
                datetime("2023-01-10T12:00:00"),
            ]
        );

        // 2023-01-03 is Tuesday
        // in 7 and 14 days at earlier time
        assert_eq!(
            datetimes_for_rule_from_start(&rule, datetime("2023-01-03T13:00:00")),
            [
                datetime("2023-01-10T12:00:00"),
                datetime("2023-01-17T12:00:00"),
            ]
        );

        // 2023-01-04 is Wednesday
        // in 6 and 13 days at earlier time
        assert_eq!(
            datetimes_for_rule_from_start(&rule, datetime("2023-01-04T11:00:00")),
            [
                datetime("2023-01-10T12:00:00"),
                datetime("2023-01-17T12:00:00"),
            ]
        );

        // 2023-01-04 is Wednesday
        // in 6 and 13 days at earlier time
        assert_eq!(
            datetimes_for_rule_from_start(&rule, datetime("2023-01-04T13:00:00")),
            [
                datetime("2023-01-10T12:00:00"),
                datetime("2023-01-17T12:00:00"),
            ]
        );

        // 2025-10-19 is Sunday
        // in 2 and 9 days
        // in 2 day is same timezone
        // in 9 days is after summer-winter time zone change
        assert_eq!(
            datetimes_for_rule_from_start(&rule, datetime("2025-10-19T11:00:00")),
            [
                datetime("2025-10-21T12:00:00"),
                datetime("2025-10-28T12:00:00"),
            ]
        );

        // 2025-10-26 is Sunday
        // in 2 and 9 days
        assert_eq!(
            datetimes_for_rule_from_start(&rule, datetime("2025-10-26T11:00:00")),
            [
                datetime("2025-10-28T12:00:00"),
                datetime("2025-11-04T12:00:00"),
            ]
        );
    }
}
