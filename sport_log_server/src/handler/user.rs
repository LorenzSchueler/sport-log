use super::*;
use crate::{
    auth::AuthenticatedUser,
    model::{NewUser, User, UserId},
};

#[post("/user", format = "application/json", data = "<user>")]
pub fn create_user(user: Json<NewUser>, conn: Db) -> Result<Json<User>, Status> {
    to_json(User::create(user.into_inner(), &conn))
}

#[get("/user")]
pub fn get_users(conn: Db) -> Result<Json<Vec<User>>, Status> {
    to_json(User::get_all(&conn))
}

#[get("/user/<user_id>")]
pub fn get_user(user_id: UserId, auth: AuthenticatedUser, conn: Db) -> Result<Json<User>, Status> {
    to_json(User::get_by_id(user_id, &conn))
}

#[put("/user", format = "application/json", data = "<user>")]
pub fn update_user(user: Json<User>, conn: Db) -> Result<Json<User>, Status> {
    to_json(User::update(user.into_inner(), &conn))
}

#[delete("/user/<user_id>")]
pub fn delete_user(user_id: UserId, auth: AuthenticatedUser, conn: Db) -> Result<Status, Status> {
    User::delete(user_id, &conn)
        .map(|_| Status::NoContent)
        .map_err(|_| Status::InternalServerError)
}
