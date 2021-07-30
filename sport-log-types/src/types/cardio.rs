#[cfg(feature = "full")]
use std::io::Write;

use chrono::NaiveDateTime;
#[cfg(feature = "full")]
use diesel::{
    deserialize,
    pg::Pg,
    serialize::{self, Output, WriteTuple},
    sql_types::{Double, Float, Integer},
    types::{FromSql, Record, ToSql},
};
#[cfg(feature = "full")]
use diesel_derive_enum::DbEnum;
use serde::{Deserialize, Serialize};

#[cfg(feature = "full")]
use sport_log_types_derive::{
    Create, CreateMultiple, Delete, DeleteMultiple, FromI32, FromSql, GetAll, GetById, GetByUser,
    ToSql, Update, VerifyForUserWithDb, VerifyForUserWithoutDb, VerifyIdForUser,
};

#[cfg(feature = "full")]
use crate::{
    schema::{cardio_session, route},
    User,
};
use crate::{Movement, MovementId, UserId};

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq)]
#[cfg_attr(feature = "full", derive(DbEnum))]
pub enum CardioType {
    Training,
    ActiveRecovery,
    Freetime,
}

/// A GPS position.
///
/// `time` is the time in seconds since the start of the recording.
#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "full", derive(SqlType,))]
#[cfg_attr(feature = "full", postgres(type_name = "position"))]
pub struct Position {
    pub longitude: f64,
    pub latitude: f64,
    pub elevation: f32,
    pub time: i32,
}

#[cfg(feature = "full")]
impl ToSql<Position, Pg> for Position {
    fn to_sql<W: Write>(&self, out: &mut Output<W, Pg>) -> serialize::Result {
        WriteTuple::<(Double, Double, Float, Integer)>::write_tuple(
            &(self.longitude, self.latitude, self.elevation, self.time),
            out,
        )
    }
}

#[cfg(feature = "full")]
impl FromSql<Position, Pg> for Position {
    fn from_sql(bytes: Option<&[u8]>) -> deserialize::Result<Self> {
        let (longitude, latitude, elevation, time) =
            FromSql::<Record<(Double, Double, Float, Integer)>, Pg>::from_sql(bytes)?;
        Ok(Position {
            longitude,
            latitude,
            elevation,
            time,
        })
    }
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq)]
#[cfg_attr(
    feature = "full",
    derive(
        Hash,
        FromSqlRow,
        AsExpression,
        FromI32,
        ToSql,
        FromSql,
        VerifyIdForUser
    )
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::Integer")]
pub struct RouteId(pub i32);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(
        Associations,
        Identifiable,
        Queryable,
        AsChangeset,
        Create,
        CreateMultiple,
        GetById,
        GetByUser,
        GetAll,
        Update,
        Delete,
        DeleteMultiple,
        VerifyForUserWithDb
    )
)]
#[cfg_attr(feature = "full", table_name = "route")]
#[cfg_attr(feature = "full", belongs_to(User))]
pub struct Route {
    pub id: RouteId,
    pub user_id: UserId,
    pub name: String,
    pub distance: i32,
    #[cfg_attr(features = "full", changeset_options(treat_none_as_null = "true"))]
    pub ascent: Option<i32>,
    #[cfg_attr(features = "full", changeset_options(treat_none_as_null = "true"))]
    pub descent: Option<i32>,
    #[cfg_attr(features = "full", changeset_options(treat_none_as_null = "true"))]
    pub track: Option<Vec<Position>>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "full", derive(Insertable, VerifyForUserWithoutDb))]
#[cfg_attr(feature = "full", table_name = "route")]
pub struct NewRoute {
    pub user_id: UserId,
    pub name: String,
    pub distance: i32,
    pub ascent: Option<i32>,
    pub descent: Option<i32>,
    pub track: Option<Vec<Position>>,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq)]
#[cfg_attr(
    feature = "full",
    derive(
        Hash,
        FromSqlRow,
        AsExpression,
        FromI32,
        ToSql,
        FromSql,
        VerifyIdForUser
    )
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::Integer")]
pub struct CardioSessionId(pub i32);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(
        Associations,
        Identifiable,
        Queryable,
        AsChangeset,
        Create,
        CreateMultiple,
        GetById,
        GetByUser,
        GetAll,
        Update,
        Delete,
        DeleteMultiple,
        VerifyForUserWithDb
    )
)]
#[cfg_attr(feature = "full", table_name = "cardio_session")]
#[cfg_attr(feature = "full", belongs_to(User))]
#[cfg_attr(feature = "full", belongs_to(Movement))]
pub struct CardioSession {
    pub id: CardioSessionId,
    pub user_id: UserId,
    pub movement_id: MovementId,
    pub cardio_type: CardioType,
    pub datetime: NaiveDateTime,
    #[cfg_attr(features = "full", changeset_options(treat_none_as_null = "true"))]
    pub distance: Option<i32>,
    #[cfg_attr(features = "full", changeset_options(treat_none_as_null = "true"))]
    pub ascent: Option<i32>,
    #[cfg_attr(features = "full", changeset_options(treat_none_as_null = "true"))]
    pub descent: Option<i32>,
    #[cfg_attr(features = "full", changeset_options(treat_none_as_null = "true"))]
    pub time: Option<i32>,
    #[cfg_attr(features = "full", changeset_options(treat_none_as_null = "true"))]
    pub calories: Option<i32>,
    #[cfg_attr(features = "full", changeset_options(treat_none_as_null = "true"))]
    pub track: Option<Vec<Position>>,
    #[cfg_attr(features = "full", changeset_options(treat_none_as_null = "true"))]
    pub avg_cycles: Option<i32>,
    #[cfg_attr(features = "full", changeset_options(treat_none_as_null = "true"))]
    pub cycles: Option<Vec<f32>>,
    #[cfg_attr(features = "full", changeset_options(treat_none_as_null = "true"))]
    pub avg_heart_rate: Option<i32>,
    #[cfg_attr(features = "full", changeset_options(treat_none_as_null = "true"))]
    pub heart_rate: Option<Vec<f32>>,
    #[cfg_attr(features = "full", changeset_options(treat_none_as_null = "true"))]
    pub route_id: Option<RouteId>,
    #[cfg_attr(features = "full", changeset_options(treat_none_as_null = "true"))]
    pub comments: Option<String>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "full", derive(Insertable, VerifyForUserWithoutDb))]
#[cfg_attr(feature = "full", table_name = "cardio_session")]
pub struct NewCardioSession {
    pub user_id: UserId,
    pub movement_id: MovementId,
    pub cardio_type: CardioType,
    pub datetime: NaiveDateTime,
    pub distance: Option<i32>,
    pub ascent: Option<i32>,
    pub descent: Option<i32>,
    pub time: Option<i32>,
    pub calories: Option<i32>,
    pub track: Option<Vec<Position>>,
    pub avg_cycles: Option<i32>,
    pub cycles: Option<Vec<f32>>,
    pub avg_heart_rate: Option<i32>,
    pub heart_rate: Option<Vec<f32>>,
    pub route_id: Option<RouteId>,
    pub comments: Option<String>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct CardioSessionDescription {
    pub cardio_session: CardioSession,
    pub route: Option<Route>,
    pub movement: Movement,
}
