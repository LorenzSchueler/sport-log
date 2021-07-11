use chrono::{NaiveDateTime, NaiveTime};
use serde::{Deserialize, Serialize};

use crate::{PlatformId, UserId};

pub type ActionProviderId = i32;

#[derive(Serialize, Deserialize, Debug)]
pub struct ActionProvider {
    pub id: ActionId,
    pub name: String,
    pub password: String,
    pub platform_id: PlatformId,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct NewActionProvider {
    pub name: String,
    pub password: String,
    pub platform_id: PlatformId,
}

pub type ActionId = i32;

#[derive(Serialize, Deserialize, Debug)]
pub struct Action {
    pub id: ActionId,
    pub name: String,
    pub action_provider_id: ActionProviderId,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct NewAction {
    pub name: String,
    pub action_provider_id: ActionProviderId,
}

#[derive(Serialize, Deserialize, Debug)]
pub enum Weekday {
    Monday,
    Tuesday,
    Wednesday,
    Thursday,
    Friday,
    Saturday,
    Sunday,
}

impl Weekday {
    pub fn to_u32(&self) -> u32 {
        match self {
            Weekday::Monday => 0,
            Weekday::Tuesday => 1,
            Weekday::Wednesday => 2,
            Weekday::Thursday => 3,
            Weekday::Friday => 4,
            Weekday::Saturday => 5,
            Weekday::Sunday => 6,
        }
    }
}

pub type ActionRuleId = i32;

#[derive(Serialize, Deserialize, Debug)]
pub struct ActionRule {
    pub id: ActionRuleId,
    pub user_id: UserId,
    pub action_id: ActionId,
    pub weekday: Weekday,
    pub time: NaiveTime,
    pub enabled: bool,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct NewActionRule {
    pub user_id: UserId,
    pub action_id: ActionId,
    pub weekday: Weekday,
    pub time: NaiveTime,
    pub enabled: bool,
}

pub type ActionEventId = i32;

#[derive(Serialize, Deserialize, Debug)]
pub struct ActionEvent {
    pub id: ActionEventId,
    pub user_id: UserId,
    pub action_id: ActionId,
    pub datetime: NaiveDateTime,
    pub enabled: bool,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct NewActionEvent {
    pub user_id: UserId,
    pub action_id: ActionId,
    pub datetime: NaiveDateTime,
    pub enabled: bool,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct ExecutableActionEvent {
    pub action_event_id: ActionEventId,
    pub action_name: String,
    pub datetime: NaiveDateTime,
    pub username: String,
    pub password: String,
}
