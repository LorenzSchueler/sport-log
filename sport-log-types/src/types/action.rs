use chrono::{DateTime, Utc};
#[cfg(feature = "full")]
use diesel_derive_enum::DbEnum;
#[cfg(feature = "full")]
use serde::{Deserialize, Serialize};

#[cfg(feature = "full")]
use sport_log_types_derive::{
    CheckAPId, CheckUserId, Create, CreateMultiple, FromI64, FromSql, GetAll, GetById, GetByIds,
    GetBySync, GetByUser, GetByUserSync, ToI64, ToSql, Update, VerifyForActionProviderWithDb,
    VerifyForActionProviderWithoutDb, VerifyForAdminWithoutDb, VerifyForUserWithDb,
    VerifyForUserWithoutDb, VerifyIdForActionProvider, VerifyIdForAdmin, VerifyIdForUser,
    VerifyIdUnchecked, VerifyUnchecked,
};

use crate::{from_str, to_str, PlatformId, UserId};
#[cfg(feature = "full")]
use crate::{
    schema::{action, action_event, action_provider, action_rule},
    Platform, User,
};

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq)]
#[cfg_attr(
    feature = "full",
    derive(
        Hash,
        FromSqlRow,
        AsExpression,
        FromI64,
        ToI64,
        ToSql,
        FromSql,
        VerifyIdForAdmin,
        VerifyIdUnchecked
    )
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::BigInt")]
pub struct ActionProviderId(pub i64);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(
        Insertable,
        Associations,
        Identifiable,
        Queryable,
        AsChangeset,
        GetById,
        GetByIds,
        GetAll,
        GetBySync,
        VerifyForAdminWithoutDb,
        VerifyUnchecked
    )
)]
#[cfg_attr(feature = "full", table_name = "action_provider")]
#[cfg_attr(feature = "full", belongs_to(Platform))]
pub struct ActionProvider {
    #[serde(serialize_with = "to_str")]
    #[serde(deserialize_with = "from_str")]
    pub id: ActionProviderId,
    pub name: String,
    pub password: String,
    pub platform_id: PlatformId,
    pub description: Option<String>,
    #[serde(skip)]
    #[serde(default = "Utc::now")]
    pub last_change: DateTime<Utc>,
    pub deleted: bool,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq)]
#[cfg_attr(
    feature = "full",
    derive(
        Hash,
        FromSqlRow,
        AsExpression,
        FromI64,
        ToI64,
        ToSql,
        FromSql,
        VerifyIdForActionProvider
    )
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::BigInt")]
pub struct ActionId(pub i64);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(
        Insertable,
        Associations,
        Identifiable,
        Queryable,
        AsChangeset,
        Create,
        CreateMultiple,
        GetById,
        GetByIds,
        GetAll,
        GetBySync,
        CheckAPId,
        VerifyForActionProviderWithDb,
        VerifyForActionProviderWithoutDb,
    )
)]
#[cfg_attr(feature = "full", table_name = "action")]
#[cfg_attr(feature = "full", belongs_to(ActionProvider))]
pub struct Action {
    #[serde(serialize_with = "to_str")]
    #[serde(deserialize_with = "from_str")]
    pub id: ActionId,
    pub name: String,
    pub action_provider_id: ActionProviderId,
    pub description: Option<String>,
    pub create_before: i32,
    pub delete_after: i32,
    #[serde(skip)]
    #[serde(default = "Utc::now")]
    pub last_change: DateTime<Utc>,
    pub deleted: bool,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq)]
#[cfg_attr(feature = "full", derive(DbEnum))]
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

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq)]
#[cfg_attr(
    feature = "full",
    derive(
        Hash,
        FromSqlRow,
        AsExpression,
        FromI64,
        ToI64,
        ToSql,
        FromSql,
        VerifyIdForUser
    )
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::BigInt")]
pub struct ActionRuleId(pub i64);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(
        Insertable,
        Associations,
        Identifiable,
        Queryable,
        AsChangeset,
        Create,
        CreateMultiple,
        GetById,
        GetByIds,
        GetByUser,
        GetByUserSync,
        Update,
        CheckUserId,
        VerifyForUserWithDb,
        VerifyForUserWithoutDb,
    )
)]
#[cfg_attr(feature = "full", table_name = "action_rule")]
#[cfg_attr(feature = "full", belongs_to(User))]
#[cfg_attr(feature = "full", belongs_to(Action))]
pub struct ActionRule {
    #[serde(serialize_with = "to_str")]
    #[serde(deserialize_with = "from_str")]
    pub id: ActionRuleId,
    pub user_id: UserId,
    pub action_id: ActionId,
    pub weekday: Weekday,
    pub time: DateTime<Utc>,
    pub enabled: bool,
    #[serde(skip)]
    #[serde(default = "Utc::now")]
    pub last_change: DateTime<Utc>,
    pub deleted: bool,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq)]
#[cfg_attr(
    feature = "full",
    derive(
        Hash,
        FromSqlRow,
        AsExpression,
        FromI64,
        ToI64,
        ToSql,
        FromSql,
        VerifyIdForUser,
        VerifyIdForActionProvider,
        VerifyIdForAdmin
    )
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::BigInt")]
pub struct ActionEventId(pub i64);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(
        Insertable,
        Associations,
        Identifiable,
        Queryable,
        AsChangeset,
        Create,
        CreateMultiple,
        GetById,
        GetByIds,
        GetByUser,
        GetByUserSync,
        Update,
        CheckUserId,
        VerifyForUserWithDb,
        VerifyForUserWithoutDb,
        VerifyForAdminWithoutDb,
    )
)]
#[cfg_attr(feature = "full", table_name = "action_event")]
#[cfg_attr(feature = "full", belongs_to(User))]
#[cfg_attr(feature = "full", belongs_to(Action))]
pub struct ActionEvent {
    #[serde(serialize_with = "to_str")]
    #[serde(deserialize_with = "from_str")]
    pub id: ActionEventId,
    pub user_id: UserId,
    pub action_id: ActionId,
    pub datetime: DateTime<Utc>,
    pub enabled: bool,
    #[serde(skip)]
    #[serde(default = "Utc::now")]
    pub last_change: DateTime<Utc>,
    pub deleted: bool,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "full", derive(Queryable))]
pub struct CreatableActionRule {
    pub action_rule_id: ActionRuleId,
    pub user_id: UserId,
    pub action_id: ActionId,
    pub weekday: Weekday,
    pub time: DateTime<Utc>,
    pub create_before: i32,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "full", derive(Queryable))]
pub struct ExecutableActionEvent {
    pub action_event_id: ActionEventId,
    pub action_name: String,
    pub datetime: DateTime<Utc>,
    pub user_id: UserId,
    pub username: String,
    pub password: String,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "full", derive(Queryable))]
pub struct DeletableActionEvent {
    pub action_event_id: ActionEventId,
    pub datetime: DateTime<Utc>,
    pub delete_after: i32,
}
