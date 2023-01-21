#[cfg(feature = "server")]
use std::convert::Infallible;

#[cfg(feature = "server")]
use axum::{
    extract::rejection::{TypedHeaderRejection, TypedHeaderRejectionReason},
    response::{IntoResponse, Response},
    Json,
};
#[cfg(feature = "server")]
use diesel::result::{DatabaseErrorKind, Error as DieselError};
use http::StatusCode;
#[cfg(feature = "server")]
use r2d2::Error as R2D2Error;
use serde::{ser::SerializeStruct, Deserialize, Serialize};
#[cfg(feature = "server")]
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
    pub status: StatusCode,
    pub message: Option<ErrorMessage>,
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

#[cfg(feature = "server")]
impl From<StatusCode> for HandlerError {
    fn from(status: StatusCode) -> Self {
        HandlerError {
            status,
            message: None,
        }
    }
}

#[cfg(feature = "server")]
impl From<TypedHeaderRejection> for HandlerError {
    fn from(rejection: TypedHeaderRejection) -> Self {
        match rejection.reason() {
            TypedHeaderRejectionReason::Missing => HandlerError {
                status: StatusCode::UNAUTHORIZED,
                message: Some(ErrorMessage::Other {
                    error: "authorization header missing".to_owned(),
                }),
            },
            TypedHeaderRejectionReason::Error(error) => HandlerError {
                status: StatusCode::BAD_REQUEST,
                message: Some(ErrorMessage::Other {
                    error: format!("header {}: {}", rejection.name(), error),
                }),
            },
            _ => HandlerError {
                status: StatusCode::BAD_REQUEST,
                message: Some(ErrorMessage::Other {
                    error: format!("header {} invalid", rejection.name(),),
                }),
            },
        }
    }
}

#[cfg(feature = "server")]
impl From<R2D2Error> for HandlerError {
    fn from(error: R2D2Error) -> Self {
        HandlerError {
            status: StatusCode::INTERNAL_SERVER_ERROR,
            message: Some(ErrorMessage::Other {
                error: error.to_string(),
            }),
        }
    }
}

#[cfg(feature = "server")]
impl From<DieselError> for HandlerError {
    fn from(error: DieselError) -> Self {
        match error {
            DieselError::NotFound => HandlerError {
                status: StatusCode::NOT_FOUND,
                message: None,
            },
            DieselError::DatabaseError(db_error, db_error_info) => match db_error {
                DatabaseErrorKind::UniqueViolation => HandlerError {
                    status: StatusCode::CONFLICT,
                    message: Some({
                        let table = db_error_info.table_name().unwrap_or("<unknown>").to_owned();
                        let constraint = db_error_info.constraint_name();
                        if constraint
                            .map(|constraint| constraint.ends_with("_pkey"))
                            .unwrap_or(false)
                        {
                            ErrorMessage::PrimaryKeyViolation { table }
                        } else {
                            let columns = constraint
                                .and_then(|c| {
                                    // {tablename}__{column1__column2...}__key
                                    let key = "__key";
                                    if c.ends_with(key) && c.len() > key.len() {
                                        Some(
                                            c[..c.len() - 5]
                                                .split("__")
                                                .skip(1)
                                                .map(ToOwned::to_owned)
                                                .collect(),
                                        )
                                    } else {
                                        None
                                    }
                                })
                                .unwrap_or_default();

                            ErrorMessage::UniqueViolation { table, columns }
                        }
                    }),
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
                                if c.ends_with(fkey) && c.len() > table.len() + 1 + fkey.len() {
                                    let column = &c[table.len() + 1..c.len() - fkey.len()];
                                    Some(column)
                                } else {
                                    None
                                }
                            })
                            .unwrap_or("<unknown>")
                            .to_owned();

                        Some(ErrorMessage::ForeignKeyViolation { table, column })
                    },
                },
                _ => HandlerError {
                    status: StatusCode::INTERNAL_SERVER_ERROR,
                    message: Some(ErrorMessage::Other {
                        error: db_error_info.message().to_owned(),
                    }),
                },
            },
            _ => HandlerError {
                status: StatusCode::INTERNAL_SERVER_ERROR,
                message: None,
            },
        }
    }
}

#[cfg(feature = "server")]
impl From<Infallible> for HandlerError {
    fn from(_: Infallible) -> Self {
        unreachable!()
    }
}

#[cfg(feature = "server")]
impl IntoResponse for HandlerError {
    fn into_response(self) -> Response {
        if let Some(message) = &self.message {
            info!("{:?}", message);
        }
        (self.status, Json(self)).into_response()
    }
}
