use axum::{extract::Query, http::StatusCode, Json};
use sport_log_types::{
    AuthUserOrAP, CardioSession, CardioSessionId, Create, DbConn, GetById, GetByUser, Route,
    RouteId, UnverifiedId, Update, VerifyForUserOrAPWithDb, VerifyForUserOrAPWithoutDb,
    VerifyIdForUserOrAP, VerifyMultipleForUserOrAPWithDb, VerifyMultipleForUserOrAPWithoutDb,
};

use crate::handler::{HandlerResult, IdOption, UnverifiedSingleOrVec};

pub async fn create_routes(
    auth: AuthUserOrAP,
    mut db: DbConn,
    Json(routes): Json<UnverifiedSingleOrVec<Route>>,
) -> HandlerResult<StatusCode> {
    match routes {
        UnverifiedSingleOrVec::Single(route) => {
            let route = route.verify_user_ap_without_db(auth)?;
            Route::create(route, &mut db)
        }
        UnverifiedSingleOrVec::Vec(routes) => {
            let routes = routes.verify_user_ap_without_db(auth)?;
            Route::create_multiple(routes, &mut db)
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
            let route_id = id.verify_user_ap(auth, &mut db)?;
            Route::get_by_id(route_id, &mut db).map(|r| vec![r])
        }
        None => Route::get_by_user(*auth, &mut db),
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
            let route = route.verify_user_ap(auth, &mut db)?;
            Route::update(route, &mut db)
        }
        UnverifiedSingleOrVec::Vec(routes) => {
            let routes = routes.verify_user_ap(auth, &mut db)?;
            Route::update_multiple(routes, &mut db)
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

//#[post(
//"/cardio_blueprint",
//format = "application/json",
//data = "<cardio_blueprint>"
//)]
//pub async fn create_cardio_blueprint(
//auth: AuthUserOrAP,
//mut db: DbConn,
//Json(cardio_blueprint): Json<Unverified<CardioBlueprint>>,
//) -> HandlerResult<Json<CardioBlueprint>> {
//let cardio_blueprint = cardio_blueprint
//.verify_user_ap_without_db(auth)
//.map_err(Error::from)?;
//CardioBlueprint::create(cardio_blueprint, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

//#[post(
//"/cardio_blueprints",
//format = "application/json",
//data = "<cardio_blueprints>"
//)]
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
//CardioBlueprint::create_multiple(cardio_blueprints, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

////#[get("/cardio_blueprint/<cardio_blueprint_id>")]
//pub async fn get_cardio_blueprint(
//auth: AuthUserOrAP,
//Path(cardio_blueprint_id): Path<UnverifiedId<CardioBlueprintId>>,
//mut db: DbConn,
//) -> HandlerResult<Json<CardioBlueprint>> {
//let cardio_blueprint_id = cardio_blueprint_id
//.verify_user_ap(auth, &mut db)?;
//CardioBlueprint::get_by_id(cardio_blueprint_id, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

////#[get("/cardio_blueprint")]
//pub async fn get_cardio_blueprints(
//auth: AuthUserOrAP,
//mut db: DbConn,
//) -> HandlerResult<Json<Vec<CardioBlueprint>>> {
//CardioBlueprint::get_by_user(*auth, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

//#[put(
//"/cardio_blueprint",
//format = "application/json",
//data = "<cardio_blueprint>"
//)]
//pub async fn update_cardio_blueprint(
//auth: AuthUserOrAP,
//mut db: DbConn,
//Json(cardio_blueprint): Json<Unverified<CardioBlueprint>>,
//) -> HandlerResult<Json<CardioBlueprint>> {
//let cardio_blueprint = cardio_blueprint
//.verify_user_ap(auth, &mut db)
//.map_err(Error::from)?;
//CardioBlueprint::update(cardio_blueprint, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

//#[put(
//"/cardio_blueprints",
//format = "application/json",
//data = "<cardio_blueprints>"
//)]
//pub async fn update_cardio_blueprints(
//auth: AuthUserOrAP,
//mut db: DbConn,
//Json(cardio_blueprints): Json<UnverifiedSingleOrVec<CardioBlueprint>>>,
//) -> HandlerResult<Json<Vec<CardioBlueprint>>> {
//let cardio_blueprints = cardio_blueprints
//.verify_user_ap(auth, &mut db)?;
//CardioBlueprint::update_multiple(cardio_blueprints, &mut db)
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
            CardioSession::create(cardio_session, &mut db)
        }
        UnverifiedSingleOrVec::Vec(cardio_sessions) => {
            let cardio_sessions = cardio_sessions.verify_user_ap_without_db(auth)?;
            CardioSession::create_multiple(cardio_sessions, &mut db)
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

pub async fn get_cardio_sessions(
    auth: AuthUserOrAP,
    Query(IdOption { id }): Query<IdOption<UnverifiedId<CardioSessionId>>>,
    mut db: DbConn,
) -> HandlerResult<Json<Vec<CardioSession>>> {
    match id {
        Some(id) => {
            let cardio_session_id = id.verify_user_ap(auth, &mut db)?;
            CardioSession::get_by_id(cardio_session_id, &mut db).map(|c| vec![c])
        }
        None => CardioSession::get_by_user(*auth, &mut db),
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
            let cardio_session = cardio_session.verify_user_ap(auth, &mut db)?;
            CardioSession::update(cardio_session, &mut db)
        }
        UnverifiedSingleOrVec::Vec(cardio_sessions) => {
            let cardio_sessions = cardio_sessions.verify_user_ap(auth, &mut db)?;
            CardioSession::update_multiple(cardio_sessions, &mut db)
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

////#[get("/cardio_session_description/<cardio_session_id>")]
//pub async fn get_cardio_session_description(
//auth: AuthUserOrAP,
//mut db: DbConn,
//Path(cardio_session_id): Path<UnverifiedId<CardioSessionId>>,
//) -> HandlerResult<Json<CardioSessionDescription>> {
//let cardio_session_id = cardio_session_id
//.verify_user_ap(auth, &mut db)
//.map_err(Error::from)?;
//CardioSessionDescription::get_by_id(cardio_session_id, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

////#[get("/cardio_session_description")]
//pub async fn get_cardio_session_descriptions(
//auth: AuthUserOrAP,
//mut db: DbConn,
//) -> HandlerResult<Json<Vec<CardioSessionDescription>>> {
//CardioSessionDescription::get_by_user(*auth, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

////#[get("/cardio_session_description/timespan/<start_datetime>/<end_datetime>")]
//pub async fn get_ordered_cardio_session_descriptions_by_timespan(
//auth: AuthUserOrAP,
//Path(start_datetime): Path<DateTime<Utc>>,
//Path(end_datetime): Path<DateTime<Utc>>,
//mut db: DbConn,
//) -> HandlerResult<Json<Vec<CardioSessionDescription>>> {
//CardioSessionDescription::get_ordered_by_user_and_timespan(
//*auth,
//start_datetime,
//end_datetime,
//&mut db,
//)
//.map(Json)
//.map_err(Into::into)
//}
