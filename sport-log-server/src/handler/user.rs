use rocket::{http::Status, serde::json::Json};

use sport_log_types::{
    AuthAdmin, AuthUser, Create, Db,  GetById, Unverified, Update, User,
    VerifyForUserWithDb, VerifyUnchecked, CONFIG,
};

use crate::handler::IntoJson;

#[post("/adm/user", format = "application/json", data = "<user>")]
pub async fn adm_create_user(
    user: Unverified<User>,
    _auth: AuthAdmin,
    conn: Db,
) -> Result<Json<User>, Status> {
    let user = user.verify_unchecked()?;
    conn.run(|c| User::create(user, c)).await.into_json()
}

#[post("/user", format = "application/json", data = "<user>")]
pub async fn create_user(user: Unverified<User>, conn: Db) -> Result<Json<User>, Status> {
    if !CONFIG.user_self_registration {
        return Err(Status::Forbidden);
    }
    let user = user.verify_unchecked()?;
    conn.run(|c| User::create(user, c)).await.into_json()
}

#[get("/user")]
pub async fn get_user(auth: AuthUser, conn: Db) -> Result<Json<User>, Status> {
    conn.run(move |c| User::get_by_id(*auth, c))
        .await
        .into_json()
}

#[put("/user", format = "application/json", data = "<user>")]
pub async fn update_user(
    user: Unverified<User>,
    auth: AuthUser,
    conn: Db,
) -> Result<Json<User>, Status> {
    let user = conn.run(move |c| user.verify_user(&auth, c)).await?;
    conn.run(|c| User::update(user, c)).await.into_json()
}

#[delete("/user")]
pub async fn delete_user(auth: AuthUser, conn: Db) -> Result<Status, Status> {
    conn.run(move |c| {
        User::delete(*auth, c)
            .map(|_| Status::NoContent)
            .map_err(|_| Status::InternalServerError)
    })
    .await
}
