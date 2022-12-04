#[cfg(feature = "server")]
use std::io::Write;

use chrono::{DateTime, Utc};
#[cfg(feature = "server")]
use diesel::{
    deserialize,
    pg::Pg,
    serialize::{self, Output, WriteTuple},
    sql_types::{Double, Integer},
    types::{FromSql, Record, ToSql},
};
#[cfg(feature = "server")]
use diesel_derive_enum::DbEnum;
use serde::{Deserialize, Serialize};

#[cfg(feature = "server")]
use sport_log_types_derive::{
    CheckUserId, Create, CreateMultiple, FromSql, GetById, GetByIds, GetByUser, GetByUserSync,
    HardDelete, ToSql, Update, VerifyForUserOrAPWithDb, VerifyForUserOrAPWithoutDb,
    VerifyIdForUserOrAP,
};
use sport_log_types_derive::{FromI64, ToI64};

use crate::{
    from_str, from_str_optional, to_str, to_str_optional, Movement, MovementId, TrainingPlanId,
    UserId,
};
#[cfg(feature = "server")]
use crate::{
    schema::{cardio_blueprint, cardio_session, route},
    TrainingPlan, User,
};

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq)]
#[cfg_attr(feature = "server", derive(DbEnum))]
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
#[cfg_attr(feature = "server", derive(SqlType,))]
#[cfg_attr(feature = "server", postgres(type_name = "position"))]
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

#[cfg(feature = "server")]
impl ToSql<Position, Pg> for Position {
    fn to_sql<W: Write>(&self, out: &mut Output<W, Pg>) -> serialize::Result {
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

#[cfg(feature = "server")]
impl FromSql<Position, Pg> for Position {
    fn from_sql(bytes: Option<&[u8]>) -> deserialize::Result<Self> {
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

#[derive(
    Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq, PartialOrd, Ord, FromI64, ToI64,
)]
#[cfg_attr(
    feature = "server",
    derive(Hash, FromSqlRow, AsExpression, ToSql, FromSql, VerifyIdForUserOrAP)
)]
#[cfg_attr(feature = "server", sql_type = "diesel::sql_types::BigInt")]
pub struct RouteId(pub i64);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "server",
    derive(
        Insertable,
        Associations,
        Identifiable,
        Queryable,
        AsChangeset,
        Create,
        CreateMultiple,
        GetById,
        GetByIds,
        GetByUser,
        GetByUserSync,
        Update,
        HardDelete,
        CheckUserId,
        VerifyForUserOrAPWithDb,
        VerifyForUserOrAPWithoutDb
    )
)]
#[cfg_attr(feature = "server", table_name = "route")]
#[cfg_attr(feature = "server", belongs_to(User))]
pub struct Route {
    #[serde(serialize_with = "to_str")]
    #[serde(deserialize_with = "from_str")]
    pub id: RouteId,
    #[serde(serialize_with = "to_str")]
    #[serde(deserialize_with = "from_str")]
    pub user_id: UserId,
    pub name: String,
    pub distance: i32,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub ascent: Option<i32>,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub descent: Option<i32>,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub track: Option<Vec<Position>>,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub marked_positions: Option<Vec<Position>>,
    #[serde(skip)]
    #[serde(default = "Utc::now")]
    pub last_change: DateTime<Utc>,
    pub deleted: bool,
}

#[derive(
    Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq, PartialOrd, Ord, FromI64, ToI64,
)]
#[cfg_attr(
    feature = "server",
    derive(Hash, FromSqlRow, AsExpression, ToSql, FromSql, VerifyIdForUserOrAP)
)]
#[cfg_attr(feature = "server", sql_type = "diesel::sql_types::BigInt")]
pub struct CardioBlueprintId(pub i64);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "server",
    derive(
        Insertable,
        Associations,
        Identifiable,
        Queryable,
        AsChangeset,
        Create,
        CreateMultiple,
        GetById,
        GetByIds,
        GetByUser,
        GetByUserSync,
        Update,
        HardDelete,
        VerifyForUserOrAPWithDb,
        VerifyForUserOrAPWithoutDb
    )
)]
#[cfg_attr(feature = "server", table_name = "cardio_blueprint")]
#[cfg_attr(feature = "server", belongs_to(User))]
#[cfg_attr(feature = "server", belongs_to(TrainingPlan))]
#[cfg_attr(feature = "server", belongs_to(Movement))]
#[cfg_attr(feature = "server", belongs_to(Route))]
pub struct CardioBlueprint {
    #[serde(serialize_with = "to_str")]
    #[serde(deserialize_with = "from_str")]
    pub id: CardioBlueprintId,
    #[serde(serialize_with = "to_str")]
    #[serde(deserialize_with = "from_str")]
    pub user_id: UserId,
    #[serde(serialize_with = "to_str")]
    #[serde(deserialize_with = "from_str")]
    pub training_plan_id: TrainingPlanId,
    pub name: String,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub description: Option<String>,
    #[serde(serialize_with = "to_str")]
    #[serde(deserialize_with = "from_str")]
    pub movement_id: MovementId,
    pub cardio_type: CardioType,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub distance: Option<i32>,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub ascent: Option<i32>,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub descent: Option<i32>,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub time: Option<i32>,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub calories: Option<i32>,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub avg_heart_rate: Option<i32>,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    #[serde(serialize_with = "to_str_optional")]
    #[serde(deserialize_with = "from_str_optional")]
    pub route_id: Option<RouteId>,
    #[serde(skip)]
    #[serde(default = "Utc::now")]
    pub last_change: DateTime<Utc>,
    pub deleted: bool,
}

#[derive(
    Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq, PartialOrd, Ord, FromI64, ToI64,
)]
#[cfg_attr(
    feature = "server",
    derive(Hash, FromSqlRow, AsExpression, ToSql, FromSql, VerifyIdForUserOrAP)
)]
#[cfg_attr(feature = "server", sql_type = "diesel::sql_types::BigInt")]
pub struct CardioSessionId(pub i64);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "server",
    derive(
        Insertable,
        Associations,
        Identifiable,
        Queryable,
        AsChangeset,
        Create,
        CreateMultiple,
        GetById,
        GetByIds,
        GetByUser,
        GetByUserSync,
        Update,
        HardDelete,
        VerifyForUserOrAPWithDb,
        VerifyForUserOrAPWithoutDb
    )
)]
#[cfg_attr(feature = "server", table_name = "cardio_session")]
#[cfg_attr(feature = "server", belongs_to(User))]
#[cfg_attr(feature = "server", belongs_to(CardioBlueprint))]
#[cfg_attr(feature = "server", belongs_to(Movement))]
#[cfg_attr(feature = "server", belongs_to(Route))]
pub struct CardioSession {
    #[serde(serialize_with = "to_str")]
    #[serde(deserialize_with = "from_str")]
    pub id: CardioSessionId,
    #[serde(serialize_with = "to_str")]
    #[serde(deserialize_with = "from_str")]
    pub user_id: UserId,
    #[serde(serialize_with = "to_str_optional")]
    #[serde(deserialize_with = "from_str_optional")]
    pub cardio_blueprint_id: Option<CardioBlueprintId>,
    #[serde(serialize_with = "to_str")]
    #[serde(deserialize_with = "from_str")]
    pub movement_id: MovementId,
    pub cardio_type: CardioType,
    pub datetime: DateTime<Utc>,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub distance: Option<i32>,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub ascent: Option<i32>,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub descent: Option<i32>,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub time: Option<i32>,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub calories: Option<i32>,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub track: Option<Vec<Position>>,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub avg_cadence: Option<i32>,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub cadence: Option<Vec<i32>>,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub avg_heart_rate: Option<i32>,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub heart_rate: Option<Vec<i32>>,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    #[serde(serialize_with = "to_str_optional")]
    #[serde(deserialize_with = "from_str_optional")]
    pub route_id: Option<RouteId>,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub comments: Option<String>,
    #[serde(skip)]
    #[serde(default = "Utc::now")]
    pub last_change: DateTime<Utc>,
    pub deleted: bool,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct CardioSessionDescription {
    pub cardio_session: CardioSession,
    pub route: Option<Route>,
    pub movement: Movement,
}
