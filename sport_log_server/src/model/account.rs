use serde::{Deserialize, Serialize};

use sport_log_server_derive::{Create, Delete, GetAll, GetById, Update};

use crate::schema::account;

pub type AccountId = i32;

#[derive(
    Queryable, AsChangeset, Serialize, Deserialize, Debug, Create, GetById, GetAll, Update, Delete,
)]
#[table_name = "account"]
pub struct Account {
    pub id: AccountId,
    pub username: String,
    pub password: String,
    pub email: String,
}

#[derive(Insertable, Serialize, Deserialize)]
#[table_name = "account"]
pub struct NewAccount {
    pub username: String,
    pub password: String,
    pub email: String,
}
