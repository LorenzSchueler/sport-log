use serde::{Deserialize, Serialize};

use sport_log_server_derive::{Create, Delete, GetAll, Update};

use super::*;
use crate::schema::{platform, platform_credentials};

pub type PlatformId = i32;

#[derive(Queryable, AsChangeset, Serialize, Deserialize, Debug, Create, GetAll, Update, Delete)]
#[table_name = "platform"]
pub struct Platform {
    pub id: PlatformId,
    pub name: String,
}

#[derive(Insertable, Serialize, Deserialize)]
#[table_name = "platform"]
pub struct NewPlatform {
    pub name: String,
}

pub type PlatformCredentialsId = i32;

#[derive(Queryable, AsChangeset, Serialize, Deserialize, Debug, Create, GetAll, Update, Delete)]
#[table_name = "platform_credentials"]
pub struct PlatformCredentials {
    pub id: PlatformCredentialsId,
    pub account_id: AccountId,
    pub platform_id: PlatformId,
    pub username: String,
    pub password: String,
}

#[derive(Insertable, Serialize, Deserialize)]
#[table_name = "platform_credentials"]
pub struct NewPlatformCredentials {
    pub account_id: AccountId,
    pub platform_id: PlatformId,
    pub username: String,
    pub password: String,
}
