use diesel_derive_enum::DbEnum;
use serde::{Deserialize, Serialize};

use sport_log_server_derive::{
    Create, Delete, GetAll, GetById, InnerIntFromSql, InnerIntToSql, Update,
};

#[cfg(feature = "full")]
use crate::schema::{eorm, movement};
use crate::types::UserId;

#[cfg_attr(feature = "full", derive(DbEnum, Debug, Serialize, Deserialize))]
pub enum MovementCategory {
    Cardio,
    Strength,
}

#[cfg_attr(feature = "full", derive(DbEnum, Debug, Serialize, Deserialize))]
pub enum MovementUnit {
    Reps,
    Cal,
    Meter,
    Km,
    Yard,
    Foot,
    Mile,
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
pub struct MovementId(pub i32);

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
#[cfg_attr(feature = "full", table_name = "movement")]
pub struct Movement {
    pub id: MovementId,
    pub user_id: UserId,
    pub name: String,
    pub description: Option<String>,
    pub category: MovementCategory,
}

#[cfg_attr(feature = "full", derive(Insertable, Serialize, Deserialize))]
#[cfg_attr(feature = "full", table_name = "movement")]
pub struct NewMovement {
    pub user_id: UserId,
    pub name: String,
    pub description: Option<String>,
    pub category: MovementCategory,
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
pub struct EormId(pub i32);

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
#[cfg_attr(feature = "full", table_name = "eorm")]
pub struct Eorm {
    pub id: EormId,
    pub reps: i32,
    pub percentage: f32,
}

#[cfg_attr(feature = "full", derive(Insertable, Serialize, Deserialize))]
#[cfg_attr(feature = "full", table_name = "eorm")]
pub struct NewEorm {
    pub reps: i32,
    pub percentage: f32,
}
