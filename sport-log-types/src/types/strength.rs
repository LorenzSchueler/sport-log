use chrono::NaiveDateTime;
use serde::{Deserialize, Serialize};

use sport_log_server_derive::{
    Create, Delete, GetAll, GetById, InnerIntFromSql, InnerIntToSql, Update,
};

#[cfg(feature = "full")]
use crate::schema::{strength_session, strength_set};
use crate::types::{MovementId, MovementUnit, UserId};

#[cfg_attr(
    feature = "full",
    derive(
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
    )
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::Integer")]
pub struct StrengthSessionId(pub i32);

#[cfg_attr(
    feature = "full",
    derive(
        Queryable,
        AsChangeset,
        Serialize,
        Deserialize,
        Debug,
        Create,
        GetById,
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

#[cfg_attr(feature = "full", derive(Insertable, Serialize, Deserialize))]
#[cfg_attr(feature = "full", table_name = "strength_session")]
pub struct NewStrengthSession {
    pub user_id: UserId,
    pub datetime: NaiveDateTime,
    pub movement_id: MovementId,
    pub movement_unit: MovementUnit,
    pub interval: Option<i32>,
    pub comments: Option<String>,
}

#[cfg_attr(
    feature = "full",
    derive(
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
    )
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::Integer")]
pub struct StrengthSetId(pub i32);

#[cfg_attr(
    feature = "full",
    derive(
        Queryable,
        AsChangeset,
        Serialize,
        Deserialize,
        Debug,
        Create,
        GetById,
        GetAll,
        Update,
        Delete,
    )
)]
#[cfg_attr(feature = "full", table_name = "strength_set")]
pub struct StrengthSet {
    pub id: StrengthSetId,
    pub strength_session_id: StrengthSessionId,
    pub count: i32,
    pub weight: Option<f32>,
}

#[cfg_attr(feature = "full", derive(Insertable, Serialize, Deserialize))]
#[cfg_attr(feature = "full", table_name = "strength_set")]
pub struct NewStrengthSet {
    pub strength_session_id: StrengthSessionId,
    pub count: i32,
    pub weight: Option<f32>,
}
