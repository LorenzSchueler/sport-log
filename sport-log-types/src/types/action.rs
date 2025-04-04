use chrono::{DateTime, Utc};
use derive_deftly::Deftly;
#[cfg(feature = "db")]
use diesel::{deserialize::FromSqlRow, expression::AsExpression, prelude::*, sql_types::BigInt};
#[cfg(feature = "db")]
use diesel_derive_enum::DbEnum;
use serde::{Deserialize, Serialize};

#[cfg(feature = "db")]
use crate::{
    Platform, User,
    schema::{action, action_event, action_provider, action_rule},
};
use crate::{PlatformId, UserId, types::IdString};

#[derive(Serialize, Deserialize, Debug, Clone, Copy, PartialEq, Eq, Deftly)]
#[derive_deftly(IdString)]
#[serde(try_from = "IdString", into = "IdString")]
#[cfg_attr(
    feature = "db",
    derive(Hash, FromSqlRow, AsExpression),
    derive_deftly(IntoPgBigInt, FromPgBigInt),
    diesel(sql_type = diesel::sql_types::BigInt)
)]
pub struct ActionProviderId(pub i64);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "db",
    derive(
        Insertable,
        Associations,
        Identifiable,
        Queryable,
        Selectable,
        AsChangeset,
    ),
    diesel(table_name = action_provider, belongs_to(Platform))
)]
pub struct ActionProvider {
    pub id: ActionProviderId,
    pub name: String,
    pub password: String,

    pub platform_id: PlatformId,
    #[cfg_attr(feature = "db", diesel(treat_none_as_null = true))]
    pub description: Option<String>,
    pub deleted: bool,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, PartialEq, Eq, Deftly)]
#[derive_deftly(IdString)]
#[serde(try_from = "IdString", into = "IdString")]
#[cfg_attr(
    feature = "db",
    derive(Hash, FromSqlRow, AsExpression),
    derive_deftly(IntoPgBigInt, FromPgBigInt),
    diesel(sql_type = diesel::sql_types::BigInt)
)]
pub struct ActionId(pub i64);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "db",
    derive(
        Insertable,
        Associations,
        Identifiable,
        Queryable,
        Selectable,
        AsChangeset,
    ),
    diesel(table_name = action, belongs_to(ActionProvider))
)]
pub struct Action {
    pub id: ActionId,
    pub name: String,
    pub action_provider_id: ActionProviderId,
    #[cfg_attr(feature = "db", diesel(treat_none_as_null = true))]
    pub description: Option<String>,
    pub create_before: i32,
    pub delete_after: i32,
    pub deleted: bool,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, PartialEq, Eq)]
#[cfg_attr(
    feature = "db",
    derive(DbEnum),
    ExistingTypePath = "crate::schema::sql_types::Weekday"
)]

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
    pub fn to_u32(self) -> u32 {
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

#[derive(Serialize, Deserialize, Debug, Clone, Copy, PartialEq, Eq, Deftly)]
#[derive_deftly(IdString)]
#[serde(try_from = "IdString", into = "IdString")]
#[cfg_attr(
    feature = "db",
    derive(Hash, FromSqlRow, AsExpression),
    derive_deftly(IntoPgBigInt, FromPgBigInt),
    diesel(sql_type = BigInt)
)]
pub struct ActionRuleId(pub i64);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "db",
    derive(
        Insertable,
        Associations,
        Identifiable,
        Queryable,
        Selectable,
        AsChangeset,
    ),
    diesel(table_name = action_rule, belongs_to(User), belongs_to(Action))
)]
pub struct ActionRule {
    pub id: ActionRuleId,
    pub user_id: UserId,
    pub action_id: ActionId,
    pub weekday: Weekday,
    pub time: DateTime<Utc>,
    #[cfg_attr(feature = "db", diesel(treat_none_as_null = true))]
    pub arguments: Option<String>,
    pub enabled: bool,
    pub deleted: bool,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, PartialEq, Eq, Deftly)]
#[derive_deftly(IdString)]
#[serde(try_from = "IdString", into = "IdString")]
#[cfg_attr(
    feature = "db",
    derive(Hash, FromSqlRow, AsExpression),
    derive_deftly(IntoPgBigInt, FromPgBigInt),
    diesel(sql_type = BigInt)
)]
pub struct ActionEventId(pub i64);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "db",
    derive(
        Insertable,
        Associations,
        Identifiable,
        Queryable,
        Selectable,
        AsChangeset,
    ),
    diesel(table_name = action_event, belongs_to(User), belongs_to(Action))
)]
pub struct ActionEvent {
    pub id: ActionEventId,
    pub user_id: UserId,
    pub action_id: ActionId,
    pub datetime: DateTime<Utc>,
    #[cfg_attr(feature = "db", diesel(treat_none_as_null = true))]
    pub arguments: Option<String>,
    pub enabled: bool,
    pub deleted: bool,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "db", derive(Queryable))]
pub struct CreatableActionRule {
    pub action_rule_id: ActionRuleId,
    pub user_id: UserId,
    pub action_id: ActionId,
    pub weekday: Weekday,
    pub time: DateTime<Utc>,
    #[cfg_attr(feature = "db", diesel(treat_none_as_null = true))]
    pub arguments: Option<String>,
    pub create_before: i32,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "db", derive(Queryable))]
pub struct ExecutableActionEvent {
    pub action_event_id: ActionEventId,
    pub action_name: String,
    pub datetime: DateTime<Utc>,
    #[cfg_attr(feature = "db", diesel(treat_none_as_null = true))]
    pub arguments: Option<String>,
    pub user_id: UserId,
    #[cfg_attr(feature = "db", diesel(treat_none_as_null = true))]
    pub username: Option<String>,
    #[cfg_attr(feature = "db", diesel(treat_none_as_null = true))]
    pub password: Option<String>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "db", derive(Queryable))]
pub struct DeletableActionEvent {
    pub action_event_id: ActionEventId,
    pub datetime: DateTime<Utc>,
    pub delete_after: i32,
}
