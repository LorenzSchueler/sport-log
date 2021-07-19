use chrono::NaiveDateTime;
#[cfg(feature = "full")]
use diesel_derive_enum::DbEnum;
use serde::{Deserialize, Serialize};

#[cfg(feature = "full")]
use sport_log_server_derive::{
    Create, Delete, GetAll, GetById, GetByUser, InnerIntFromSql, InnerIntToSql, Update,
};

#[cfg(feature = "full")]
use crate::schema::{metcon, metcon_movement, metcon_session};
use crate::types::{MovementId, MovementUnit, UserId};

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "full", derive(DbEnum))]
pub enum MetconType {
    Amrap,
    Emom,
    ForTime,
    Ladder,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(
        FromSqlRow,
        AsExpression,
        Copy,
        PartialEq,
        Eq,
        InnerIntToSql,
        InnerIntFromSql,
    )
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::Integer")]
pub struct MetconId(pub i32);

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
#[cfg_attr(feature = "full", table_name = "metcon")]
pub struct Metcon {
    pub id: MetconId,
    pub user_id: UserId,
    pub name: Option<String>,
    pub metcon_type: MetconType,
    pub rounds: Option<i32>,
    pub timecap: Option<i32>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "full", derive(Insertable))]
#[cfg_attr(feature = "full", table_name = "metcon")]
pub struct NewMetcon {
    pub user_id: UserId,
    pub name: Option<String>,
    pub metcon_type: MetconType,
    pub rounds: Option<i32>,
    pub timecap: Option<i32>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(
        FromSqlRow,
        AsExpression,
        Copy,
        PartialEq,
        Eq,
        InnerIntToSql,
        InnerIntFromSql,
    )
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::Integer")]
pub struct MetconMovementId(pub i32);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(Queryable, AsChangeset, Create, GetById, GetAll, Update, Delete,)
)]
#[cfg_attr(feature = "full", table_name = "metcon_movement")]
pub struct MetconMovement {
    pub id: MetconMovementId,
    pub movement_id: MovementId,
    pub metcon_id: MetconId,
    pub count: i32,
    pub unit: MovementUnit,
    pub weight: Option<f32>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "full", derive(Insertable))]
#[cfg_attr(feature = "full", table_name = "metcon_movement")]
pub struct NewMetconMovement {
    pub movement_id: MovementId,
    pub metcon_id: MetconId,
    pub count: i32,
    pub unit: MovementUnit,
    pub weight: Option<f32>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(
        FromSqlRow,
        AsExpression,
        Copy,
        PartialEq,
        Eq,
        InnerIntToSql,
        InnerIntFromSql,
    )
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::Integer")]
pub struct MetconSessionId(pub i32);

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
#[cfg_attr(feature = "full", table_name = "metcon_session")]
pub struct MetconSession {
    pub id: MetconSessionId,
    pub user_id: UserId,
    pub metcon_id: MetconId,
    pub datetime: NaiveDateTime,
    pub time: Option<i32>,
    pub rounds: Option<i32>,
    pub reps: Option<i32>,
    pub rx: bool,
    pub comments: Option<String>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "full", derive(Insertable))]
#[cfg_attr(feature = "full", table_name = "metcon_session")]
pub struct NewMetconSession {
    pub user_id: UserId,
    pub metcon_id: MetconId,
    pub datetime: NaiveDateTime,
    pub time: Option<i32>,
    pub rounds: Option<i32>,
    pub reps: Option<i32>,
    pub rx: bool,
    pub comments: Option<String>,
}
