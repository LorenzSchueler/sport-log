use std::convert::Infallible;

use axum::{
    extract::rejection::{TypedHeaderRejection, TypedHeaderRejectionReason},
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use diesel::result::{
    DatabaseErrorInformation, DatabaseErrorKind as DbError, Error as DieselError,
};
use r2d2::Error as R2D2Error;
use serde::{ser::SerializeStruct, Deserialize, Serialize};
use tracing::info;

#[derive(Serialize, Deserialize, Debug)]
pub struct ConflictDescriptor {
    pub table: String,
    pub columns: Vec<String>,
}

#[derive(Serialize, Deserialize, Debug)]
pub enum ErrorMessage {
    UniqueViolation(ConflictDescriptor),
    ForeignKeyViolation(ConflictDescriptor),
    PrimaryKeyViolation(ConflictDescriptor),
    Other(String),
}

impl ErrorMessage {
    fn from_db_error(error: &(dyn DatabaseErrorInformation + Sync + Send)) -> Self {
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
                    let mut table_column =
                        error[left + 2..right - 5].split("__").map(|x| x.to_owned());
                    return ErrorMessage::UniqueViolation(ConflictDescriptor {
                        table: table_column.next().unwrap(),
                        columns: table_column.collect(),
                    });
                }
            }
        }

        ErrorMessage::Other(error.to_owned())
    }
}

#[derive(Debug)]
pub struct HandlerError {
    pub status: StatusCode,
    pub message: Option<ErrorMessage>,
}

pub type HandlerResult<T> = Result<T, HandlerError>;

impl From<StatusCode> for HandlerError {
    fn from(status: StatusCode) -> Self {
        HandlerError {
            status,
            message: None,
        }
    }
}

impl From<TypedHeaderRejection> for HandlerError {
    fn from(rejection: TypedHeaderRejection) -> Self {
        match rejection.reason() {
            TypedHeaderRejectionReason::Missing => HandlerError {
                status: StatusCode::UNAUTHORIZED,
                message: Some(ErrorMessage::Other(
                    "authorization header missing".to_owned(),
                )),
            },
            TypedHeaderRejectionReason::Error(error) => HandlerError {
                status: StatusCode::BAD_REQUEST,
                message: Some(ErrorMessage::Other(format!(
                    "header {}: {}",
                    rejection.name(),
                    error
                ))),
            },
            _ => HandlerError {
                status: StatusCode::BAD_REQUEST,
                message: Some(ErrorMessage::Other(format!(
                    "header {} invalid",
                    rejection.name(),
                ))),
            },
        }
    }
}

impl From<R2D2Error> for HandlerError {
    fn from(error: R2D2Error) -> Self {
        HandlerError {
            status: StatusCode::INTERNAL_SERVER_ERROR,
            message: Some(ErrorMessage::Other(error.to_string())),
        }
    }
}

impl From<DieselError> for HandlerError {
    fn from(error: DieselError) -> Self {
        match error {
            DieselError::NotFound => HandlerError {
                status: StatusCode::NOT_FOUND,
                message: None,
            },
            DieselError::DatabaseError(ref db_error, ref db_error_info) => match db_error {
                DbError::UniqueViolation => HandlerError {
                    status: StatusCode::CONFLICT,
                    message: Some(ErrorMessage::from_db_error(&**db_error_info)),
                },
                DbError::ForeignKeyViolation => HandlerError {
                    status: StatusCode::CONFLICT,
                    message: Some(ErrorMessage::from_db_error(&**db_error_info)),
                },
                _ => HandlerError {
                    status: StatusCode::INTERNAL_SERVER_ERROR,
                    message: Some(ErrorMessage::Other(db_error_info.message().to_owned())),
                },
            },
            _ => HandlerError {
                status: StatusCode::INTERNAL_SERVER_ERROR,
                message: None,
            },
        }
    }
}

impl From<Infallible> for HandlerError {
    fn from(_: Infallible) -> Self {
        unreachable!()
    }
}

impl Serialize for HandlerError {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: serde::Serializer,
    {
        let mut struct_ser = serializer.serialize_struct("error", 2)?;
        struct_ser.serialize_field("status", self.status.as_str())?;
        struct_ser.serialize_field("message", &self.message)?;
        struct_ser.end()
    }
}

impl IntoResponse for HandlerError {
    fn into_response(self) -> Response {
        if let Some(message) = &self.message {
            info!("{:?}", message);
        }
        (self.status, Json(self)).into_response()
    }
}
