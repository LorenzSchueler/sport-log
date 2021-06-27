use serde::{Serialize, Deserialize};

use crate::schema::*;

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

pub type PlatformId = i32;

#[derive(Queryable, AsChangeset, Serialize, Deserialize, Debug)]
#[table_name = "platform"]
pub struct Platform {
    pub id: PlatformId,
    pub name: String,
}

pub type PlatformCredentialsId = i32;

#[derive(Queryable, AsChangeset, Serialize, Deserialize, Debug)]
#[table_name = "platform_credentials"]
pub struct PlatformCredentials {
    pub id: PlatformCredentialsId,
    pub account_id: i32,
    pub platform_id: i32,
    pub username: String,
    pub password: String,
}

#[derive(Insertable, Serialize, Deserialize)]
#[table_name = "platform_credentials"]
pub struct NewPlatformCredentials {
    pub account_id: i32,
    pub platform_id: i32,
    pub username: String,
    pub password: String,
}
