use diesel::{
    result::{DatabaseErrorKind as DbError, Error as DieselError},
    QueryResult,
};
use rocket::{http::Status, serde::json::Json};

pub mod action;
pub mod platform;
pub mod user;

trait IntoJson<T> {
    fn into_json(self) -> Result<Json<T>, Status>;
}

impl<T> IntoJson<T> for QueryResult<T> {
    fn into_json(self) -> Result<Json<T>, Status> {
        self.map(Json).map_err(|diesel_error| match diesel_error {
            DieselError::NotFound => Status::NoContent,
            DieselError::DatabaseError(db_error, _db_error_info) => match db_error {
                DbError::UniqueViolation => Status::Conflict,
                DbError::ForeignKeyViolation => Status::Conflict,
                _ => Status::InternalServerError,
            },
            _ => Status::InternalServerError,
        })
    }
}
