use chrono::{DateTime, Utc};
#[cfg(feature = "db")]
use diesel::{
    backend::Backend,
    deserialize::{self, FromSql},
    pg::Pg,
    serialize::{self, Output, ToSql, WriteTuple},
    sql_types::{BigInt, Double, Integer, Nullable, Record},
};
#[cfg(feature = "db")]
use diesel_derive_enum::DbEnum;
use serde::{Deserialize, Serialize};
use sport_log_types_derive::IdString;
#[cfg(feature = "db")]
use sport_log_types_derive::{IdFromSql, IdToSql};

#[cfg(feature = "db")]
use crate::{
    schema::{cardio_blueprint, cardio_session, route},
    Movement, TrainingPlan, User,
};
use crate::{types::IdString, MovementId, TrainingPlanId, UserId};

#[derive(Serialize, Deserialize, Debug, Clone, Copy, PartialEq, Eq)]
#[cfg_attr(
    feature = "db",
    derive(DbEnum),
    ExistingTypePath = "crate::schema::sql_types::CardioType"
)]
pub enum CardioType {
    Training,
    ActiveRecovery,
    Freetime,
}

/// A GPS position.
///
/// `latitude` and `longitude` are measured in decimal degrees.
///
/// `elevation` is the elevation above sea level in in meter.
///
/// `distance` is the distance in meter since the start of the recording.
///
/// `time` is the time in seconds since the start of the recording.
#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "db",
    derive(FromSqlRow, AsExpression),
    diesel(sql_type = crate::schema::sql_types::Position)
)]
pub struct Position {
    #[serde(rename(serialize = "lo", deserialize = "lo"))]
    pub longitude: f64,
    #[serde(rename(serialize = "la", deserialize = "la"))]
    pub latitude: f64,
    #[serde(rename(serialize = "e", deserialize = "e"))]
    pub elevation: f64,
    #[serde(rename(serialize = "d", deserialize = "d"))]
    pub distance: f64,
    #[serde(rename(serialize = "t", deserialize = "t"))]
    pub time: i32,
}

#[cfg(feature = "db")]
impl ToSql<crate::schema::sql_types::Position, Pg> for Position {
    fn to_sql<'b>(&'b self, out: &mut Output<'b, '_, Pg>) -> serialize::Result {
        WriteTuple::<(Double, Double, Double, Double, Integer)>::write_tuple(
            &(
                self.longitude,
                self.latitude,
                self.elevation,
                self.distance,
                self.time,
            ),
            out,
        )
    }
}

#[cfg(feature = "db")]
impl FromSql<crate::schema::sql_types::Position, Pg> for Position {
    fn from_sql(bytes: <Pg as Backend>::RawValue<'_>) -> deserialize::Result<Self> {
        let (longitude, latitude, elevation, distance, time) =
            FromSql::<Record<(Double, Double, Double, Double, Integer)>, Pg>::from_sql(bytes)?;
        Ok(Position {
            longitude,
            latitude,
            elevation,
            distance,
            time,
        })
    }
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, PartialEq, Eq, IdString)]
#[serde(try_from = "IdString", into = "IdString")]
#[cfg_attr(
    feature = "db",
    derive(Hash, FromSqlRow, AsExpression, IdToSql, IdFromSql),
    diesel(sql_type = BigInt)
)]
pub struct RouteId(pub i64);

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
    diesel(table_name = route, belongs_to(User))
)]
pub struct Route {
    pub id: RouteId,
    pub user_id: UserId,
    pub name: String,
    pub distance: i32,
    #[cfg_attr(features = "db", changeset_options(treat_none_as_null = "true"))]
    pub ascent: Option<i32>,
    #[cfg_attr(features = "db", changeset_options(treat_none_as_null = "true"))]
    pub descent: Option<i32>,
    #[cfg_attr(features = "db", changeset_options(treat_none_as_null = "true"))]
    pub track: Option<Vec<Position>>,
    #[cfg_attr(features = "db", changeset_options(treat_none_as_null = "true"))]
    pub marked_positions: Option<Vec<Position>>,
    pub deleted: bool,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, PartialEq, Eq, IdString)]
#[serde(try_from = "IdString", into = "IdString")]
#[cfg_attr(
    feature = "db",
    derive(Hash, FromSqlRow, AsExpression, IdToSql, IdFromSql),
    diesel(sql_type = BigInt)
)]
pub struct CardioBlueprintId(pub i64);

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
    diesel(table_name = cardio_blueprint, belongs_to(User), belongs_to(TrainingPlan), belongs_to(Movement), belongs_to(Route))
)]
pub struct CardioBlueprint {
    pub id: CardioBlueprintId,
    pub user_id: UserId,
    pub training_plan_id: TrainingPlanId,
    pub name: String,
    #[cfg_attr(features = "db", changeset_options(treat_none_as_null = "true"))]
    pub description: Option<String>,
    pub movement_id: MovementId,
    pub cardio_type: CardioType,
    #[cfg_attr(features = "db", changeset_options(treat_none_as_null = "true"))]
    pub distance: Option<i32>,
    #[cfg_attr(features = "db", changeset_options(treat_none_as_null = "true"))]
    pub ascent: Option<i32>,
    #[cfg_attr(features = "db", changeset_options(treat_none_as_null = "true"))]
    pub descent: Option<i32>,
    #[cfg_attr(features = "db", changeset_options(treat_none_as_null = "true"))]
    pub time: Option<i32>,
    #[cfg_attr(features = "db", changeset_options(treat_none_as_null = "true"))]
    pub calories: Option<i32>,
    #[cfg_attr(features = "db", changeset_options(treat_none_as_null = "true"))]
    pub avg_heart_rate: Option<i32>,
    #[cfg_attr(features = "db", changeset_options(treat_none_as_null = "true"))]
    pub route_id: Option<RouteId>,
    pub deleted: bool,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, PartialEq, Eq, IdString)]
#[serde(try_from = "IdString", into = "IdString")]
#[cfg_attr(
    feature = "db",
    derive(Hash, FromSqlRow, AsExpression, IdToSql, IdFromSql),
    diesel(sql_type = BigInt)
)]
pub struct CardioSessionId(pub i64);

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
    diesel(table_name = cardio_session, belongs_to(User), belongs_to(CardioBlueprint), belongs_to(Movement), belongs_to(Route))
)]
pub struct CardioSession {
    pub id: CardioSessionId,
    pub user_id: UserId,
    pub cardio_blueprint_id: Option<CardioBlueprintId>,
    pub movement_id: MovementId,
    pub cardio_type: CardioType,
    pub datetime: DateTime<Utc>,
    #[cfg_attr(features = "db", changeset_options(treat_none_as_null = "true"))]
    pub distance: Option<i32>,
    #[cfg_attr(features = "db", changeset_options(treat_none_as_null = "true"))]
    pub ascent: Option<i32>,
    #[cfg_attr(features = "db", changeset_options(treat_none_as_null = "true"))]
    pub descent: Option<i32>,
    #[cfg_attr(features = "db", changeset_options(treat_none_as_null = "true"))]
    pub time: Option<i32>,
    #[cfg_attr(features = "db", changeset_options(treat_none_as_null = "true"))]
    pub calories: Option<i32>,
    #[cfg_attr(features = "db", changeset_options(treat_none_as_null = "true"))]
    pub track: Option<Vec<Position>>,
    #[cfg_attr(features = "db", changeset_options(treat_none_as_null = "true"))]
    pub avg_cadence: Option<i32>,
    #[cfg_attr(features = "db", changeset_options(treat_none_as_null = "true"))]
    pub cadence: Option<Vec<i32>>,
    #[cfg_attr(features = "db", changeset_options(treat_none_as_null = "true"))]
    pub avg_heart_rate: Option<i32>,
    #[cfg_attr(features = "db", changeset_options(treat_none_as_null = "true"))]
    pub heart_rate: Option<Vec<i32>>,
    #[cfg_attr(features = "db", changeset_options(treat_none_as_null = "true"))]
    pub route_id: Option<RouteId>,
    #[cfg_attr(features = "db", changeset_options(treat_none_as_null = "true"))]
    pub comments: Option<String>,
    pub deleted: bool,
}
