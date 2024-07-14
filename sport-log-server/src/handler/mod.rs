use axum::http::StatusCode;
use chrono::{DateTime, Utc};
use serde::Deserialize;

use crate::db::{Timespan, Unverified};
pub use crate::error::*;

mod account;
mod action;
mod app;
mod cardio;
mod diary_wod;
mod metcon;
mod movement;
mod platform;
mod strength;
mod user;

pub use account::*;
pub use action::*;
pub use app::*;
pub use cardio::*;
pub use diary_wod::*;
pub use metcon::*;
pub use movement::*;
pub use platform::*;
pub use strength::*;
pub use user::*;

#[derive(Debug, Deserialize)]
#[serde(untagged)]
pub enum UnverifiedSingleOrVec<T> {
    Single(Unverified<T>),
    Vec(Unverified<Vec<T>>),
}

#[derive(Debug, Deserialize)]
pub struct IdOption<T> {
    #[serde(default = "none")]
    pub id: Option<T>,
}

#[derive(Debug, Deserialize)]
pub struct TimeSpanOption {
    #[serde(default = "none")]
    pub start: Option<DateTime<Utc>>,
    #[serde(default = "none")]
    pub end: Option<DateTime<Utc>>,
}

impl From<TimeSpanOption> for Timespan {
    fn from(tso: TimeSpanOption) -> Self {
        match tso {
            TimeSpanOption {
                start: Some(start),
                end: Some(end),
            } => Timespan::StartEnd(start, end),
            TimeSpanOption {
                start: Some(start),
                end: None,
            } => Timespan::Start(start),
            TimeSpanOption {
                start: None,
                end: Some(end),
            } => Timespan::End(end),
            TimeSpanOption {
                start: None,
                end: None,
            } => Timespan::All,
        }
    }
}

fn none<T>() -> Option<T> {
    None
}

fn check_password(password: &str) -> HandlerResult<()> {
    if password.len() >= 8
        && password.chars().any(char::is_lowercase)
        && password.chars().any(char::is_uppercase)
        && password.chars().any(char::is_numeric)
    {
        Ok(())
    } else {
        Err(HandlerError::from((
            StatusCode::BAD_REQUEST,
            ErrorMessage::Other {
                error: "The password must contain at least one lower case and one upper case character as well as one number and must be at least 8 characters long.".to_owned(),
            },
        )))
    }
}
