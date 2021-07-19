#[cfg(feature = "full")]
use diesel_derive_enum::DbEnum;
use serde::{Deserialize, Serialize};

#[cfg(feature = "full")]
use sport_log_server_derive::{
    Create, Delete, GetAll, GetById, GetByUser, InnerIntFromSql, InnerIntToSql, Update,
};

#[cfg(feature = "full")]
use crate::schema::{eorm, movement};
use crate::types::UserId;

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "full", derive(DbEnum))]
pub enum MovementCategory {
    Cardio,
    Strength,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "full", derive(DbEnum))]
pub enum MovementUnit {
    Reps,
    Cal,
    Meter,
    Km,
    Yard,
    Foot,
    Mile,
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
pub struct MovementId(pub i32);

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
#[cfg_attr(feature = "full", table_name = "movement")]
pub struct Movement {
    pub id: MovementId,
    pub user_id: UserId,
    pub name: String,
    pub description: Option<String>,
    pub category: MovementCategory,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "full", derive(Insertable))]
#[cfg_attr(feature = "full", table_name = "movement")]
pub struct NewMovement {
    pub user_id: UserId,
    pub name: String,
    pub description: Option<String>,
    pub category: MovementCategory,
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
pub struct EormId(pub i32);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(Queryable, AsChangeset, Create, GetById, GetAll, Update, Delete,)
)]
#[cfg_attr(feature = "full", table_name = "eorm")]
pub struct Eorm {
    pub id: EormId,
    pub reps: i32,
    pub percentage: f32,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "full", derive(Insertable))]
#[cfg_attr(feature = "full", table_name = "eorm")]
pub struct NewEorm {
    pub reps: i32,
    pub percentage: f32,
}
