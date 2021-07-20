use chrono::NaiveDateTime;
use serde::{Deserialize, Serialize};

#[cfg(feature = "full")]
use sport_log_server_derive::{Create, Delete, FromSql, GetAll, GetById, GetByUser, ToSql, Update};

#[cfg(feature = "full")]
use crate::schema::{strength_session, strength_set};
use crate::types::{MovementId, MovementUnit, UserId};

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(FromSqlRow, AsExpression, Copy, PartialEq, Eq, ToSql, FromSql,)
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::Integer")]
pub struct StrengthSessionId(pub i32);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(
        Queryable,
        AsChangeset,
        Create,
        GetById,
        GetByUser,
        GetAll,
        Update,
        Delete,
    )
)]
#[cfg_attr(feature = "full", table_name = "strength_session")]
pub struct StrengthSession {
    pub id: StrengthSessionId,
    pub user_id: UserId,
    pub datetime: NaiveDateTime,
    pub movement_id: MovementId,
    pub movement_unit: MovementUnit,
    pub interval: Option<i32>,
    pub comments: Option<String>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "full", derive(Insertable))]
#[cfg_attr(feature = "full", table_name = "strength_session")]
pub struct NewStrengthSession {
    pub user_id: UserId,
    pub datetime: NaiveDateTime,
    pub movement_id: MovementId,
    pub movement_unit: MovementUnit,
    pub interval: Option<i32>,
    pub comments: Option<String>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(FromSqlRow, AsExpression, Copy, PartialEq, Eq, ToSql, FromSql,)
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::Integer")]
pub struct StrengthSetId(pub i32);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(Queryable, AsChangeset, Create, GetById, GetAll, Update, Delete,)
)]
#[cfg_attr(feature = "full", table_name = "strength_set")]
pub struct StrengthSet {
    pub id: StrengthSetId,
    pub strength_session_id: StrengthSessionId,
    pub count: i32,
    pub weight: Option<f32>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "full", derive(Insertable))]
#[cfg_attr(feature = "full", table_name = "strength_set")]
pub struct NewStrengthSet {
    pub strength_session_id: StrengthSessionId,
    pub count: i32,
    pub weight: Option<f32>,
}
