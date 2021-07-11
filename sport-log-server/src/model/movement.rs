use diesel_derive_enum::DbEnum;
use serde::{Deserialize, Serialize};

#[derive(DbEnum, Debug, Serialize, Deserialize)]
pub enum MovementCategory {
    Cardio,
    Strength,
}
