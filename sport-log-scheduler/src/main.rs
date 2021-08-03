use chrono::{Datelike, Duration, Local, NaiveDateTime};
use reqwest::blocking::Client;

use sport_log_types::{CreatableActionRule, DeletableActionEvent, NewActionEvent};

mod config;

use config::Config;

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

    let mut action_events = vec![];
    for creatable_action_rule in creatable_action_rules {
        let datetime = NaiveDateTime::new(
            Local::today()
                .naive_local()
                .checked_add_signed(Duration::days(
                    (creatable_action_rule.weekday.to_u32() as i64
                        - Local::today().weekday().num_days_from_monday() as i64)
                        .rem_euclid(7),
                ))
                .unwrap(),
            creatable_action_rule.time,
        );

        for weeks in 0.. {
            let datetime = datetime + Duration::weeks(weeks);
            if Local::now().naive_local()
                >= datetime - Duration::hours(creatable_action_rule.create_before as i64)
            {
                action_events.push(NewActionEvent {
                    user_id: creatable_action_rule.user_id,
                    action_id: creatable_action_rule.action_id,
                    datetime,
                    enabled: true,
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
        if Local::now().naive_local()
            >= deletable_action_event.datetime
                + Duration::hours(deletable_action_event.delete_after as i64)
        {
            action_event_ids.push(deletable_action_event.action_event_id);
        }
    }

    println!("{:#?}", action_event_ids);

    client
        .delete(format!("{}/v1/adm/action_events", config.base_url,))
        .basic_auth(username, Some(&config.admin_password))
        .json(&action_event_ids)
        .send()
        .unwrap();
}
