use diesel_derive_enum::DbEnum;
use serde::{Deserialize, Serialize};

#[derive(DbEnum, Debug, Serialize, Deserialize)]
#[allow(non_camel_case_types)]
pub enum MetconType {
    amrap,
    emom,
    for_time,
    ladder,
}
