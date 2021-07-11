use diesel::QueryResult;
use rocket::{http::Status, serde::json::Json};

pub mod action;
pub mod platform;
pub mod user;

trait ToJson<T> {
    fn to_json(self) -> Result<Json<T>, Status>;
}

impl<T> ToJson<T> for QueryResult<T> {
    fn to_json(self) -> Result<Json<T>, Status> {
        self.map(Json).map_err(|_| Status::InternalServerError)
    }
}
