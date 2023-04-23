use std::convert::Infallible;

use axum::{
    extract::rejection::{TypedHeaderRejection, TypedHeaderRejectionReason},
    http::{HeaderValue, StatusCode},
    response::{IntoResponse, Response},
    Json,
};
use diesel::result::{DatabaseErrorKind, Error as DieselError};
use hyper::{
    header::{AUTHORIZATION, WWW_AUTHENTICATE},
    HeaderMap,
};
use r2d2::Error as R2D2Error;
use serde::{ser::SerializeStruct, Deserialize, Serialize};
use tracing::info;

#[derive(Serialize, Deserialize, Debug)]
#[serde(rename_all = "snake_case")]
pub enum ErrorMessage {
    PrimaryKeyViolation { table: String },
    ForeignKeyViolation { table: String, column: String },
    UniqueViolation { table: String, columns: Vec<String> },
    Other { error: String },
}

#[derive(Debug)]
pub struct HandlerError {
    status: StatusCode,
    message: Option<ErrorMessage>,
    headers: Option<HeaderMap>,
}

impl Serialize for HandlerError {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: serde::Serializer,
    {
        let mut struct_ser = serializer.serialize_struct("error", 2)?;
        struct_ser.serialize_field("status", &self.status.as_u16())?;
        struct_ser.serialize_field("message", &self.message)?;
        struct_ser.end()
    }
}

pub type HandlerResult<T> = Result<T, HandlerError>;

impl From<StatusCode> for HandlerError {
    fn from(status: StatusCode) -> Self {
        HandlerError {
            status,
            message: None,
            headers: None,
        }
    }
}

impl From<(StatusCode, ErrorMessage)> for HandlerError {
    fn from((status, message): (StatusCode, ErrorMessage)) -> Self {
        HandlerError {
            status,
            message: Some(message),
            headers: None,
        }
    }
}

impl From<TypedHeaderRejection> for HandlerError {
    fn from(rejection: TypedHeaderRejection) -> Self {
        match rejection.reason() {
            TypedHeaderRejectionReason::Missing => HandlerError {
                status: StatusCode::UNAUTHORIZED,
                message: Some(ErrorMessage::Other {
                    error: format!("header {} missing", rejection.name()),
                }),
                headers: (rejection.name() == AUTHORIZATION).then(|| {
                    [(WWW_AUTHENTICATE, HeaderValue::from_static("Basic"))]
                        .into_iter()
                        .collect()
                }),
            },
            TypedHeaderRejectionReason::Error(error) => HandlerError {
                status: StatusCode::BAD_REQUEST,
                message: Some(ErrorMessage::Other {
                    error: format!("header {}: {}", rejection.name(), error),
                }),
                headers: None,
            },
            _ => HandlerError {
                status: StatusCode::BAD_REQUEST,
                message: Some(ErrorMessage::Other {
                    error: format!("header {} invalid", rejection.name()),
                }),
                headers: None,
            },
        }
    }
}

impl From<R2D2Error> for HandlerError {
    fn from(error: R2D2Error) -> Self {
        HandlerError {
            status: StatusCode::INTERNAL_SERVER_ERROR,
            message: Some(ErrorMessage::Other {
                error: error.to_string(),
            }),
            headers: None,
        }
    }
}

impl From<DieselError> for HandlerError {
    fn from(error: DieselError) -> Self {
        match error {
            DieselError::NotFound => HandlerError::from(StatusCode::NOT_FOUND),
            DieselError::DatabaseError(db_error, db_error_info) => match db_error {
                DatabaseErrorKind::UniqueViolation => HandlerError {
                    status: StatusCode::CONFLICT,
                    message: Some({
                        let table = db_error_info.table_name().unwrap_or("<unknown>").to_owned();
                        let constraint = db_error_info.constraint_name();
                        if constraint.map_or(false, |constraint| constraint.ends_with("_pkey")) {
                            ErrorMessage::PrimaryKeyViolation { table }
                        } else {
                            let columns = constraint
                                .and_then(|c| {
                                    // {tablename}__{column1__column2...}__key
                                    let key = "__key";
                                    (c.ends_with(key) && c.len() > key.len()).then(|| {
                                        c[..c.len() - 5]
                                            .split("__")
                                            .skip(1)
                                            .map(ToOwned::to_owned)
                                            .collect()
                                    })
                                })
                                .unwrap_or_default();

                            ErrorMessage::UniqueViolation { table, columns }
                        }
                    }),
                    headers: None,
                },
                DatabaseErrorKind::ForeignKeyViolation => HandlerError {
                    status: StatusCode::CONFLICT,
                    message: {
                        let table = db_error_info.table_name().unwrap_or("<unknown>").to_owned();
                        let column = db_error_info
                            .constraint_name()
                            .and_then(|c| {
                                // {tablename}_{column}_fkey
                                let fkey = "_fkey";
                                (c.ends_with(fkey) && c.len() > table.len() + 1 + fkey.len())
                                    .then(|| &c[table.len() + 1..c.len() - fkey.len()])
                            })
                            .unwrap_or("<unknown>")
                            .to_owned();

                        Some(ErrorMessage::ForeignKeyViolation { table, column })
                    },
                    headers: None,
                },
                _ => HandlerError {
                    status: StatusCode::INTERNAL_SERVER_ERROR,
                    message: Some(ErrorMessage::Other {
                        error: db_error_info.message().to_owned(),
                    }),
                    headers: None,
                },
            },
            _ => HandlerError::from(StatusCode::INTERNAL_SERVER_ERROR),
        }
    }
}

impl From<Infallible> for HandlerError {
    fn from(_: Infallible) -> Self {
        unreachable!()
    }
}

impl IntoResponse for HandlerError {
    fn into_response(self) -> Response {
        if let Some(message) = &self.message {
            info!("{:?}", message);
        }
        if let Some(header) = &self.headers {
            (self.status, header.to_owned(), Json(self)).into_response()
        } else {
            (self.status, Json(self)).into_response()
        }
    }
}
