use std::{io::Cursor, ops::Deref};

use chrono::{DateTime, NaiveTime, Utc};
use diesel::{
    result::{DatabaseErrorInformation, DatabaseErrorKind as DbError, Error as DieselError},
    QueryResult,
};
use rocket::{
    http::{ContentType, Status},
    request::FromParam,
    response::Responder,
    serde::json::Json,
    Request, Response,
};
use sport_log_types::{ConflictDescriptor, Error, ErrorMessage};
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

fn parse_db_error(error: &(dyn DatabaseErrorInformation + Sync + Send)) -> ErrorMessage {
    let error = error.message();

    if let (Some(left), Some(right)) = (error.rfind('»'), error.rfind('«')) {
        if left < right {
            if error[left..right].ends_with("_pkey") {
                // {tablename}_pkey
                return ErrorMessage::PrimaryKeyViolation(ConflictDescriptor {
                    table: error[left + 2..right - 5].to_owned(),
                    columns: vec!["id".to_owned()],
                });
            } else if error[left..right].ends_with("_fkey") {
                // {tablename}_{column}_fkey
                let table_column: Vec<_> = error[left + 2..right - 5].split('_').collect();
                return ErrorMessage::ForeignKeyViolation(ConflictDescriptor {
                    table: table_column[0].to_owned(),
                    columns: vec![table_column[1].to_owned()],
                });
            } else if error[left..right].ends_with("_key") {
                // {tablename}__{column1__column2...}__key
                let mut table_column = error[left + 2..right - 5].split("__").map(|x| x.to_owned());
                return ErrorMessage::UniqueViolation(ConflictDescriptor {
                    table: table_column.next().unwrap(),
                    columns: table_column.collect(),
                });
            }
        }
    }

    ErrorMessage::Other(error.to_owned())
}

#[derive(Debug)]
pub struct JsonError {
    pub status: Status,
    pub message: Option<ErrorMessage>,
}

impl From<JsonError> for Error {
    fn from(json_error: JsonError) -> Self {
        Error {
            status: json_error.status.code,
            message: json_error.message,
        }
    }
}

impl<'r, 'o: 'r> Responder<'r, 'o> for JsonError {
    fn respond_to(self, _request: &'r Request<'_>) -> Result<Response<'o>, Status> {
        match &self.message {
            None => warn!("responding with status {}", self.status.code),
            Some(message) => warn!("responding with status {}: {:?}", self.status.code, message),
        }
        let status = self.status;
        let json = serde_json::to_string::<Error>(&self.into())
            .map_err(|_| Status::InternalServerError)?;
        Ok(Response::build()
            .status(status)
            .header(ContentType::JSON)
            .sized_body(json.len(), Cursor::new(json))
            .finalize())
    }
}

pub type JsonResult<T> = Result<Json<T>, JsonError>;

pub trait IntoJson<T> {
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
                    message: Some(parse_db_error(&**db_error_info)),
                },
                DbError::ForeignKeyViolation => JsonError {
                    status: Status::Conflict,
                    message: Some(parse_db_error(&**db_error_info)),
                },
                _ => {
                    warn!("{:?}", diesel_error);
                    JsonError {
                        status: Status::InternalServerError,
                        message: Some(ErrorMessage::Other(db_error_info.message().to_owned())),
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
