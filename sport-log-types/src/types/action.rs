use chrono::{NaiveDateTime, NaiveTime};
#[cfg(feature = "full")]
use diesel_derive_enum::DbEnum;
#[cfg(feature = "full")]
use rocket::http::Status;
use serde::{Deserialize, Serialize};

#[cfg(feature = "full")]
use sport_log_types_derive::{
    Create, CreateMultiple, Delete, DeleteMultiple, FromI32, FromSql, GetAll, GetById, GetByIds,
    GetByUser, ToSql, Update, VerifyForActionProviderWithDb, VerifyForActionProviderWithoutDb,
    VerifyForAdminWithoutDb, VerifyForUserWithDb, VerifyForUserWithoutDb,
    VerifyIdForActionProvider, VerifyIdForAdmin, VerifyIdForUser, VerifyIdForUserUnchecked,
};

#[cfg(feature = "full")]
use crate::{
    schema::{action, action_event, action_provider, action_rule},
    AuthenticatedActionProvider, GetById, Platform, UnverifiedId, User, VerifyIdForActionProvider,
};

use crate::{PlatformId, UserId};

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq)]
#[cfg_attr(
    feature = "full",
    derive(
        Hash,
        FromSqlRow,
        AsExpression,
        FromI32,
        ToSql,
        FromSql,
        VerifyIdForAdmin,
        VerifyIdForUserUnchecked
    )
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::Integer")]
pub struct ActionProviderId(pub i32);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(
        Associations,
        Identifiable,
        Queryable,
        AsChangeset,
        GetAll,
        Delete,
        DeleteMultiple,
        VerifyForAdminWithoutDb,
    )
)]
#[cfg_attr(feature = "full", table_name = "action_provider")]
#[cfg_attr(feature = "full", belongs_to(Platform))]
pub struct ActionProvider {
    pub id: ActionProviderId,
    pub name: String,
    pub password: String,
    pub platform_id: PlatformId,
    pub description: Option<String>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "full", derive(Insertable, VerifyForAdminWithoutDb))]
#[cfg_attr(feature = "full", table_name = "action_provider")]
pub struct NewActionProvider {
    pub name: String,
    pub password: String,
    pub platform_id: PlatformId,
    pub description: Option<String>,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq)]
#[cfg_attr(
    feature = "full",
    derive(
        Hash,
        FromSqlRow,
        AsExpression,
        FromI32,
        ToSql,
        FromSql,
        VerifyIdForActionProvider
    )
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::Integer")]
pub struct ActionId(pub i32);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(
        Associations,
        Identifiable,
        Queryable,
        AsChangeset,
        Create,
        CreateMultiple,
        GetById,
        GetByIds,
        GetAll,
        Delete,
        DeleteMultiple,
        VerifyForActionProviderWithDb,
    )
)]
#[cfg_attr(feature = "full", table_name = "action")]
#[cfg_attr(feature = "full", belongs_to(ActionProvider))]
pub struct Action {
    pub id: ActionId,
    pub name: String,
    pub action_provider_id: ActionProviderId,
    pub description: Option<String>,
    pub create_before: i32,
    pub delete_after: i32,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "full", derive(Insertable, VerifyForActionProviderWithoutDb))]
#[cfg_attr(feature = "full", table_name = "action")]
pub struct NewAction {
    pub name: String,
    pub action_provider_id: ActionProviderId,
    pub description: Option<String>,
    pub create_before: i32,
    pub delete_after: i32,
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
        FromI32,
        ToSql,
        FromSql,
        VerifyIdForUser
    )
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::Integer")]
pub struct ActionRuleId(pub i32);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(
        Associations,
        Identifiable,
        Queryable,
        AsChangeset,
        Create,
        CreateMultiple,
        GetById,
        GetByIds,
        GetByUser,
        Update,
        Delete,
        DeleteMultiple,
        VerifyForUserWithDb,
    )
)]
#[cfg_attr(feature = "full", table_name = "action_rule")]
#[cfg_attr(feature = "full", belongs_to(User))]
#[cfg_attr(feature = "full", belongs_to(Action))]
pub struct ActionRule {
    pub id: ActionRuleId,
    pub user_id: UserId,
    pub action_id: ActionId,
    pub weekday: Weekday,
    pub time: NaiveTime,
    pub enabled: bool,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "full", derive(Insertable, VerifyForUserWithoutDb))]
#[cfg_attr(feature = "full", table_name = "action_rule")]
pub struct NewActionRule {
    pub user_id: UserId,
    pub action_id: ActionId,
    pub weekday: Weekday,
    pub time: NaiveTime,
    pub enabled: bool,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq)]
#[cfg_attr(
    feature = "full",
    derive(
        Hash,
        FromSqlRow,
        AsExpression,
        FromI32,
        ToSql,
        FromSql,
        VerifyIdForUser,
        VerifyIdForAdmin
    )
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::Integer")]
pub struct ActionEventId(pub i32);

#[cfg(feature = "full")]
impl VerifyIdForActionProvider for UnverifiedId<ActionEventId> {
    type Id = ActionEventId;

    fn verify_ap(
        self,
        auth: &AuthenticatedActionProvider,
        conn: &PgConnection,
    ) -> Result<Self::Id, Status> {
        let action_event = ActionEvent::get_by_id(ActionEventId(self.0 .0), conn)
            .map_err(|_| Status::InternalServerError)?;
        let entity = Action::get_by_id(action_event.action_id, conn)
            .map_err(|_| Status::InternalServerError)?;
        if entity.action_provider_id == **auth {
            Ok(self.0)
        } else {
            Err(Status::Forbidden)
        }
    }
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(
        Associations,
        Identifiable,
        Queryable,
        AsChangeset,
        Create,
        CreateMultiple,
        GetById,
        GetByIds,
        GetByUser,
        Update,
        Delete,
        DeleteMultiple,
        VerifyForUserWithDb,
    )
)]
#[cfg_attr(feature = "full", table_name = "action_event")]
#[cfg_attr(feature = "full", belongs_to(User))]
#[cfg_attr(feature = "full", belongs_to(Action))]
pub struct ActionEvent {
    pub id: ActionEventId,
    pub user_id: UserId,
    pub action_id: ActionId,
    pub datetime: NaiveDateTime,
    pub enabled: bool,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(Insertable, VerifyForUserWithoutDb, VerifyForAdminWithoutDb)
)]
#[cfg_attr(feature = "full", table_name = "action_event")]
pub struct NewActionEvent {
    pub user_id: UserId,
    pub action_id: ActionId,
    pub datetime: NaiveDateTime,
    pub enabled: bool,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "full", derive(Queryable))]
pub struct CreatableActionRule {
    pub action_rule_id: ActionRuleId,
    pub user_id: UserId,
    pub action_id: ActionId,
    pub weekday: Weekday,
    pub time: NaiveTime,
    pub create_before: i32,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "full", derive(Queryable))]
pub struct ExecutableActionEvent {
    pub action_event_id: ActionEventId,
    pub action_name: String,
    pub datetime: NaiveDateTime,
    pub user_id: UserId,
    pub username: String,
    pub password: String,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "full", derive(Queryable))]
pub struct DeletableActionEvent {
    pub action_event_id: ActionEventId,
    pub datetime: NaiveDateTime,
    pub delete_after: i32,
}
