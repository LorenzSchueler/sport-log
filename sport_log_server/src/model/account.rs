use serde::{Deserialize, Serialize};

use crate::schema::account;

pub type AccountId = i32;

#[derive(Queryable, AsChangeset, Serialize, Deserialize, Debug)]
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
