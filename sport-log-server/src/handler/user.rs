use rocket::{http::Status, State};

use sport_log_types::{
    AuthAdmin, AuthUser, Config, Create, Db, GetById, Unverified, Update, User,
    VerifyForUserWithDb, VerifyUnchecked,
};

use crate::handler::{IntoJson, JsonError, JsonResult};

#[post("/adm/user", format = "application/json", data = "<user>")]
pub async fn adm_create_user(
    user: Unverified<User>,
    _auth: AuthAdmin,
    conn: Db,
) -> JsonResult<User> {
    let user = user.verify_unchecked().map_err(|status| JsonError {
        status,
        message: None,
    })?;
    conn.run(|c| User::create(user, c)).await.into_json()
}

#[post("/user", format = "application/json", data = "<user>")]
pub async fn create_user(
    user: Unverified<User>,
    config: &State<Config>,
    conn: Db,
) -> JsonResult<User> {
    if !config.user_self_registration {
        return Err(JsonError {
            status: Status::Forbidden,
            message: None,
        });
    }
    let user = user.verify_unchecked().map_err(|status| JsonError {
        status,
        message: None,
    })?;
    conn.run(|c| User::create(user, c)).await.into_json()
}

#[get("/user")]
pub async fn get_user(auth: AuthUser, conn: Db) -> JsonResult<User> {
    conn.run(move |c| User::get_by_id(*auth, c))
        .await
        .into_json()
}

#[put("/user", format = "application/json", data = "<user>")]
pub async fn update_user(user: Unverified<User>, auth: AuthUser, conn: Db) -> JsonResult<User> {
    let user = conn
        .run(move |c| user.verify_user(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| User::update(user, c)).await.into_json()
}

#[delete("/user")]
pub async fn delete_user(auth: AuthUser, conn: Db) -> Result<Status, JsonError> {
    conn.run(move |c| {
        User::delete(*auth, c)
            .map(|_| Status::NoContent)
            .map_err(|_| JsonError {
                status: Status::InternalServerError,
                message: None,
            })
    })
    .await
}
