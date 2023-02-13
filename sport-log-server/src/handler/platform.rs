use axum::{
    extract::{Query, State},
    http::StatusCode,
    Json,
};
use sport_log_types::{Platform, PlatformCredential, PlatformCredentialId, PlatformId};

use crate::{
    auth::{AuthAdmin, AuthUser},
    config::Config,
    db::*,
    handler::{HandlerError, HandlerResult, IdOption, UnverifiedSingleOrVec},
    state::DbConn,
};

pub async fn adm_create_platforms(
    auth: AuthAdmin,
    mut db: DbConn,
    Json(platforms): Json<UnverifiedSingleOrVec<Platform>>,
) -> HandlerResult<StatusCode> {
    match platforms {
        UnverifiedSingleOrVec::Single(platform) => {
            let platform = platform.verify_adm(auth)?;
            PlatformDb::create(&platform, &mut db)
        }
        UnverifiedSingleOrVec::Vec(platforms) => {
            let platforms = platforms.verify_adm(auth)?;
            PlatformDb::create_multiple(&platforms, &mut db)
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

pub async fn ap_create_platform(
    State(config): State<&Config>,
    mut db: DbConn,
    Json(platform): Json<Unverified<Platform>>,
) -> HandlerResult<StatusCode> {
    if !config.ap_self_registration {
        return Err(HandlerError {
            status: StatusCode::FORBIDDEN,
            message: None,
        });
    }

    let platform = platform.verify_unchecked()?;
    PlatformDb::create(&platform, &mut db)
        .map(|_| StatusCode::OK)
        .map_err(Into::into)
}

pub async fn adm_get_platforms(
    auth: AuthAdmin,
    Query(IdOption { id }): Query<IdOption<UnverifiedId<PlatformId>>>,
    mut db: DbConn,
) -> HandlerResult<Json<Vec<Platform>>> {
    match id {
        Some(id) => {
            let platform_id = id.verify_adm(auth)?;
            PlatformDb::get_by_id(platform_id, &mut db).map(|p| vec![p])
        }
        None => PlatformDb::get_all(&mut db),
    }
    .map(Json)
    .map_err(Into::into)
}

pub async fn ap_get_platforms(
    Query(IdOption { id }): Query<IdOption<UnverifiedId<PlatformId>>>,
    State(config): State<&Config>,
    mut db: DbConn,
) -> HandlerResult<Json<Vec<Platform>>> {
    if !config.ap_self_registration {
        return Err(HandlerError {
            status: StatusCode::FORBIDDEN,
            message: None,
        });
    }

    match id {
        Some(id) => {
            let platform_id = id.verify_unchecked()?;
            PlatformDb::get_by_id(platform_id, &mut db).map(|p| vec![p])
        }
        None => PlatformDb::get_all(&mut db),
    }
    .map(Json)
    .map_err(Into::into)
}

pub async fn get_platforms(
    _auth: AuthUser,
    Query(IdOption { id }): Query<IdOption<UnverifiedId<PlatformId>>>,
    mut db: DbConn,
) -> HandlerResult<Json<Vec<Platform>>> {
    match id {
        Some(id) => {
            let platform_id = id.verify_unchecked()?;
            PlatformDb::get_by_id(platform_id, &mut db).map(|p| vec![p])
        }
        None => PlatformDb::get_all(&mut db),
    }
    .map(Json)
    .map_err(Into::into)
}

pub async fn adm_update_platforms(
    auth: AuthAdmin,
    mut db: DbConn,
    Json(platforms): Json<UnverifiedSingleOrVec<Platform>>,
) -> HandlerResult<StatusCode> {
    match platforms {
        UnverifiedSingleOrVec::Single(platform) => {
            let platform = platform.verify_adm(auth)?;
            PlatformDb::update(&platform, &mut db)
        }
        UnverifiedSingleOrVec::Vec(platforms) => {
            let platforms = platforms.verify_adm(auth)?;
            PlatformDb::update_multiple(&platforms, &mut db)
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

pub async fn create_platform_credentials(
    auth: AuthUser,
    mut db: DbConn,
    Json(platform_credentials): Json<UnverifiedSingleOrVec<PlatformCredential>>,
) -> HandlerResult<StatusCode> {
    match platform_credentials {
        UnverifiedSingleOrVec::Single(platform_credential) => {
            let platform_credential =
                platform_credential
                    .verify_user_without_db(auth)
                    .map_err(|status| HandlerError {
                        status,
                        message: None,
                    })?;
            PlatformCredentialDb::create(&platform_credential, &mut db)
        }
        UnverifiedSingleOrVec::Vec(platform_credentials) => {
            let platform_credentials =
                platform_credentials
                    .verify_user_without_db(auth)
                    .map_err(|status| HandlerError {
                        status,
                        message: None,
                    })?;
            PlatformCredentialDb::create_multiple(&platform_credentials, &mut db)
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

pub async fn get_platform_credentials(
    auth: AuthUser,
    Query(IdOption { id }): Query<IdOption<UnverifiedId<PlatformCredentialId>>>,
    mut db: DbConn,
) -> HandlerResult<Json<Vec<PlatformCredential>>> {
    match id {
        Some(id) => {
            let platform_id = id.verify_user(auth, &mut db)?;
            PlatformCredentialDb::get_by_id(platform_id, &mut db).map(|p| vec![p])
        }
        None => PlatformCredentialDb::get_by_user(*auth, &mut db),
    }
    .map(Json)
    .map_err(Into::into)
}

pub async fn update_platform_credentials(
    auth: AuthUser,
    mut db: DbConn,
    Json(platform_credentials): Json<UnverifiedSingleOrVec<PlatformCredential>>,
) -> HandlerResult<StatusCode> {
    match platform_credentials {
        UnverifiedSingleOrVec::Single(platform_credential) => {
            let platform_credential = platform_credential.verify_user(auth, &mut db)?;
            PlatformCredentialDb::update(&platform_credential, &mut db)
        }
        UnverifiedSingleOrVec::Vec(platform_credentials) => {
            let platform_credentials = platform_credentials.verify_user(auth, &mut db)?;
            PlatformCredentialDb::update_multiple(&platform_credentials, &mut db)
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}
