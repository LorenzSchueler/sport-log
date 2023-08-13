use axum::http::StatusCode;
use chrono::{DateTime, Utc};
use serde::Deserialize;

use crate::db::{Timespan, Unverified};
pub use crate::error::*;

mod account;
mod action;
//mod activity;
mod app;
mod cardio;
mod diary_wod;
mod garbage_collection;
mod metcon;
mod movement;
mod platform;
mod strength;
//mod training_plan;
mod user;

pub use account::*;
pub use action::*;
pub use app::*;
//pub use activity::*;
pub use cardio::*;
pub use diary_wod::*;
pub use garbage_collection::*;
pub use metcon::*;
pub use movement::*;
pub use platform::*;
pub use strength::*;
//pub use training_plan::*;
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
        && password.chars().any(|c| c.is_lowercase())
        && password.chars().any(|c| c.is_uppercase())
        && password.chars().any(|c| c.is_numeric())
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
