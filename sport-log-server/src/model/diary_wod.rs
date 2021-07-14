use chrono::{NaiveDate, NaiveDateTime};
use serde::{Deserialize, Serialize};

use sport_log_server_derive::{Create, Delete, GetAll, GetById, Update};

use crate::{
    model::UserId,
    schema::{diary, wod},
};

pub type DiaryId = i32;

#[derive(
    Queryable, AsChangeset, Serialize, Deserialize, Debug, Create, GetById, GetAll, Update, Delete,
)]
#[table_name = "diary"]
pub struct Diary {
    pub id: DiaryId,
    pub user_id: UserId,
    pub date: NaiveDate,
    pub bodyweight: Option<f32>,
    pub comments: Option<String>,
}

#[derive(Insertable, Serialize, Deserialize)]
#[table_name = "diary"]
pub struct NewDiary {
    pub user_id: UserId,
    pub date: NaiveDate,
    pub bodyweight: Option<f32>,
    pub comments: Option<String>,
}

pub type WodId = i32;

#[derive(
    Queryable, AsChangeset, Serialize, Deserialize, Debug, Create, GetById, GetAll, Update, Delete,
)]
#[table_name = "wod"]
pub struct Wod {
    pub id: DiaryId,
    pub user_id: UserId,
    pub datetime: NaiveDateTime,
    pub description: Option<String>,
}

#[derive(Insertable, Serialize, Deserialize)]
#[table_name = "wod"]
pub struct NewWod {
    pub user_id: UserId,
    pub datetime: NaiveDateTime,
    pub description: Option<String>,
}
