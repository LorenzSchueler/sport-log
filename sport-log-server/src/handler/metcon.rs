use axum::{extract::Query, Json};
use sport_log_types::{
    EpochResponse, Metcon, MetconId, MetconMovement, MetconMovementId, MetconSession,
    MetconSessionId,
};

use crate::{
    auth::AuthUserOrAP,
    db::*,
    handler::{HandlerResult, IdOption, TimeSpanOption, UnverifiedSingleOrVec},
    state::DbConn,
};

pub async fn create_metcon_sessions(
    auth: AuthUserOrAP,
    mut db: DbConn,
    Json(metcon_sessions): Json<UnverifiedSingleOrVec<MetconSession>>,
) -> HandlerResult<Json<EpochResponse>> {
    match metcon_sessions {
        UnverifiedSingleOrVec::Single(metcon_session) => {
            let metcon_session = metcon_session.verify_user_ap_create(auth)?;
            MetconSessionDb::create(&metcon_session, &mut db).await?;
        }
        UnverifiedSingleOrVec::Vec(metcon_sessions) => {
            let metcon_sessions = metcon_sessions.verify_user_ap_create(auth)?;
            MetconSessionDb::create_multiple(&metcon_sessions, &mut db).await?;
        }
    }
    let epoch = MetconSessionDb::get_epoch_by_user(*auth, &mut db).await?;
    Ok(Json(EpochResponse { epoch }))
}

pub async fn get_metcon_sessions(
    auth: AuthUserOrAP,
    Query(IdOption { id }): Query<IdOption<UnverifiedId<MetconSessionId>>>,
    Query(time_span_option): Query<TimeSpanOption>,
    mut db: DbConn,
) -> HandlerResult<Json<Vec<MetconSession>>> {
    match id {
        Some(id) => {
            let metcon_session_id = id.verify_user_ap_get(auth, &mut db).await?;
            MetconSessionDb::get_by_id(metcon_session_id, &mut db)
                .await
                .map(|m| vec![m])
        }
        None => {
            MetconSessionDb::get_by_user_and_timespan(*auth, time_span_option.into(), &mut db).await
        }
    }
    .map(Json)
    .map_err(Into::into)
}

pub async fn update_metcon_sessions(
    auth: AuthUserOrAP,
    mut db: DbConn,
    Json(metcon_sessions): Json<UnverifiedSingleOrVec<MetconSession>>,
) -> HandlerResult<Json<EpochResponse>> {
    match metcon_sessions {
        UnverifiedSingleOrVec::Single(metcon_session) => {
            let metcon_session = metcon_session.verify_user_ap_update(auth, &mut db).await?;
            MetconSessionDb::update(&metcon_session, &mut db).await?;
        }
        UnverifiedSingleOrVec::Vec(metcon_sessions) => {
            let metcon_sessions = metcon_sessions.verify_user_ap_update(auth, &mut db).await?;
            MetconSessionDb::update_multiple(&metcon_sessions, &mut db).await?;
        }
    }
    let epoch = MetconSessionDb::get_epoch_by_user(*auth, &mut db).await?;
    Ok(Json(EpochResponse { epoch }))
}

pub async fn create_metcons(
    auth: AuthUserOrAP,
    mut db: DbConn,
    Json(metcons): Json<UnverifiedSingleOrVec<Metcon>>,
) -> HandlerResult<Json<EpochResponse>> {
    match metcons {
        UnverifiedSingleOrVec::Single(metcon) => {
            let metcon = metcon.verify_user_ap_create(auth)?;
            MetconDb::create(&metcon, &mut db).await?;
        }
        UnverifiedSingleOrVec::Vec(metcons) => {
            let metcons = metcons.verify_user_ap_create(auth)?;
            MetconDb::create_multiple(&metcons, &mut db).await?;
        }
    }
    let epoch = MetconDb::get_epoch_by_user_optional(*auth, &mut db).await?;
    Ok(Json(EpochResponse { epoch }))
}

pub async fn get_metcons(
    auth: AuthUserOrAP,
    Query(IdOption { id }): Query<IdOption<UnverifiedId<MetconId>>>,
    mut db: DbConn,
) -> HandlerResult<Json<Vec<Metcon>>> {
    match id {
        Some(id) => {
            let metcon_id = id.verify_user_ap_get(auth, &mut db).await?;
            MetconDb::get_by_id(metcon_id, &mut db)
                .await
                .map(|m| vec![m])
        }
        None => MetconDb::get_by_user(*auth, &mut db).await,
    }
    .map(Json)
    .map_err(Into::into)
}

pub async fn update_metcons(
    auth: AuthUserOrAP,
    mut db: DbConn,
    Json(metcons): Json<UnverifiedSingleOrVec<Metcon>>,
) -> HandlerResult<Json<EpochResponse>> {
    match metcons {
        UnverifiedSingleOrVec::Single(metcon) => {
            let metcon = metcon.verify_user_ap_update(auth, &mut db).await?;
            MetconDb::update(&metcon, &mut db).await?;
        }
        UnverifiedSingleOrVec::Vec(metcons) => {
            let metcons = metcons.verify_user_ap_update(auth, &mut db).await?;
            MetconDb::update_multiple(&metcons, &mut db).await?;
        }
    }
    let epoch = MetconDb::get_epoch_by_user_optional(*auth, &mut db).await?;
    Ok(Json(EpochResponse { epoch }))
}

pub async fn create_metcon_movements(
    auth: AuthUserOrAP,
    mut db: DbConn,
    Json(metcon_movements): Json<UnverifiedSingleOrVec<MetconMovement>>,
) -> HandlerResult<Json<EpochResponse>> {
    match metcon_movements {
        UnverifiedSingleOrVec::Single(metcon_movement) => {
            let metcon_movement = metcon_movement.verify_user_ap_create(auth)?;
            MetconMovementDb::create(&metcon_movement, &mut db).await?;
        }
        UnverifiedSingleOrVec::Vec(metcon_movements) => {
            let metcon_movements = metcon_movements.verify_user_ap_create(auth)?;
            MetconMovementDb::create_multiple(&metcon_movements, &mut db).await?;
        }
    }
    let epoch = MetconMovementDb::get_epoch_by_user_optional(*auth, &mut db).await?;
    Ok(Json(EpochResponse { epoch }))
}

pub async fn get_metcon_movements(
    auth: AuthUserOrAP,
    Query(IdOption { id }): Query<IdOption<UnverifiedId<MetconMovementId>>>,
    mut db: DbConn,
) -> HandlerResult<Json<Vec<MetconMovement>>> {
    match id {
        Some(id) => {
            let metcon_movement_id = id.verify_user_ap_get(auth, &mut db).await?;
            MetconMovementDb::get_by_id(metcon_movement_id, &mut db)
                .await
                .map(|m| vec![m])
        }
        None => MetconMovementDb::get_by_user(*auth, &mut db).await,
    }
    .map(Json)
    .map_err(Into::into)
}

pub async fn update_metcon_movements(
    auth: AuthUserOrAP,
    mut db: DbConn,
    Json(metcon_movements): Json<UnverifiedSingleOrVec<MetconMovement>>,
) -> HandlerResult<Json<EpochResponse>> {
    match metcon_movements {
        UnverifiedSingleOrVec::Single(metcon_movement) => {
            let metcon_movement = metcon_movement.verify_user_ap_update(auth, &mut db).await?;
            MetconMovementDb::update(&metcon_movement, &mut db).await?;
        }
        UnverifiedSingleOrVec::Vec(metcon_movements) => {
            let metcon_movements = metcon_movements
                .verify_user_ap_update(auth, &mut db)
                .await?;
            MetconMovementDb::update_multiple(&metcon_movements, &mut db).await?;
        }
    }
    let epoch = MetconMovementDb::get_epoch_by_user_optional(*auth, &mut db).await?;
    Ok(Json(EpochResponse { epoch }))
}
