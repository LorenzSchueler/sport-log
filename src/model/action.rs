use chrono::{NaiveDateTime, NaiveTime};
use diesel_derive_enum::DbEnum;
use serde::{Deserialize, Serialize};

use super::*;
use crate::schema::{action, action_event, action_rule};

pub type ActionId = i32;

#[derive(Queryable, AsChangeset, Serialize, Deserialize, Debug)]
#[table_name = "action"]
pub struct Action {
    pub id: AccountId,
    pub platform_id: PlatformId,
    pub name: String,
}

#[derive(Insertable, Serialize, Deserialize)]
#[table_name = "action"]
pub struct NewAction {
    pub platform_id: PlatformId,
    pub name: String,
}

#[derive(DbEnum, Debug, Serialize, Deserialize)]
pub enum Weekday {
    Monday,
    Tuesday,
    Wednesday,
    Thursday,
    Friday,
    Saturday,
    Sunday,
}

pub type ActionRuleId = i32;

#[derive(Queryable, AsChangeset, Serialize, Deserialize, Debug)]
#[table_name = "action_rule"]
pub struct ActionRule {
    pub id: ActionRuleId,
    pub account_id: AccountId,
    pub action_id: ActionId,
    pub weekday: Weekday,
    pub time: NaiveTime,
    pub enabled: bool,
}

#[derive(Insertable, Serialize, Deserialize)]
#[table_name = "action_rule"]
pub struct NewActionRule {
    pub account_id: AccountId,
    pub action_id: ActionId,
    pub weekday: Weekday,
    pub time: NaiveTime,
    pub enabled: bool,
}

pub type ActionEventId = i32;

#[derive(Queryable, AsChangeset, Serialize, Deserialize, Debug)]
#[table_name = "action_event"]
pub struct ActionEvent {
    pub id: ActionEventId,
    pub account_id: AccountId,
    pub action_id: ActionId,
    pub datetime: NaiveDateTime,
    pub enabled: bool,
}

#[derive(Insertable, Serialize, Deserialize)]
#[table_name = "action_event"]
pub struct NewActionEvent {
    pub account_id: AccountId,
    pub action_id: ActionId,
    pub datetime: NaiveDateTime,
    pub enabled: bool,
}

#[derive(Queryable, Serialize, Deserialize, Debug)]
pub struct ExecutableActionEvent {
    pub action_name: String,
    pub datetime: NaiveDateTime,
    pub username: String,
    pub password: String,
}
