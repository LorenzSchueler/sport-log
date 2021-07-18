use rocket::{
    data::{self, FromData},
    outcome::Outcome,
    serde::json::Json,
    Data, Request,
};

use serde::Deserialize;
mod action;
mod diary_wod;
mod platform;

pub use action::*;
pub use diary_wod::*;
pub use platform::*;

pub struct Unverified<T>(pub Json<T>);

#[rocket::async_trait]
impl<'r, T: Deserialize<'r>> FromData<'r> for Unverified<T> {
    type Error = ();

    async fn from_data(req: &'r Request<'_>, data: Data<'r>) -> data::Outcome<'r, Self> {
        Outcome::Success(Self(Json::<T>::from_data(req, data).await.unwrap()))
    }
}
