use diesel_derive_enum::DbEnum;
use serde::{Deserialize, Serialize};

use sport_log_server_derive::{Create, Delete, GetAll, GetById, Update};

use crate::{
    model::UserId,
    schema::{eorm, movement},
};

#[derive(DbEnum, Debug, Serialize, Deserialize)]
pub enum MovementCategory {
    Cardio,
    Strength,
}

#[derive(DbEnum, Debug, Serialize, Deserialize)]
pub enum MovementUnit {
    Reps,
    Cal,
    Meter,
    Km,
    Yard,
    Foot,
    Mile,
}

pub type MovementId = i32;

#[derive(
    Queryable, AsChangeset, Serialize, Deserialize, Debug, Create, GetById, GetAll, Update, Delete,
)]
#[table_name = "movement"]
pub struct Movement {
    pub id: MovementId,
    pub user_id: UserId,
    pub name: String,
    pub description: Option<String>,
    pub category: MovementCategory,
}

#[derive(Insertable, Serialize, Deserialize)]
#[table_name = "movement"]
pub struct NewMovement {
    pub user_id: UserId,
    pub name: String,
    pub description: Option<String>,
    pub category: MovementCategory,
}

pub type EormId = i32;

#[derive(
    Queryable, AsChangeset, Serialize, Deserialize, Debug, Create, GetById, GetAll, Update, Delete,
)]
#[table_name = "eorm"]
pub struct Eorm {
    pub id: EormId,
    pub reps: i32,
    pub percentage: f32,
}

#[derive(Insertable, Serialize, Deserialize)]
#[table_name = "eorm"]
pub struct NewEorm {
    pub reps: i32,
    pub percentage: f32,
}
