use serde::{Deserialize, Serialize};

pub type UserId = i32;

#[derive(Serialize, Deserialize, Debug)]
pub struct User {
    pub id: UserId,
    pub username: String,
    pub password: String,
    pub email: String,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct NewUser {
    pub username: String,
    pub password: String,
    pub email: String,
}
