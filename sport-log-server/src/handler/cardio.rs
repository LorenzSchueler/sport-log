use axum::{extract::Query, http::StatusCode, Json};
use sport_log_types::{CardioSession, CardioSessionId, Route, RouteId};

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
) -> HandlerResult<StatusCode> {
    match routes {
        UnverifiedSingleOrVec::Single(route) => {
            let route = route.verify_user_ap_without_db(auth)?;
            RouteDb::create(&route, &mut db).await
        }
        UnverifiedSingleOrVec::Vec(routes) => {
            let routes = routes.verify_user_ap_without_db(auth)?;
            let r = RouteDb::create_multiple(&routes, &mut db).await;
            println!("\n\n\n##########\n{:?}\n##########\n\n\n", r);
            // Err(SerializationError(FailedToLookupTypeError(PgMetadataCacheKey { schema: None, type_name: "position" })))
            // https://github.com/weiznich/diesel_async/issues/103
            r
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

pub async fn get_routes(
    auth: AuthUserOrAP,
    Query(IdOption { id }): Query<IdOption<UnverifiedId<RouteId>>>,
    mut db: DbConn,
) -> HandlerResult<Json<Vec<Route>>> {
    match id {
        Some(id) => {
            let route_id = id.verify_user_ap(auth, &mut db).await?;
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
) -> HandlerResult<StatusCode> {
    match routes {
        UnverifiedSingleOrVec::Single(route) => {
            let route = route.verify_user_ap(auth, &mut db).await?;
            RouteDb::update(&route, &mut db).await
        }
        UnverifiedSingleOrVec::Vec(routes) => {
            let routes = routes.verify_user_ap(auth, &mut db).await?;
            RouteDb::update_multiple(&routes, &mut db).await
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

//pub async fn create_cardio_blueprint(
//auth: AuthUserOrAP,
//mut db: DbConn,
//Json(cardio_blueprint): Json<Unverified<CardioBlueprint>>,
//) -> HandlerResult<Json<CardioBlueprint>> {
//let cardio_blueprint = cardio_blueprint
//.verify_user_ap_without_db(auth)
//.map_err(Error::from)?;
//CardioBlueprintDb::create(&cardio_blueprint, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

//pub async fn create_cardio_blueprints(
//auth: AuthUserOrAP,
//mut db: DbConn,
//Json(cardio_blueprints): Json<UnverifiedSingleOrVec<CardioBlueprint>>>,
//) -> HandlerResult<Json<Vec<CardioBlueprint>>> {
//let cardio_blueprints =
//cardio_blueprints
//.verify_user_ap_without_db(auth)
//.map_err(|status| HandlerError {
//status,
//message: None,
//})?;
//CardioBlueprintDb::create_multiple(&cardio_blueprints, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

//pub async fn get_cardio_blueprint(
//auth: AuthUserOrAP,
//Path(cardio_blueprint_id): Path<UnverifiedId<CardioBlueprintId>>,
//mut db: DbConn,
//) -> HandlerResult<Json<CardioBlueprint>> {
//let cardio_blueprint_id = cardio_blueprint_id
//.verify_user_ap(auth, &mut db)?;
//CardioBlueprintDb::get_by_id(cardio_blueprint_id, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

//pub async fn get_cardio_blueprints(
//auth: AuthUserOrAP,
//mut db: DbConn,
//) -> HandlerResult<Json<Vec<CardioBlueprint>>> {
//CardioBlueprintDb::get_by_user(*auth, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

//pub async fn update_cardio_blueprint(
//auth: AuthUserOrAP,
//mut db: DbConn,
//Json(cardio_blueprint): Json<Unverified<CardioBlueprint>>,
//) -> HandlerResult<Json<CardioBlueprint>> {
//let cardio_blueprint = cardio_blueprint
//.verify_user_ap(auth, &mut db)
//.map_err(Error::from)?;
//CardioBlueprintDb::update(&cardio_blueprint, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

//pub async fn update_cardio_blueprints(
//auth: AuthUserOrAP,
//mut db: DbConn,
//Json(cardio_blueprints): Json<UnverifiedSingleOrVec<CardioBlueprint>>>,
//) -> HandlerResult<Json<Vec<CardioBlueprint>>> {
//let cardio_blueprints = cardio_blueprints
//.verify_user_ap(auth, &mut db)?;
//CardioBlueprintDb::update_multiple(&cardio_blueprints, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

pub async fn create_cardio_sessions(
    auth: AuthUserOrAP,
    mut db: DbConn,
    Json(cardio_sessions): Json<UnverifiedSingleOrVec<CardioSession>>,
) -> HandlerResult<StatusCode> {
    match cardio_sessions {
        UnverifiedSingleOrVec::Single(cardio_session) => {
            let cardio_session = cardio_session.verify_user_ap_without_db(auth)?;
            CardioSessionDb::create(&cardio_session, &mut db).await
        }
        UnverifiedSingleOrVec::Vec(cardio_sessions) => {
            let cardio_sessions = cardio_sessions.verify_user_ap_without_db(auth)?;
            CardioSessionDb::create_multiple(&cardio_sessions, &mut db).await
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

pub async fn get_cardio_sessions(
    auth: AuthUserOrAP,
    Query(IdOption { id }): Query<IdOption<UnverifiedId<CardioSessionId>>>,
    Query(time_span_option): Query<TimeSpanOption>,
    mut db: DbConn,
) -> HandlerResult<Json<Vec<CardioSession>>> {
    match id {
        Some(id) => {
            let cardio_session_id = id.verify_user_ap(auth, &mut db).await?;
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
) -> HandlerResult<StatusCode> {
    match cardio_sessions {
        UnverifiedSingleOrVec::Single(cardio_session) => {
            let cardio_session = cardio_session.verify_user_ap(auth, &mut db).await?;
            CardioSessionDb::update(&cardio_session, &mut db).await
        }
        UnverifiedSingleOrVec::Vec(cardio_sessions) => {
            let cardio_sessions = cardio_sessions.verify_user_ap(auth, &mut db).await?;
            CardioSessionDb::update_multiple(&cardio_sessions, &mut db).await
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}
