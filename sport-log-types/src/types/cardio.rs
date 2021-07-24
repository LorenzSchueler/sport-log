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
use sport_log_server_derive::{
    Create, Delete, FromI32, FromSql, GetAll, GetById, GetByUser, ToSql, Update,
    VerifyForUserWithDb, VerifyForUserWithoutDb, VerifyIdForUser,
};

#[cfg(feature = "full")]
use crate::schema::{cardio_session, route};
use crate::types::{MovementId, UserId};

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "full", derive(DbEnum))]
pub enum CardioType {
    Training,
    ActiveRecovery,
    Freetime,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "full", derive(SqlType,))]
#[cfg_attr(feature = "full", postgres(type_name = "position"))]
pub struct Position {
    longitude: f64,
    latitude: f64,
    elevation: f32,
    time: i32,
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

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(
        FromSqlRow,
        AsExpression,
        Copy,
        PartialEq,
        Eq,
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
        Queryable,
        AsChangeset,
        Create,
        GetById,
        GetByUser,
        GetAll,
        Update,
        Delete,
        VerifyForUserWithDb
    )
)]
#[cfg_attr(feature = "full", table_name = "route")]
pub struct Route {
    pub id: RouteId,
    pub user_id: UserId,
    pub name: String,
    pub distance: i32,
    pub ascent: Option<i32>,
    pub descent: Option<i32>,
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

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(
        FromSqlRow,
        AsExpression,
        Copy,
        PartialEq,
        Eq,
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
        Queryable,
        AsChangeset,
        Create,
        GetById,
        GetByUser,
        GetAll,
        Update,
        Delete,
        VerifyForUserWithDb
    )
)]
#[cfg_attr(feature = "full", table_name = "cardio_session")]
pub struct CardioSession {
    pub id: CardioSessionId,
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
