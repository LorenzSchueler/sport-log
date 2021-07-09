use rocket::http::Status;
use rocket_contrib::json::Json;

use crate::{
    auth::AuthenticatedUser,
    handler::to_json,
    model::{NewUser, User},
    Db,
};

#[post("/user", format = "application/json", data = "<user>")]
pub fn create_user(user: Json<NewUser>, conn: Db) -> Result<Json<User>, Status> {
    to_json(User::create(user.into_inner(), &conn))
}

#[get("/user")]
pub fn get_user(auth: AuthenticatedUser, conn: Db) -> Result<Json<User>, Status> {
    to_json(User::get_by_id(*auth, &conn))
}

#[put("/user", format = "application/json", data = "<user>")]
pub fn update_user(
    user: Json<User>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<User>, Status> {
    to_json(User::update(User::verify(user, auth)?, &conn))
}

#[delete("/user")]
pub fn delete_user(auth: AuthenticatedUser, conn: Db) -> Result<Status, Status> {
    User::delete(*auth, &conn)
        .map(|_| Status::NoContent)
        .map_err(|_| Status::InternalServerError)
}
