use chrono::{NaiveDateTime, NaiveTime};
use diesel_derive_enum::DbEnum;
use serde::{Deserialize, Serialize};

use crate::schema::*;

pub type AccountId = i32;

#[derive(Queryable, AsChangeset, Serialize, Deserialize, Debug)]
#[table_name = "account"]
pub struct Account {
    pub id: AccountId,
    pub username: String,
    pub password: String,
    pub email: String,
}

#[derive(Insertable, Serialize, Deserialize)]
#[table_name = "account"]
pub struct NewAccount {
    pub username: String,
    pub password: String,
    pub email: String,
}

pub type PlatformId = i32;

#[derive(Queryable, AsChangeset, Serialize, Deserialize, Debug)]
#[table_name = "platform"]
pub struct Platform {
    pub id: PlatformId,
    pub name: String,
}

pub type PlatformCredentialsId = i32;

#[derive(Queryable, AsChangeset, Serialize, Deserialize, Debug)]
#[table_name = "platform_credentials"]
pub struct PlatformCredentials {
    pub id: PlatformCredentialsId,
    pub account_id: AccountId,
    pub platform_id: PlatformId,
    pub username: String,
    pub password: String,
}

#[derive(Insertable, Serialize, Deserialize)]
#[table_name = "platform_credentials"]
pub struct NewPlatformCredentials {
    pub account_id: AccountId,
    pub platform_id: PlatformId,
    pub username: String,
    pub password: String,
}

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
