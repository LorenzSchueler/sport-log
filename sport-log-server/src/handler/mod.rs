use diesel::QueryResult;
use rocket::{http::Status, serde::json::Json};

pub mod action;
pub mod platform;
pub mod user;

fn to_json<T>(query_result: QueryResult<T>) -> Result<Json<T>, Status> {
    query_result
        .map(Json)
        .map_err(|_| Status::InternalServerError)
}
