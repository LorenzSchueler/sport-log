#[cfg(feature = "full")]
use rocket::{
    data::{self, FromData},
    outcome::Outcome,
    serde::json::Json,
    Data, Request,
};
#[cfg(feature = "full")]
use serde::Deserialize;

mod action;
#[cfg(feature = "full")]
mod auth;
mod cardio;
#[cfg(feature = "full")]
mod config;
#[cfg(feature = "full")]
mod db;
mod diary_wod;
mod metcon;
mod movement;
mod platform;
mod sharing;
mod strength;
mod user;

pub use action::*;
#[cfg(feature = "full")]
pub use auth::*;
pub use cardio::*;
#[cfg(feature = "full")]
pub use config::*;
#[cfg(feature = "full")]
pub use db::*;
pub use diary_wod::*;
pub use metcon::*;
pub use movement::*;
pub use platform::*;
pub use sharing::*;
pub use strength::*;
pub use user::*;

#[cfg(feature = "full")]
pub struct Unverified<T>(Json<T>);

#[cfg(feature = "full")]
#[rocket::async_trait]
impl<'r, T: Deserialize<'r>> FromData<'r> for Unverified<T> {
    type Error = ();

    async fn from_data(req: &'r Request<'_>, data: Data<'r>) -> data::Outcome<'r, Self> {
        Outcome::Success(Self(Json::<T>::from_data(req, data).await.unwrap()))
    }
}
