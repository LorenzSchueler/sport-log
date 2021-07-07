use diesel::QueryResult;
use rocket::http::Status;
use rocket_contrib::json::Json;

use crate::Db;

pub mod action;
pub mod platform;
pub mod user;

fn to_json<T>(query_result: QueryResult<T>) -> Result<Json<T>, Status> {
    query_result
        .map(Json)
        .map_err(|_| Status::InternalServerError)
}
