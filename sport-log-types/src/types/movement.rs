use derive_deftly::Deftly;
#[cfg(feature = "db")]
use diesel::{deserialize::FromSqlRow, expression::AsExpression, prelude::*, sql_types::BigInt};
#[cfg(feature = "db")]
use diesel_derive_enum::DbEnum;
use serde::{Deserialize, Serialize};

#[cfg(feature = "db")]
use crate::{schema::movement, User};
use crate::{types::IdString, UserId};

#[derive(Serialize, Deserialize, Debug, Clone, Copy, PartialEq, Eq)]
#[cfg_attr(
    feature = "db",
    derive(DbEnum),
    ExistingTypePath = "crate::schema::sql_types::MovementDimension"
)]
pub enum MovementDimension {
    Reps,
    Time,
    Energy,
    Distance,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Deftly)]
#[derive_deftly(IdString)]
#[serde(try_from = "IdString", into = "IdString")]
#[cfg_attr(
    feature = "db",
    derive(Hash, FromSqlRow, AsExpression),
    derive_deftly(IntoPgBigInt, FromPgBigInt),
    diesel(sql_type = BigInt)
)]
pub struct MovementId(pub i64);

/// [`Movement`]
///
/// Movements can be predefined (`user_id` is [`None`]) or can be user-defined (`user_id` contains
/// the id of the user).
///
/// `categories` decides whether the Movement can be used in Cardio or Strength Sessions or both.
/// For Metcons the `categories` does not matter.
#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "db",
    derive(
        Insertable,
        Associations,
        Identifiable,
        Queryable,
        Selectable,
        AsChangeset,
    ),
    diesel(table_name = movement, belongs_to(User))
)]
pub struct Movement {
    pub id: MovementId,
    #[cfg_attr(feature = "db", diesel(treat_none_as_null = true))]
    pub user_id: Option<UserId>,
    pub name: String,
    #[cfg_attr(feature = "db", diesel(treat_none_as_null = true))]
    pub description: Option<String>,
    pub movement_dimension: MovementDimension,
    pub cardio: bool,
    pub deleted: bool,
}
