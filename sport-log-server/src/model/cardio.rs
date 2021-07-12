use diesel_derive_enum::DbEnum;
use serde::{Deserialize, Serialize};

#[derive(DbEnum, Debug, Serialize, Deserialize)]
pub enum CardioType {
    Training,
    ActiveRecovery,
    Freetime,
}

#[derive(SqlType, Serialize, Deserialize, Debug)]
pub struct Position {
    longitude: f64,
    latitude: f64,
    elevation: f64,
    time: i32,
}
