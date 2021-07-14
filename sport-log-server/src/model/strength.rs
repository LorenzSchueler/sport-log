use chrono::NaiveDateTime;
use serde::{Deserialize, Serialize};

use sport_log_server_derive::{Create, Delete, GetAll, GetById, Update};

use crate::{
    model::{MovementId, MovementUnit, UserId},
    schema::{strength_session, strength_set},
};

pub type StrengthSessionId = i32;

#[derive(
    Queryable, AsChangeset, Serialize, Deserialize, Debug, Create, GetById, GetAll, Update, Delete,
)]
#[table_name = "strength_session"]
pub struct StrengthSession {
    pub id: StrengthSessionId,
    pub user_id: UserId,
    pub datetime: NaiveDateTime,
    pub movement_id: MovementId,
    pub movement_unit: MovementUnit,
    pub interval: Option<i32>,
    pub comments: Option<String>,
}

#[derive(Insertable, Serialize, Deserialize)]
#[table_name = "strength_session"]
pub struct NewStrengthSession {
    pub user_id: UserId,
    pub datetime: NaiveDateTime,
    pub movement_id: MovementId,
    pub movement_unit: MovementUnit,
    pub interval: Option<i32>,
    pub comments: Option<String>,
}

pub type StrengthSetId = i32;

#[derive(
    Queryable, AsChangeset, Serialize, Deserialize, Debug, Create, GetById, GetAll, Update, Delete,
)]
#[table_name = "strength_set"]
pub struct StrengthSet {
    pub id: StrengthSetId,
    pub strength_session_id: StrengthSessionId,
    pub count: i32,
    pub weight: Option<f32>,
}

#[derive(Insertable, Serialize, Deserialize)]
#[table_name = "strength_set"]
pub struct NewStrengthSet {
    pub strength_session_id: StrengthSessionId,
    pub count: i32,
    pub weight: Option<f32>,
}
