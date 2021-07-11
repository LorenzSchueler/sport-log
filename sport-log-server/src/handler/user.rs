use rocket::{http::Status, serde::json::Json};

use crate::{
    auth::AuthenticatedUser,
    handler::to_json,
    model::{NewUser, User},
    Db,
};

#[post("/user", format = "application/json", data = "<user>")]
pub async fn create_user(user: Json<NewUser>, conn: Db) -> Result<Json<User>, Status> {
    to_json(conn.run(|c| User::create(user.into_inner(), c)).await)
}

#[get("/user")]
pub async fn get_user(auth: AuthenticatedUser, conn: Db) -> Result<Json<User>, Status> {
    to_json(conn.run(move |c| User::get_by_id(*auth, c)).await)
}

#[put("/user", format = "application/json", data = "<user>")]
pub async fn update_user(
    user: Json<User>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<User>, Status> {
    let user = User::verify(user, auth)?;
    to_json(conn.run(|c| User::update(user, c)).await)
}

#[delete("/user")]
pub async fn delete_user(auth: AuthenticatedUser, conn: Db) -> Result<Status, Status> {
    conn.run(move |c| {
        User::delete(*auth, c)
            .map(|_| Status::NoContent)
            .map_err(|_| Status::InternalServerError)
    })
    .await
}
