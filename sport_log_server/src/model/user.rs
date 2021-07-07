use serde::{Deserialize, Serialize};

use sport_log_server_derive::{Create, Delete, GetAll, GetById, Update};

use crate::schema::user;

pub type UserId = i32;

#[derive(
    Queryable, AsChangeset, Serialize, Deserialize, Debug, Create, GetById, GetAll, Update, Delete,
)]
#[table_name = "user"]
pub struct User {
    pub id: UserId,
    pub username: String,
    pub password: String,
    pub email: String,
}

#[derive(Insertable, Serialize, Deserialize)]
#[table_name = "user"]
pub struct NewUser {
    pub username: String,
    pub password: String,
    pub email: String,
}
