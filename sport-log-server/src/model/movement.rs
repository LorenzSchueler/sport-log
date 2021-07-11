use diesel_derive_enum::DbEnum;
use serde::{Deserialize, Serialize};

#[derive(DbEnum, Debug, Serialize, Deserialize)]
#[allow(non_camel_case_types)]
pub enum MovementCategory {
    Cardio,
    Strength,
}

#[derive(DbEnum, Debug, Serialize, Deserialize)]
#[allow(non_camel_case_types)]
pub enum MovementUnit {
    Reps,
    Cal,
    Meter,
    Km,
    Yard,
    Foot,
    Mile,
}
