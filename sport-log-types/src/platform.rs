use serde::{Deserialize, Serialize};

use crate::UserId;

pub type PlatformId = i32;

#[derive(Serialize, Deserialize, Debug)]
pub struct Platform {
    pub id: PlatformId,
    pub name: String,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct NewPlatform {
    pub name: String,
}

pub type PlatformCredentialsId = i32;

#[derive(Serialize, Deserialize, Debug)]
pub struct PlatformCredentials {
    pub id: PlatformCredentialsId,
    pub user_id: UserId,
    pub platform_id: PlatformId,
    pub username: String,
    pub password: String,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct NewPlatformCredentials {
    pub user_id: UserId,
    pub platform_id: PlatformId,
    pub username: String,
    pub password: String,
}
