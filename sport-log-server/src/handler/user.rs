use std::sync::Arc;

use axum::{extract::State, http::StatusCode, Json};
use sport_log_types::{
    AuthAdmin, AuthUser, Config, Create, DbConn, GetById, Unverified, Update, User,
    VerifyForAdminWithoutDb, VerifyForUserWithDb, VerifyMultipleForAdminWithoutDb, VerifyUnchecked,
};

use crate::handler::{ErrorMessage, HandlerError, HandlerResult, UnverifiedSingleOrVec};

pub async fn adm_create_users(
    auth: AuthAdmin,
    mut db: DbConn,
    Json(users): Json<UnverifiedSingleOrVec<User>>,
) -> HandlerResult<StatusCode> {
    match users {
        UnverifiedSingleOrVec::Single(user) => {
            let user = user.verify_adm(auth)?;
            User::create(user, &mut db)
        }
        UnverifiedSingleOrVec::Vec(users) => {
            let users = users.verify_adm(auth)?;
            User::create_multiple(users, &mut db)
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

pub async fn create_user(
    State(config): State<Arc<Config>>,
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

    let user = user.verify_unchecked()?;
    User::create(user, &mut db)
        .map(|_| StatusCode::OK)
        .map_err(Into::into)
}

pub async fn get_user(auth: AuthUser, mut db: DbConn) -> HandlerResult<Json<User>> {
    User::get_by_id(*auth, &mut db)
        .map(Json)
        .map_err(Into::into)
}

pub async fn update_user(
    auth: AuthUser,
    mut db: DbConn,
    Json(user): Json<Unverified<User>>,
) -> HandlerResult<StatusCode> {
    let user = user.verify_user(auth, &mut db)?;
    User::update(user, &mut db)
        .map(|_| StatusCode::OK)
        .map_err(Into::into)
}

pub async fn delete_user(auth: AuthUser, mut db: DbConn) -> HandlerResult<StatusCode> {
    User::delete(*auth, &mut db)
        .map(|_| StatusCode::OK)
        .map_err(Into::into)
}
