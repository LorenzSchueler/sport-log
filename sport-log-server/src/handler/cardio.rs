use sport_log_types::{
    AuthUserOrAP, CardioBlueprint, CardioBlueprintId, CardioSession, CardioSessionDescription,
    CardioSessionId, Create, CreateMultiple, Db, GetById, GetByUser, Route, RouteId, Unverified,
    UnverifiedId, Update, VerifyForUserOrAPWithDb, VerifyForUserOrAPWithoutDb, VerifyIdForUserOrAP,
    VerifyMultipleForUserOrAPWithDb, VerifyMultipleForUserOrAPWithoutDb,
};

use crate::handler::{DateTimeWrapper, IntoJson, JsonError, JsonResult};

#[post("/route", format = "application/json", data = "<route>")]
pub async fn create_route(
    route: Unverified<Route>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Route> {
    let route = route
        .verify_user_ap_without_db(&auth)
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| Route::create(route, c)).await.into_json()
}

#[post("/routes", format = "application/json", data = "<routes>")]
pub async fn create_routes(
    routes: Unverified<Vec<Route>>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Vec<Route>> {
    let routes = routes
        .verify_user_ap_without_db(&auth)
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| Route::create_multiple(routes, c))
        .await
        .into_json()
}

#[get("/route/<route_id>")]
pub async fn get_route(
    route_id: UnverifiedId<RouteId>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Route> {
    let route_id = conn
        .run(move |c| route_id.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(move |c| Route::get_by_id(route_id, c))
        .await
        .into_json()
}

#[get("/route")]
pub async fn get_routes(auth: AuthUserOrAP, conn: Db) -> JsonResult<Vec<Route>> {
    conn.run(move |c| Route::get_by_user(*auth, c))
        .await
        .into_json()
}

#[put("/route", format = "application/json", data = "<route>")]
pub async fn update_route(
    route: Unverified<Route>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Route> {
    let route = conn
        .run(move |c| route.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| Route::update(route, c)).await.into_json()
}

#[put("/routes", format = "application/json", data = "<routes>")]
pub async fn update_routes(
    routes: Unverified<Vec<Route>>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Vec<Route>> {
    let routes = conn
        .run(move |c| routes.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| Route::update_multiple(routes, c))
        .await
        .into_json()
}

#[post(
    "/cardio_blueprint",
    format = "application/json",
    data = "<cardio_blueprint>"
)]
pub async fn create_cardio_blueprint(
    cardio_blueprint: Unverified<CardioBlueprint>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<CardioBlueprint> {
    let cardio_blueprint = cardio_blueprint
        .verify_user_ap_without_db(&auth)
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| CardioBlueprint::create(cardio_blueprint, c))
        .await
        .into_json()
}

#[post(
    "/cardio_blueprints",
    format = "application/json",
    data = "<cardio_blueprints>"
)]
pub async fn create_cardio_blueprints(
    cardio_blueprints: Unverified<Vec<CardioBlueprint>>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Vec<CardioBlueprint>> {
    let cardio_blueprints =
        cardio_blueprints
            .verify_user_ap_without_db(&auth)
            .map_err(|status| JsonError {
                status,
                message: None,
            })?;
    conn.run(|c| CardioBlueprint::create_multiple(cardio_blueprints, c))
        .await
        .into_json()
}

#[get("/cardio_blueprint/<cardio_blueprint_id>")]
pub async fn get_cardio_blueprint(
    cardio_blueprint_id: UnverifiedId<CardioBlueprintId>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<CardioBlueprint> {
    let cardio_blueprint_id = conn
        .run(move |c| cardio_blueprint_id.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(move |c| CardioBlueprint::get_by_id(cardio_blueprint_id, c))
        .await
        .into_json()
}

#[get("/cardio_blueprint")]
pub async fn get_cardio_blueprints(
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Vec<CardioBlueprint>> {
    conn.run(move |c| CardioBlueprint::get_by_user(*auth, c))
        .await
        .into_json()
}

#[put(
    "/cardio_blueprint",
    format = "application/json",
    data = "<cardio_blueprint>"
)]
pub async fn update_cardio_blueprint(
    cardio_blueprint: Unverified<CardioBlueprint>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<CardioBlueprint> {
    let cardio_blueprint = conn
        .run(move |c| cardio_blueprint.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| CardioBlueprint::update(cardio_blueprint, c))
        .await
        .into_json()
}

#[put(
    "/cardio_blueprints",
    format = "application/json",
    data = "<cardio_blueprints>"
)]
pub async fn update_cardio_blueprints(
    cardio_blueprints: Unverified<Vec<CardioBlueprint>>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Vec<CardioBlueprint>> {
    let cardio_blueprints = conn
        .run(move |c| cardio_blueprints.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| CardioBlueprint::update_multiple(cardio_blueprints, c))
        .await
        .into_json()
}

#[post(
    "/cardio_session",
    format = "application/json",
    data = "<cardio_session>"
)]
pub async fn create_cardio_session(
    cardio_session: Unverified<CardioSession>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<CardioSession> {
    let cardio_session = cardio_session
        .verify_user_ap_without_db(&auth)
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| CardioSession::create(cardio_session, c))
        .await
        .into_json()
}

#[post(
    "/cardio_sessions",
    format = "application/json",
    data = "<cardio_sessions>"
)]
pub async fn create_cardio_sessions(
    cardio_sessions: Unverified<Vec<CardioSession>>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Vec<CardioSession>> {
    let cardio_sessions = cardio_sessions
        .verify_user_ap_without_db(&auth)
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| CardioSession::create_multiple(cardio_sessions, c))
        .await
        .into_json()
}

#[get("/cardio_session/<cardio_session_id>")]
pub async fn get_cardio_session(
    cardio_session_id: UnverifiedId<CardioSessionId>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<CardioSession> {
    let cardio_session_id = conn
        .run(move |c| cardio_session_id.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(move |c| CardioSession::get_by_id(cardio_session_id, c))
        .await
        .into_json()
}

#[get("/cardio_session")]
pub async fn get_cardio_sessions(auth: AuthUserOrAP, conn: Db) -> JsonResult<Vec<CardioSession>> {
    conn.run(move |c| CardioSession::get_by_user(*auth, c))
        .await
        .into_json()
}

#[put(
    "/cardio_session",
    format = "application/json",
    data = "<cardio_session>"
)]
pub async fn update_cardio_session(
    cardio_session: Unverified<CardioSession>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<CardioSession> {
    let cardio_session = conn
        .run(move |c| cardio_session.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| CardioSession::update(cardio_session, c))
        .await
        .into_json()
}

#[put(
    "/cardio_sessions",
    format = "application/json",
    data = "<cardio_sessions>"
)]
pub async fn update_cardio_sessions(
    cardio_sessions: Unverified<Vec<CardioSession>>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Vec<CardioSession>> {
    let cardio_sessions = conn
        .run(move |c| cardio_sessions.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| CardioSession::update_multiple(cardio_sessions, c))
        .await
        .into_json()
}

#[get("/cardio_session_description/<cardio_session_id>")]
pub async fn get_cardio_session_description(
    cardio_session_id: UnverifiedId<CardioSessionId>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<CardioSessionDescription> {
    let cardio_session_id = conn
        .run(move |c| cardio_session_id.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(move |c| CardioSessionDescription::get_by_id(cardio_session_id, c))
        .await
        .into_json()
}

#[get("/cardio_session_description")]
pub async fn get_cardio_session_descriptions(
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Vec<CardioSessionDescription>> {
    conn.run(move |c| CardioSessionDescription::get_by_user(*auth, c))
        .await
        .into_json()
}

#[get("/cardio_session_description/timespan/<start_datetime>/<end_datetime>")]
pub async fn get_ordered_cardio_session_descriptions_by_timespan(
    start_datetime: DateTimeWrapper,
    end_datetime: DateTimeWrapper,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Vec<CardioSessionDescription>> {
    conn.run(move |c| {
        CardioSessionDescription::get_ordered_by_user_and_timespan(
            *auth,
            *start_datetime,
            *end_datetime,
            c,
        )
    })
    .await
    .into_json()
}
