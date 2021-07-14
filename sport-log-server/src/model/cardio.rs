use std::io::Write;

use chrono::NaiveDateTime;
use diesel::{
    deserialize,
    pg::Pg,
    serialize::{self, Output, WriteTuple},
    sql_types::{Double, Float, Integer},
    types::{FromSql, Record, ToSql},
};
use diesel_derive_enum::DbEnum;
use serde::{Deserialize, Serialize};

use sport_log_server_derive::{Create, Delete, GetAll, GetById, Update};

use crate::{
    model::{MovementId, UserId},
    schema::{cardio_session, route},
};

#[derive(DbEnum, Debug, Serialize, Deserialize)]
pub enum CardioType {
    Training,
    ActiveRecovery,
    Freetime,
}

#[derive(SqlType, Serialize, Deserialize, Debug)]
#[postgres(type_name = "position")]
pub struct Position {
    longitude: f64,
    latitude: f64,
    elevation: f32,
    time: i32,
}

impl ToSql<Position, Pg> for Position {
    fn to_sql<W: Write>(&self, out: &mut Output<W, Pg>) -> serialize::Result {
        WriteTuple::<(Double, Double, Float, Integer)>::write_tuple(
            &(self.longitude, self.latitude, self.elevation, self.time),
            out,
        )
    }
}

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

pub type RouteId = i32;

#[derive(
    Queryable, AsChangeset, Serialize, Deserialize, Debug, Create, GetById, GetAll, Update, Delete,
)]
#[table_name = "route"]
pub struct Route {
    pub id: RouteId,
    pub user_id: UserId,
    pub name: String,
    pub distance: i32,
    pub ascent: Option<i32>,
    pub descent: Option<i32>,
    pub track: Option<Vec<Position>>,
}

#[derive(Insertable, Serialize, Deserialize)]
#[table_name = "route"]
pub struct NewRoute {
    pub user_id: UserId,
    pub name: String,
    pub distance: i32,
    pub ascent: Option<i32>,
    pub descent: Option<i32>,
    pub track: Option<Vec<Position>>,
}

pub type CardioSessionId = i32;

#[derive(
    Queryable, AsChangeset, Serialize, Deserialize, Debug, Create, GetById, GetAll, Update, Delete,
)]
#[table_name = "cardio_session"]
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

#[derive(Insertable, Serialize, Deserialize)]
#[table_name = "cardio_session"]
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
