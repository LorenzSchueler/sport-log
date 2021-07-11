use diesel_derive_enum::DbEnum;
use serde::{Deserialize, Serialize};

#[derive(DbEnum, Debug, Serialize, Deserialize)]
pub enum MetconType {
    Amrap,
    Emom,
    For_time,
    Ladder,
}
