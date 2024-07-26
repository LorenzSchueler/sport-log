use chrono::{DateTime, Utc};
use derive_deftly::Deftly;
#[cfg(feature = "db")]
use diesel::{deserialize::FromSqlRow, expression::AsExpression, prelude::*, sql_types::BigInt};
#[cfg(feature = "db")]
use diesel_derive_enum::DbEnum;
use serde::{Deserialize, Serialize};

#[cfg(feature = "db")]
use crate::{
    schema::{metcon, metcon_movement, metcon_session},
    Movement, User,
};
use crate::{types::IdString, MovementId, UserId};

#[derive(Serialize, Deserialize, Debug, Clone, Copy, PartialEq, Eq)]
#[cfg_attr(
    feature = "db",
    derive(DbEnum),
    ExistingTypePath = "crate::schema::sql_types::MetconType"
)]
pub enum MetconType {
    Amrap,
    Emom,
    ForTime,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, PartialEq, Eq)]
#[cfg_attr(
    feature = "db",
    derive(DbEnum),
    ExistingTypePath = "crate::schema::sql_types::DistanceUnit"
)]
pub enum DistanceUnit {
    Meter,
    Km,
    Yard,
    Foot,
    Mile,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Deftly)]
#[derive_deftly(IdString)]
#[serde(try_from = "IdString", into = "IdString")]
#[cfg_attr(
    feature = "db",
    derive(Hash, FromSqlRow, AsExpression),
    derive_deftly(IdToSql, IdFromSql),
    diesel(sql_type = BigInt)
)]
pub struct MetconId(pub i64);

/// [`Metcon`] acts like a template for a [`MetconSession`].
///
/// Metcons can be predefined (`user_id` is [`None`]) or can be user-defined (`user_id` contains the
/// id of the user).
///
/// If `metcon_type` is [`MetconType::Amrap`] `rounds` should be `None` and `timecap` should be set.
///
/// If `metcon_type` is [`MetconType::Emom`] rounds and timecap should be set (rounds determines how
/// many rounds should be performed and `timecap`/`rounds` determines how long each round takes).
///
/// If `metcon_type` is [`MetconType::ForTime`] `rounds` should be set and `timecap` can be None or
/// have a value.
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
    diesel(table_name = metcon, belongs_to(User))
)]
pub struct Metcon {
    pub id: MetconId,
    #[cfg_attr(feature = "db", diesel(treat_none_as_null = true))]
    pub user_id: Option<UserId>,
    pub name: String,
    pub metcon_type: MetconType,
    #[cfg_attr(feature = "db", diesel(treat_none_as_null = true))]
    pub rounds: Option<i32>,
    #[cfg_attr(feature = "db", diesel(treat_none_as_null = true))]
    pub timecap: Option<i32>,
    #[cfg_attr(feature = "db", diesel(treat_none_as_null = true))]
    pub description: Option<String>,
    pub deleted: bool,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, PartialEq, Eq, Deftly)]
#[derive_deftly(IdString)]
#[serde(try_from = "IdString", into = "IdString")]
#[cfg_attr(
    feature = "db",
    derive(Hash, FromSqlRow, AsExpression),
    derive_deftly(IdToSql, IdFromSql),
    diesel(sql_type = BigInt)
)]
pub struct MetconMovementId(pub i64);

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
    diesel(table_name = metcon_movement, belongs_to(Movement), belongs_to(Metcon))
)]
pub struct MetconMovement {
    pub id: MetconMovementId,
    pub metcon_id: MetconId,
    pub movement_id: MovementId,
    pub distance_unit: Option<DistanceUnit>,
    pub movement_number: i32,
    pub count: i32,
    #[cfg_attr(feature = "db", diesel(treat_none_as_null = true))]
    pub male_weight: Option<f32>,
    #[cfg_attr(feature = "db", diesel(treat_none_as_null = true))]
    pub female_weight: Option<f32>,
    pub deleted: bool,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, PartialEq, Eq, Deftly)]
#[derive_deftly(IdString)]
#[serde(try_from = "IdString", into = "IdString")]
#[cfg_attr(
    feature = "db",
    derive(Hash, FromSqlRow, AsExpression),
    derive_deftly(IdToSql, IdFromSql),
    diesel(sql_type = BigInt)
)]
pub struct MetconSessionId(pub i64);

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
    diesel(table_name = metcon_session, belongs_to(User), belongs_to(Metcon))
)]
pub struct MetconSession {
    pub id: MetconSessionId,
    pub user_id: UserId,
    pub metcon_id: MetconId,
    pub datetime: DateTime<Utc>,
    #[cfg_attr(feature = "db", diesel(treat_none_as_null = true))]
    pub time: Option<i32>,
    #[cfg_attr(feature = "db", diesel(treat_none_as_null = true))]
    pub rounds: Option<i32>,
    #[cfg_attr(feature = "db", diesel(treat_none_as_null = true))]
    pub reps: Option<i32>,
    pub rx: bool,
    #[cfg_attr(feature = "db", diesel(treat_none_as_null = true))]
    pub comments: Option<String>,
    pub deleted: bool,
}
