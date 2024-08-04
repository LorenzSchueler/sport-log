use axum::{extract::State, http::StatusCode, Json};
use sport_log_types::{EpochResponse, User};

use crate::{
    auth::{AuthAdmin, AuthUser},
    config::Config,
    db::*,
    handler::{check_password, ErrorMessage, HandlerError, HandlerResult, UnverifiedSingleOrVec},
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
            check_password(&user.password)?;
            UserDb::create(&mut user, &mut db).await?;
        }
        UnverifiedSingleOrVec::Vec(users) => {
            let mut users = users.verify_adm(auth)?;
            for user in &users {
                check_password(&user.password)?;
            }
            UserDb::create_multiple(&mut users, &mut db).await?;
        }
    }
    Ok(StatusCode::OK)
}

pub async fn create_user(
    State(config): State<&Config>,
    mut db: DbConn,
    Json(user): Json<Unverified<User>>,
) -> HandlerResult<Json<EpochResponse>> {
    if !config.user_self_registration {
        return Err(HandlerError::from((
            StatusCode::FORBIDDEN,
            ErrorMessage::Other {
                error: "user self registration is disabled".to_owned(),
            },
        )));
    }

    let mut user = user.verify_unchecked_create()?;
    check_password(&user.password)?;
    UserDb::create(&mut user, &mut db).await?;
    let epoch = UserDb::get_epoch_by_user(user.id, &mut db).await?;
    Ok(Json(EpochResponse { epoch }))
}

pub async fn get_user(auth: AuthUser, mut db: DbConn) -> HandlerResult<Json<User>> {
    UserDb::get_by_id(*auth, &mut db)
        .await
        .map(Json)
        .map_err(Into::into)
}

pub async fn update_user(
    auth: AuthUser,
    mut db: DbConn,
    Json(user): Json<Unverified<User>>,
) -> HandlerResult<Json<EpochResponse>> {
    let mut user = user.verify_user_update(auth, &mut db).await?;
    check_password(&user.password)?;
    UserDb::update(&mut user, &mut db).await?;
    let epoch = UserDb::get_epoch_by_user(*auth, &mut db).await?;
    Ok(Json(EpochResponse { epoch }))
}

pub async fn delete_user(auth: AuthUser, mut db: DbConn) -> HandlerResult<Json<EpochResponse>> {
    UserDb::delete(*auth, &mut db).await?;
    let epoch = UserDb::get_epoch_by_user(*auth, &mut db).await?;
    Ok(Json(EpochResponse { epoch }))
}
