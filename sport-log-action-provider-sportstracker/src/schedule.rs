use chrono::{Datelike, Duration, Local, NaiveDateTime};
use reqwest::Client;

use sport_log_action_provider_sportstracker_config::Config;
use sport_log_types::types::{ActionEvent, ActionRule, NewActionEvent};

#[tokio::main]
async fn main() {
    let config = Config::get();

    let client = Client::new();

    let action_events: Vec<ActionEvent> = client
        .get(format!("{}/v1/ap/action_event", config.base_url))
        .basic_auth(&config.username, Some(&config.password))
        .send()
        .await
        .unwrap()
        .json()
        .await
        .unwrap();
    println!("{:#?}", action_events);
    for action_event in action_events {
        if action_event.datetime < Local::now().naive_local() {
            client
                .delete(format!(
                    "{}/v1/ap/action_event/{}",
                    config.base_url, action_event.id.0
                ))
                .basic_auth(&config.username, Some(&config.password))
                .send()
                .await
                .unwrap();
        }
    }

    let action_rules: Vec<ActionRule> = client
        .get(format!("{}/v1/ap/action_rule", config.base_url))
        .basic_auth(&config.username, Some(&config.password))
        .send()
        .await
        .unwrap()
        .json()
        .await
        .unwrap();
    println!("{:#?}", action_rules);

    for action_rule in action_rules {
        if action_rule.enabled {
            let action_event = NewActionEvent {
                user_id: action_rule.user_id,
                action_id: action_rule.action_id,
                datetime: NaiveDateTime::new(
                    Local::today()
                        .naive_local()
                        .checked_add_signed(Duration::days(
                            ((action_rule.weekday.to_u32()
                                - Local::today().weekday().num_days_from_monday())
                                % 7) as i64,
                        ))
                        .unwrap(),
                    action_rule.time,
                ),
                enabled: action_rule.enabled,
            };
            client
                .post(format!("{}/v1/ap/action_event", config.base_url))
                .basic_auth(&config.username, Some(&config.password))
                .json(&action_event)
                .send()
                .await
                .unwrap();
        }
    }
}
