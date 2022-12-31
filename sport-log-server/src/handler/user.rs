use std::sync::Arc;

use axum::{extract::State, http::StatusCode, Json};

use sport_log_types::{
    AuthAdmin, AuthUser, Config, Create, DbConn, GetById, Unverified, Update, User,
    VerifyForAdminWithoutDb, VerifyForUserWithDb, VerifyMultipleForAdminWithoutDb, VerifyUnchecked,
};

use crate::handler::{ErrorMessage, HandlerError, HandlerResult, UnverifiedSingleOrVec};

pub async fn adm_create_users(
    auth: AuthAdmin,
    db: DbConn,
    Json(users): Json<UnverifiedSingleOrVec<User>>,
) -> HandlerResult<StatusCode> {
    match users {
        UnverifiedSingleOrVec::Single(user) => {
            let user = user.verify_adm(auth)?;
            User::create(user, &db)
        }
        UnverifiedSingleOrVec::Vec(users) => {
            let users = users.verify_adm(auth)?;
            User::create_multiple(users, &db)
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

pub async fn create_user(
    State(config): State<Arc<Config>>,
    db: DbConn,
    Json(user): Json<Unverified<User>>,
) -> HandlerResult<StatusCode> {
    if !config.user_self_registration {
        return Err(HandlerError {
            status: StatusCode::FORBIDDEN,
            message: Some(ErrorMessage::Other(
                "user self registration is disabled".to_owned(),
            )),
        });
    }

    let user = user.verify_unchecked()?;
    User::create(user, &db)
        .map(|_| StatusCode::OK)
        .map_err(Into::into)
}

pub async fn get_user(auth: AuthUser, db: DbConn) -> HandlerResult<Json<User>> {
    User::get_by_id(*auth, &db).map(Json).map_err(Into::into)
}

pub async fn update_user(
    auth: AuthUser,
    db: DbConn,
    Json(user): Json<Unverified<User>>,
) -> HandlerResult<StatusCode> {
    let user = user.verify_user(auth, &db)?;
    User::update(user, &db)
        .map(|_| StatusCode::OK)
        .map_err(Into::into)
}

pub async fn delete_user(auth: AuthUser, db: DbConn) -> HandlerResult<StatusCode> {
    User::delete(*auth, &db)
        .map(|_| StatusCode::OK)
        .map_err(Into::into)
}
