use rocket::{http::Status, serde::json::Json};

use sport_log_types::{
    AuthenticatedAdmin, AuthenticatedUser, Create, Db, Delete, GetById, NewUser, Unverified,
    Update, User, VerifyForUserWithDb, CONFIG,
};

use crate::handler::IntoJson;

#[post("/adm/user", format = "application/json", data = "<user>")]
pub async fn adm_create_user(
    user: Unverified<NewUser>,
    _auth: AuthenticatedAdmin,
    conn: Db,
) -> Result<Json<User>, Status> {
    let user = user.verify_unchecked()?;
    conn.run(|c| User::create(user, c)).await.into_json()
}

#[post("/user", format = "application/json", data = "<user>")]
pub async fn create_user(user: Unverified<NewUser>, conn: Db) -> Result<Json<User>, Status> {
    if !CONFIG.self_registration {
        return Err(Status::Unauthorized);
    }
    let user = user.verify_unchecked()?;
    conn.run(|c| User::create(user, c)).await.into_json()
}

#[get("/user")]
pub async fn get_user(auth: AuthenticatedUser, conn: Db) -> Result<Json<User>, Status> {
    conn.run(move |c| User::get_by_id(*auth, c))
        .await
        .into_json()
}

#[put("/user", format = "application/json", data = "<user>")]
pub async fn update_user(
    user: Unverified<User>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<User>, Status> {
    let user = conn.run(move |c| user.verify(&auth, c)).await?;
    conn.run(|c| User::update(user, c)).await.into_json()
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
