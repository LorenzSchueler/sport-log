use diesel_derive_enum::DbEnum;
use serde::{Deserialize, Serialize};

#[derive(DbEnum, Debug, Serialize, Deserialize)]
#[allow(non_camel_case_types)]
pub enum MovementCategory {
    cardio,
    strength,
}

#[derive(DbEnum, Debug, Serialize, Deserialize)]
#[allow(non_camel_case_types)]
pub enum MovementUnit {
    reps,
    cal,
    m,
    km,
    yard,
    foot,
    mile,
}
