use chrono::{NaiveDateTime, NaiveTime};
use diesel_derive_enum::DbEnum;
use serde::{Deserialize, Serialize};

use sport_log_server_derive::{
    Create, Delete, GetAll, GetById, InnerIntFromSql, InnerIntToSql, Update,
    VerifyForActionProviderWithDb, VerifyForActionProviderWithoutDb, VerifyForAdminWithoutDb,
    VerifyForUserWithDb, VerifyForUserWithoutDb,
};

use super::*;
use crate::schema::{action, action_event, action_provider, action_rule};

#[derive(
    FromSqlRow,
    AsExpression,
    Serialize,
    Deserialize,
    Debug,
    Clone,
    Copy,
    PartialEq,
    Eq,
    InnerIntToSql,
    InnerIntFromSql,
)]
#[sql_type = "diesel::sql_types::Integer"]
pub struct ActionProviderId(pub i32);

#[derive(
    Queryable,
    AsChangeset,
    Serialize,
    Deserialize,
    Debug,
    Create,
    GetAll,
    Delete,
    VerifyForAdminWithoutDb,
)]
#[table_name = "action_provider"]
pub struct ActionProvider {
    pub id: ActionId,
    pub name: String,
    pub password: String,
    pub platform_id: PlatformId,
}

#[derive(Insertable, Serialize, Deserialize, VerifyForAdminWithoutDb)]
#[table_name = "action_provider"]
pub struct NewActionProvider {
    pub name: String,
    pub password: String,
    pub platform_id: PlatformId,
}

#[derive(
    FromSqlRow,
    AsExpression,
    Serialize,
    Deserialize,
    Debug,
    Clone,
    Copy,
    PartialEq,
    Eq,
    InnerIntToSql,
    InnerIntFromSql,
)]
#[sql_type = "diesel::sql_types::Integer"]
pub struct ActionId(pub i32);

#[derive(
    Queryable,
    AsChangeset,
    Serialize,
    Deserialize,
    Debug,
    Create,
    GetById,
    GetAll,
    Delete,
    VerifyForActionProviderWithDb,
)]
#[table_name = "action"]
pub struct Action {
    pub id: ActionId,
    pub name: String,
    pub action_provider_id: ActionProviderId,
}

#[derive(Insertable, Serialize, Deserialize, VerifyForActionProviderWithoutDb)]
#[table_name = "action"]
pub struct NewAction {
    pub name: String,
    pub action_provider_id: ActionProviderId,
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

#[derive(
    FromSqlRow,
    AsExpression,
    Serialize,
    Deserialize,
    Debug,
    Clone,
    Copy,
    PartialEq,
    Eq,
    InnerIntToSql,
    InnerIntFromSql,
)]
#[sql_type = "diesel::sql_types::Integer"]
pub struct ActionRuleId(pub i32);

#[derive(
    Queryable,
    AsChangeset,
    Serialize,
    Deserialize,
    Debug,
    Create,
    GetById,
    Update,
    Delete,
    VerifyForUserWithDb,
)]
#[table_name = "action_rule"]
pub struct ActionRule {
    pub id: ActionRuleId,
    pub user_id: UserId,
    pub action_id: ActionId,
    pub weekday: Weekday,
    pub time: NaiveTime,
    pub enabled: bool,
}

#[derive(Insertable, Serialize, Deserialize, VerifyForUserWithoutDb)]
#[table_name = "action_rule"]
pub struct NewActionRule {
    pub user_id: UserId,
    pub action_id: ActionId,
    pub weekday: Weekday,
    pub time: NaiveTime,
    pub enabled: bool,
}

#[derive(
    FromSqlRow,
    AsExpression,
    Serialize,
    Deserialize,
    Debug,
    Clone,
    Copy,
    PartialEq,
    Eq,
    InnerIntToSql,
    InnerIntFromSql,
)]
#[sql_type = "diesel::sql_types::Integer"]
pub struct ActionEventId(pub i32);

#[derive(
    Queryable,
    AsChangeset,
    Serialize,
    Deserialize,
    Debug,
    Create,
    GetById,
    Update,
    Delete,
    VerifyForUserWithDb,
)]
#[table_name = "action_event"]
pub struct ActionEvent {
    pub id: ActionEventId,
    pub user_id: UserId,
    pub action_id: ActionId,
    pub datetime: NaiveDateTime,
    pub enabled: bool,
}

#[derive(Insertable, Serialize, Deserialize, VerifyForUserWithoutDb)]
#[table_name = "action_event"]
pub struct NewActionEvent {
    pub user_id: UserId,
    pub action_id: ActionId,
    pub datetime: NaiveDateTime,
    pub enabled: bool,
}

#[derive(Queryable, Serialize, Deserialize, Debug)]
pub struct ExecutableActionEvent {
    pub action_event_id: ActionEventId,
    pub action_name: String,
    pub datetime: NaiveDateTime,
    pub username: String,
    pub password: String,
}
