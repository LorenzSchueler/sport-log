use std::{io::Cursor, ops::Deref};

use chrono::{DateTime, NaiveTime, Utc};
use diesel::{
    result::{DatabaseErrorKind as DbError, Error as DieselError},
    QueryResult,
};
use rocket::{
    http::{ContentType, Status},
    request::FromParam,
    response::Responder,
    serde::json::Json,
    Request, Response,
};
use serde::{Deserialize, Serialize};
use tracing::warn;

pub mod account;
pub mod action;
pub mod activity;
pub mod cardio;
pub mod diary_wod;
pub mod garbage_collection;
pub mod metcon;
pub mod movement;
pub mod platform;
pub mod strength;
pub mod training_plan;
pub mod user;

#[derive(Debug)]
pub struct JsonError {
    pub status: Status,
    pub message: Option<String>,
}

#[derive(Serialize, Deserialize, Debug)]
struct SerializableJsonError {
    pub status: u16,
    pub message: Option<String>,
}

impl From<JsonError> for SerializableJsonError {
    fn from(json_error: JsonError) -> Self {
        SerializableJsonError {
            status: json_error.status.code,
            message: json_error.message,
        }
    }
}

impl<'r, 'o: 'r> Responder<'r, 'o> for JsonError {
    fn respond_to(self, _request: &'r Request<'_>) -> Result<Response<'o>, Status> {
        let status = self.status;
        let json = serde_json::to_string::<SerializableJsonError>(&self.into())
            .map_err(|_| Status::InternalServerError)?;
        Ok(Response::build()
            .status(status)
            .header(ContentType::JSON)
            .sized_body(json.len(), Cursor::new(json))
            .finalize())
    }
}

pub type JsonResult<T> = Result<Json<T>, JsonError>;

trait IntoJson<T> {
    fn into_json(self) -> JsonResult<T>;
}

impl<T> IntoJson<T> for QueryResult<T> {
    fn into_json(self) -> JsonResult<T> {
        self.map(Json).map_err(|diesel_error| match diesel_error {
            DieselError::NotFound => JsonError {
                status: Status::NoContent,
                message: None,
            },
            DieselError::DatabaseError(ref db_error, ref db_error_info) => match db_error {
                DbError::UniqueViolation => JsonError {
                    status: Status::Conflict,
                    message: Some(db_error_info.message().to_owned()),
                },
                DbError::ForeignKeyViolation => JsonError {
                    status: Status::Conflict,
                    message: Some(db_error_info.message().to_owned()),
                },
                _ => {
                    warn!("{:?}", diesel_error);
                    JsonError {
                        status: Status::InternalServerError,
                        message: None,
                    }
                }
            },
            _ => JsonError {
                status: Status::InternalServerError,
                message: None,
            },
        })
    }
}

#[derive(Debug, Clone)]
pub struct NaiveTimeWrapper(NaiveTime);

#[derive(Debug, Clone)]
pub struct DateTimeWrapper(DateTime<Utc>);

impl<'v> FromParam<'v> for NaiveTimeWrapper {
    type Error = &'v str;

    fn from_param(param: &'v str) -> Result<Self, Self::Error> {
        Ok(Self(param.parse().map_err(|_| param)?))
    }
}

impl<'v> FromParam<'v> for DateTimeWrapper {
    type Error = &'v str;

    fn from_param(param: &'v str) -> Result<DateTimeWrapper, Self::Error> {
        Ok(DateTimeWrapper(param.parse().map_err(|_| param)?))
    }
}

impl Deref for NaiveTimeWrapper {
    type Target = NaiveTime;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

impl Deref for DateTimeWrapper {
    type Target = DateTime<Utc>;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}
