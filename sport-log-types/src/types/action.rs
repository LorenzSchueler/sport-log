use chrono::{DateTime, Utc};
#[cfg(feature = "server")]
use diesel::sql_types::BigInt;
#[cfg(feature = "server")]
use diesel_derive_enum::DbEnum;
use serde::{Deserialize, Serialize};
#[cfg(feature = "server")]
use sport_log_types_derive::{
    CheckAPId, CheckUserId, Create, GetAll, GetById, GetByIds, GetBySync, GetByUser, GetByUserSync,
    HardDelete, IdFromSql, IdToSql, Update, VerifyForActionProviderWithDb,
    VerifyForActionProviderWithoutDb, VerifyForAdminWithoutDb, VerifyForUserWithDb,
    VerifyForUserWithoutDb, VerifyIdForActionProvider, VerifyIdForAdmin, VerifyIdForUser,
    VerifyIdUnchecked, VerifyUnchecked,
};

#[cfg(feature = "server")]
use crate::{
    schema::{action, action_event, action_provider, action_rule},
    Platform, User,
};
use crate::{PlatformId, UserId};

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq, PartialOrd, Ord)]
#[serde(transparent)]
#[cfg_attr(
    feature = "server",
    derive(
        Hash,
        FromSqlRow,
        AsExpression,
        IdToSql,
        IdFromSql,
        VerifyIdForAdmin,
        VerifyIdUnchecked
    ),
    diesel(sql_type = diesel::sql_types::BigInt)
)]
pub struct ActionProviderId(pub i64);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "server",
    derive(
        Insertable,
        Associations,
        Identifiable,
        Queryable,
        Selectable,
        AsChangeset,
        GetById,
        GetByIds,
        GetAll,
        GetBySync,
        HardDelete,
        VerifyForAdminWithoutDb,
        VerifyUnchecked,
    ),
    diesel(table_name = action_provider, belongs_to(Platform))
)]
pub struct ActionProvider {
    pub id: ActionProviderId,
    pub name: String,
    pub password: String,

    pub platform_id: PlatformId,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub description: Option<String>,
    pub deleted: bool,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq, PartialOrd, Ord)]
#[serde(transparent)]
#[cfg_attr(
    feature = "server",
    derive(
        Hash,
        FromSqlRow,
        AsExpression,
        IdToSql,
        IdFromSql,
        VerifyIdUnchecked,
        VerifyIdForActionProvider
    ),
    diesel(sql_type = diesel::sql_types::BigInt)
)]
pub struct ActionId(pub i64);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "server",
    derive(
        Insertable,
        Associations,
        Identifiable,
        Queryable,
        Selectable,
        AsChangeset,
        Create,
        GetById,
        GetByIds,
        GetAll,
        GetBySync,
        HardDelete,
        CheckAPId,
        VerifyForActionProviderWithDb,
        VerifyForActionProviderWithoutDb,
    ),
    diesel(table_name = action, belongs_to(ActionProvider))
)]
pub struct Action {
    pub id: ActionId,
    pub name: String,
    pub action_provider_id: ActionProviderId,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub description: Option<String>,
    pub create_before: i32,
    pub delete_after: i32,
    pub deleted: bool,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq)]
#[cfg_attr(feature = "server", derive(DbEnum))]

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

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq, PartialOrd, Ord)]
#[serde(transparent)]
#[cfg_attr(
    feature = "server",
    derive(Hash, FromSqlRow, AsExpression, IdToSql, IdFromSql, VerifyIdForUser),
    diesel(sql_type = BigInt)
)]
pub struct ActionRuleId(pub i64);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "server",
    derive(
        Insertable,
        Associations,
        Identifiable,
        Queryable,
        Selectable,
        AsChangeset,
        Create,
        GetById,
        GetByIds,
        GetByUser,
        GetByUserSync,
        Update,
        HardDelete,
        CheckUserId,
        VerifyForUserWithDb,
        VerifyForUserWithoutDb,
    ),
    diesel(table_name = action_rule,belongs_to(User),belongs_to(Action))
)]
pub struct ActionRule {
    pub id: ActionRuleId,
    pub user_id: UserId,
    pub action_id: ActionId,
    pub weekday: Weekday,
    pub time: DateTime<Utc>,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub arguments: Option<String>,
    pub enabled: bool,
    pub deleted: bool,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq, PartialOrd, Ord)]
#[serde(transparent)]
#[cfg_attr(
    feature = "server",
    derive(
        Hash,
        FromSqlRow,
        AsExpression,
        IdToSql,
        IdFromSql,
        VerifyIdForUser,
        VerifyIdForActionProvider,
        VerifyIdForAdmin
    ),
    diesel(sql_type = BigInt)
)]
pub struct ActionEventId(pub i64);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "server",
    derive(
        Insertable,
        Associations,
        Identifiable,
        Queryable,
        Selectable,
        AsChangeset,
        Create,
        GetById,
        GetByIds,
        GetByUser,
        GetByUserSync,
        Update,
        HardDelete,
        CheckUserId,
        VerifyForUserWithDb,
        VerifyForUserWithoutDb,
        VerifyForAdminWithoutDb,
    ),
    diesel(table_name = action_event, belongs_to(User), belongs_to(Action))
)]
pub struct ActionEvent {
    pub id: ActionEventId,
    pub user_id: UserId,
    pub action_id: ActionId,
    pub datetime: DateTime<Utc>,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub arguments: Option<String>,
    pub enabled: bool,
    pub deleted: bool,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "server", derive(Queryable))]
pub struct CreatableActionRule {
    pub action_rule_id: ActionRuleId,
    pub user_id: UserId,
    pub action_id: ActionId,
    pub weekday: Weekday,
    pub time: DateTime<Utc>,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub arguments: Option<String>,
    pub create_before: i32,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "server", derive(Queryable))]
pub struct ExecutableActionEvent {
    pub action_event_id: ActionEventId,
    pub action_name: String,
    pub datetime: DateTime<Utc>,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub arguments: Option<String>,
    pub user_id: UserId,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub username: Option<String>,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub password: Option<String>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "server", derive(Queryable))]
pub struct DeletableActionEvent {
    pub action_event_id: ActionEventId,
    pub datetime: DateTime<Utc>,
    pub delete_after: i32,
}
