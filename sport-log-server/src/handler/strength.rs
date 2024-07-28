use axum::{extract::Query, http::StatusCode, Json};
use sport_log_types::{Eorm, StrengthSession, StrengthSessionId, StrengthSet, StrengthSetId};

use crate::{
    auth::AuthUserOrAP,
    db::*,
    handler::{HandlerResult, IdOption, TimeSpanOption, UnverifiedSingleOrVec},
    state::DbConn,
};

pub async fn create_strength_sessions(
    auth: AuthUserOrAP,
    mut db: DbConn,
    Json(strength_sessions): Json<UnverifiedSingleOrVec<StrengthSession>>,
) -> HandlerResult<StatusCode> {
    match strength_sessions {
        UnverifiedSingleOrVec::Single(strength_session) => {
            let strength_session = strength_session.verify_user_ap_create(auth)?;
            StrengthSessionDb::create(&strength_session, &mut db).await
        }
        UnverifiedSingleOrVec::Vec(strength_sessions) => {
            let strength_sessions = strength_sessions.verify_user_ap_create(auth)?;
            StrengthSessionDb::create_multiple(&strength_sessions, &mut db).await
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

pub async fn get_strength_sessions(
    auth: AuthUserOrAP,
    Query(IdOption { id }): Query<IdOption<UnverifiedId<StrengthSessionId>>>,
    Query(time_span_option): Query<TimeSpanOption>,
    mut db: DbConn,
) -> HandlerResult<Json<Vec<StrengthSession>>> {
    match id {
        Some(id) => {
            let strength_session_id = id.verify_user_ap_get(auth, &mut db).await?;
            StrengthSessionDb::get_by_id(strength_session_id, &mut db)
                .await
                .map(|s| vec![s])
        }
        None => {
            StrengthSessionDb::get_by_user_and_timespan(*auth, time_span_option.into(), &mut db)
                .await
        }
    }
    .map(Json)
    .map_err(Into::into)
}

pub async fn update_strength_sessions(
    auth: AuthUserOrAP,
    mut db: DbConn,
    Json(strength_sessions): Json<UnverifiedSingleOrVec<StrengthSession>>,
) -> HandlerResult<StatusCode> {
    match strength_sessions {
        UnverifiedSingleOrVec::Single(strength_session) => {
            let strength_session = strength_session
                .verify_user_ap_update(auth, &mut db)
                .await?;
            StrengthSessionDb::update(&strength_session, &mut db).await
        }
        UnverifiedSingleOrVec::Vec(strength_sessions) => {
            let strength_sessions = strength_sessions
                .verify_user_ap_update(auth, &mut db)
                .await?;
            StrengthSessionDb::update_multiple(&strength_sessions, &mut db).await
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

pub async fn create_strength_sets(
    auth: AuthUserOrAP,
    mut db: DbConn,
    Json(strength_sets): Json<UnverifiedSingleOrVec<StrengthSet>>,
) -> HandlerResult<StatusCode> {
    match strength_sets {
        UnverifiedSingleOrVec::Single(strength_set) => {
            let strength_set = strength_set.verify_user_ap_create(auth)?;
            StrengthSetDb::create(&strength_set, &mut db).await
        }
        UnverifiedSingleOrVec::Vec(strength_sets) => {
            let strength_sets = strength_sets.verify_user_ap_create(auth)?;
            StrengthSetDb::create_multiple(&strength_sets, &mut db).await
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

pub async fn get_strength_sets(
    auth: AuthUserOrAP,
    Query(IdOption { id }): Query<IdOption<UnverifiedId<StrengthSetId>>>,
    mut db: DbConn,
) -> HandlerResult<Json<Vec<StrengthSet>>> {
    match id {
        Some(id) => {
            let strength_set_id = id.verify_user_ap_get(auth, &mut db).await?;
            StrengthSetDb::get_by_id(strength_set_id, &mut db)
                .await
                .map(|s| vec![s])
        }
        None => StrengthSetDb::get_by_user(*auth, &mut db).await,
    }
    .map(Json)
    .map_err(Into::into)
}

pub async fn update_strength_sets(
    auth: AuthUserOrAP,
    mut db: DbConn,
    Json(strength_sets): Json<UnverifiedSingleOrVec<StrengthSet>>,
) -> HandlerResult<StatusCode> {
    match strength_sets {
        UnverifiedSingleOrVec::Single(strength_set) => {
            let strength_set = strength_set.verify_user_ap_update(auth, &mut db).await?;
            StrengthSetDb::update(&strength_set, &mut db).await
        }
        UnverifiedSingleOrVec::Vec(strength_sets) => {
            let strength_sets = strength_sets.verify_user_ap_update(auth, &mut db).await?;
            StrengthSetDb::update_multiple(&strength_sets, &mut db).await
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

pub async fn get_eorms(_auth: AuthUserOrAP, mut db: DbConn) -> HandlerResult<Json<Vec<Eorm>>> {
    EormDb::get_all(&mut db).await.map(Json).map_err(Into::into)
}
