use rocket::{http::Status, serde::json::Json};

use sport_log_types::{
    AuthUserOrAP, CardioSession, CardioSessionDescription, CardioSessionId, Create, CreateMultiple,
    Db, Delete, DeleteMultiple, GetById, GetByUser, Route, RouteId, Unverified, UnverifiedId,
    UnverifiedIds, Update, VerifyForUserOrAPWithDb, VerifyForUserOrAPWithoutDb,
    VerifyIdForUserOrAP, VerifyIdsForUserOrAP, VerifyMultipleForUserOrAPWithoutDb,
};

use crate::handler::{IntoJson, NaiveDateTimeWrapper};

#[post("/route", format = "application/json", data = "<route>")]
pub async fn create_route(
    route: Unverified<Route>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<Route>, Status> {
    let route = route.verify_user_ap_without_db(&auth)?;
    conn.run(|c| Route::create(route, c)).await.into_json()
}

#[post("/routes", format = "application/json", data = "<routes>")]
pub async fn create_routes(
    routes: Unverified<Vec<Route>>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<Vec<Route>>, Status> {
    let routes = routes.verify_user_ap_without_db(&auth)?;
    conn.run(|c| Route::create_multiple(routes, c))
        .await
        .into_json()
}

#[get("/route/<route_id>")]
pub async fn get_route(
    route_id: UnverifiedId<RouteId>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<Route>, Status> {
    let route_id = conn.run(move |c| route_id.verify_user_ap(&auth, c)).await?;
    conn.run(move |c| Route::get_by_id(route_id, c))
        .await
        .into_json()
}

#[get("/route")]
pub async fn get_routes(auth: AuthUserOrAP, conn: Db) -> Result<Json<Vec<Route>>, Status> {
    conn.run(move |c| Route::get_by_user(*auth, c))
        .await
        .into_json()
}

#[put("/route", format = "application/json", data = "<route>")]
pub async fn update_route(
    route: Unverified<Route>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<Route>, Status> {
    let route = conn.run(move |c| route.verify_user_ap(&auth, c)).await?;
    conn.run(|c| Route::update(route, c)).await.into_json()
}

#[delete("/route/<route_id>")]
pub async fn delete_route(
    route_id: UnverifiedId<RouteId>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Status, Status> {
    conn.run(move |c| {
        Route::delete(route_id.verify_user_ap(&auth, c)?, c)
            .map(|_| Status::NoContent)
            .map_err(|_| Status::InternalServerError)
    })
    .await
}

#[delete("/routes", format = "application/json", data = "<route_ids>")]
pub async fn delete_routes(
    route_ids: UnverifiedIds<RouteId>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Status, Status> {
    conn.run(move |c| {
        Route::delete_multiple(route_ids.verify_user_ap(&auth, c)?, c)
            .map(|_| Status::NoContent)
            .map_err(|_| Status::InternalServerError)
    })
    .await
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
) -> Result<Json<CardioSession>, Status> {
    let cardio_session = cardio_session.verify_user_ap_without_db(&auth)?;
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
) -> Result<Json<Vec<CardioSession>>, Status> {
    let cardio_sessions = cardio_sessions.verify_user_ap_without_db(&auth)?;
    conn.run(|c| CardioSession::create_multiple(cardio_sessions, c))
        .await
        .into_json()
}

#[get("/cardio_session/<cardio_session_id>")]
pub async fn get_cardio_session(
    cardio_session_id: UnverifiedId<CardioSessionId>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<CardioSession>, Status> {
    let cardio_session_id = conn
        .run(move |c| cardio_session_id.verify_user_ap(&auth, c))
        .await?;
    conn.run(move |c| CardioSession::get_by_id(cardio_session_id, c))
        .await
        .into_json()
}

#[get("/cardio_session")]
pub async fn get_cardio_sessions(
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<Vec<CardioSession>>, Status> {
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
) -> Result<Json<CardioSession>, Status> {
    let cardio_session = conn
        .run(move |c| cardio_session.verify_user_ap(&auth, c))
        .await?;
    conn.run(|c| CardioSession::update(cardio_session, c))
        .await
        .into_json()
}

#[delete("/cardio_session/<cardio_session_id>")]
pub async fn delete_cardio_session(
    cardio_session_id: UnverifiedId<CardioSessionId>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Status, Status> {
    conn.run(move |c| {
        CardioSession::delete(cardio_session_id.verify_user_ap(&auth, c)?, c)
            .map(|_| Status::NoContent)
            .map_err(|_| Status::InternalServerError)
    })
    .await
}

#[delete(
    "/cardio_sessions",
    format = "application/json",
    data = "<cardio_session_ids>"
)]
pub async fn delete_cardio_sessions(
    cardio_session_ids: UnverifiedIds<CardioSessionId>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Status, Status> {
    conn.run(move |c| {
        CardioSession::delete_multiple(cardio_session_ids.verify_user_ap(&auth, c)?, c)
            .map(|_| Status::NoContent)
            .map_err(|_| Status::InternalServerError)
    })
    .await
}

#[get("/cardio_session_description/<cardio_session_id>")]
pub async fn get_cardio_session_description(
    cardio_session_id: UnverifiedId<CardioSessionId>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<CardioSessionDescription>, Status> {
    let cardio_session_id = conn
        .run(move |c| cardio_session_id.verify_user_ap(&auth, c))
        .await?;
    conn.run(move |c| CardioSessionDescription::get_by_id(cardio_session_id, c))
        .await
        .into_json()
}

#[get("/cardio_session_description")]
pub async fn get_cardio_session_descriptions(
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<Vec<CardioSessionDescription>>, Status> {
    conn.run(move |c| CardioSessionDescription::get_by_user(*auth, c))
        .await
        .into_json()
}

#[get("/cardio_session_description/timespan/<start_datetime>/<end_datetime>")]
pub async fn get_ordered_cardio_session_descriptions_by_timespan(
    start_datetime: NaiveDateTimeWrapper,
    end_datetime: NaiveDateTimeWrapper,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<Vec<CardioSessionDescription>>, Status> {
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
