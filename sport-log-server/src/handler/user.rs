use axum::{extract::State, http::StatusCode, Json};
use sport_log_types::User;

use crate::{
    auth::{AuthAdmin, AuthUser},
    config::Config,
    db::*,
    handler::{ErrorMessage, HandlerError, HandlerResult, UnverifiedSingleOrVec},
    state::DbConn,
};

pub async fn adm_create_users(
    auth: AuthAdmin,
    mut db: DbConn,
    Json(users): Json<UnverifiedSingleOrVec<User>>,
) -> HandlerResult<StatusCode> {
    match users {
        UnverifiedSingleOrVec::Single(user) => {
            let mut user = user.verify_adm(auth)?;
            UserDb::create(&mut user, &mut db)
        }
        UnverifiedSingleOrVec::Vec(users) => {
            let mut users = users.verify_adm(auth)?;
            UserDb::create_multiple(&mut users, &mut db)
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

pub async fn create_user(
    State(config): State<&Config>,
    mut db: DbConn,
    Json(user): Json<Unverified<User>>,
) -> HandlerResult<StatusCode> {
    if !config.user_self_registration {
        return Err(HandlerError {
            status: StatusCode::FORBIDDEN,
            message: Some(ErrorMessage::Other {
                error: "user self registration is disabled".to_owned(),
            }),
        });
    }

    let mut user = user.verify_unchecked()?;
    UserDb::create(&mut user, &mut db)
        .map(|_| StatusCode::OK)
        .map_err(Into::into)
}

pub async fn get_user(auth: AuthUser, mut db: DbConn) -> HandlerResult<Json<User>> {
    UserDb::get_by_id(*auth, &mut db)
        .map(Json)
        .map_err(Into::into)
}

pub async fn update_user(
    auth: AuthUser,
    mut db: DbConn,
    Json(user): Json<Unverified<User>>,
) -> HandlerResult<StatusCode> {
    let mut user = user.verify_user(auth, &mut db)?;
    UserDb::update(&mut user, &mut db)
        .map(|_| StatusCode::OK)
        .map_err(Into::into)
}

pub async fn delete_user(auth: AuthUser, mut db: DbConn) -> HandlerResult<StatusCode> {
    UserDb::delete(*auth, &mut db)
        .map(|_| StatusCode::OK)
        .map_err(Into::into)
}
