use chrono::NaiveDateTime;
use diesel_derive_enum::DbEnum;
use serde::{Deserialize, Serialize};

use sport_log_server_derive::{Create, Delete, GetAll, GetById, Update};

use crate::{
    model::{MovementId, MovementUnit, UserId},
    schema::{metcon, metcon_movement, metcon_session},
};

#[derive(DbEnum, Debug, Serialize, Deserialize)]
pub enum MetconType {
    Amrap,
    Emom,
    ForTime,
    Ladder,
}

pub type MetconId = i32;

#[derive(
    Queryable, AsChangeset, Serialize, Deserialize, Debug, Create, GetById, GetAll, Update, Delete,
)]
#[table_name = "metcon"]
pub struct Metcon {
    pub id: MetconId,
    pub user_id: UserId,
    pub name: Option<String>,
    pub metcon_type: MetconType,
    pub rounds: Option<i32>,
    pub timecap: Option<i32>,
}

#[derive(Insertable, Serialize, Deserialize)]
#[table_name = "metcon"]
pub struct NewMetcon {
    pub user_id: UserId,
    pub name: Option<String>,
    pub metcon_type: MetconType,
    pub rounds: Option<i32>,
    pub timecap: Option<i32>,
}

pub type MetconMovementId = i32;

#[derive(
    Queryable, AsChangeset, Serialize, Deserialize, Debug, Create, GetById, GetAll, Update, Delete,
)]
#[table_name = "metcon_movement"]
pub struct MetconMovement {
    pub id: MetconMovementId,
    pub movement_id: MovementId,
    pub metcon_id: MetconId,
    pub count: i32,
    pub unit: MovementUnit,
    pub weight: Option<f32>,
}

#[derive(Insertable, Serialize, Deserialize)]
#[table_name = "metcon_movement"]
pub struct NewMetconMovement {
    pub movement_id: MovementId,
    pub metcon_id: MetconId,
    pub count: i32,
    pub unit: MovementUnit,
    pub weight: Option<f32>,
}

pub type MetconSessionId = i32;

#[derive(
    Queryable, AsChangeset, Serialize, Deserialize, Debug, Create, GetById, GetAll, Update, Delete,
)]
#[table_name = "metcon_session"]
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

#[derive(Insertable, Serialize, Deserialize)]
#[table_name = "metcon_session"]
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
