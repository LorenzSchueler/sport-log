use axum::{Json, extract::Query};
use sport_log_types::{CardioSession, CardioSessionId, EpochResponse, Route, RouteId};

use crate::{
    auth::AuthUserOrAP,
    db::*,
    handler::{HandlerResult, IdOption, TimeSpanOption, UnverifiedSingleOrVec},
    state::DbConn,
};

pub async fn create_routes(
    auth: AuthUserOrAP,
    mut db: DbConn,
    Json(routes): Json<UnverifiedSingleOrVec<Route>>,
) -> HandlerResult<Json<EpochResponse>> {
    match routes {
        UnverifiedSingleOrVec::Single(route) => {
            let route = route.verify_user_ap_create(auth)?;
            RouteDb::create(&route, &mut db).await?;
        }
        UnverifiedSingleOrVec::Vec(routes) => {
            let routes = routes.verify_user_ap_create(auth)?;
            RouteDb::create_multiple(&routes, &mut db).await?;
        }
    }
    let epoch = RouteDb::get_epoch_by_user(*auth, &mut db).await?;
    Ok(Json(EpochResponse { epoch }))
}

pub async fn get_routes(
    auth: AuthUserOrAP,
    Query(IdOption { id }): Query<IdOption<UnverifiedId<RouteId>>>,
    mut db: DbConn,
) -> HandlerResult<Json<Vec<Route>>> {
    match id {
        Some(id) => {
            let route_id = id.verify_user_ap_get(auth, &mut db).await?;
            RouteDb::get_by_id(route_id, &mut db).await.map(|r| vec![r])
        }
        None => RouteDb::get_by_user(*auth, &mut db).await,
    }
    .map(Json)
    .map_err(Into::into)
}

pub async fn update_routes(
    auth: AuthUserOrAP,
    mut db: DbConn,
    Json(routes): Json<UnverifiedSingleOrVec<Route>>,
) -> HandlerResult<Json<EpochResponse>> {
    match routes {
        UnverifiedSingleOrVec::Single(route) => {
            let route = route.verify_user_ap_update(auth, &mut db).await?;
            RouteDb::update(&route, &mut db).await?;
        }
        UnverifiedSingleOrVec::Vec(routes) => {
            let routes = routes.verify_user_ap_update(auth, &mut db).await?;
            RouteDb::update_multiple(&routes, &mut db).await?;
        }
    }
    let epoch = RouteDb::get_epoch_by_user(*auth, &mut db).await?;
    Ok(Json(EpochResponse { epoch }))
}

pub async fn create_cardio_sessions(
    auth: AuthUserOrAP,
    mut db: DbConn,
    Json(cardio_sessions): Json<UnverifiedSingleOrVec<CardioSession>>,
) -> HandlerResult<Json<EpochResponse>> {
    match cardio_sessions {
        UnverifiedSingleOrVec::Single(cardio_session) => {
            let cardio_session = cardio_session.verify_user_ap_create(auth)?;
            CardioSessionDb::create(&cardio_session, &mut db).await?;
        }
        UnverifiedSingleOrVec::Vec(cardio_sessions) => {
            let cardio_sessions = cardio_sessions.verify_user_ap_create(auth)?;
            CardioSessionDb::create_multiple(&cardio_sessions, &mut db).await?;
        }
    }
    let epoch = CardioSessionDb::get_epoch_by_user(*auth, &mut db).await?;
    Ok(Json(EpochResponse { epoch }))
}

pub async fn get_cardio_sessions(
    auth: AuthUserOrAP,
    Query(IdOption { id }): Query<IdOption<UnverifiedId<CardioSessionId>>>,
    Query(time_span_option): Query<TimeSpanOption>,
    mut db: DbConn,
) -> HandlerResult<Json<Vec<CardioSession>>> {
    match id {
        Some(id) => {
            let cardio_session_id = id.verify_user_ap_get(auth, &mut db).await?;
            CardioSessionDb::get_by_id(cardio_session_id, &mut db)
                .await
                .map(|c| vec![c])
        }
        None => {
            CardioSessionDb::get_by_user_and_timespan(*auth, time_span_option.into(), &mut db).await
        }
    }
    .map(Json)
    .map_err(Into::into)
}

pub async fn update_cardio_sessions(
    auth: AuthUserOrAP,
    mut db: DbConn,
    Json(cardio_sessions): Json<UnverifiedSingleOrVec<CardioSession>>,
) -> HandlerResult<Json<EpochResponse>> {
    match cardio_sessions {
        UnverifiedSingleOrVec::Single(cardio_session) => {
            let cardio_session = cardio_session.verify_user_ap_update(auth, &mut db).await?;
            CardioSessionDb::update(&cardio_session, &mut db).await?;
        }
        UnverifiedSingleOrVec::Vec(cardio_sessions) => {
            let cardio_sessions = cardio_sessions.verify_user_ap_update(auth, &mut db).await?;
            CardioSessionDb::update_multiple(&cardio_sessions, &mut db).await?;
        }
    }
    let epoch = CardioSessionDb::get_epoch_by_user(*auth, &mut db).await?;
    Ok(Json(EpochResponse { epoch }))
}
