use rocket::{http::Status, serde::json::Json};

use sport_log_types::{
    AuthenticatedUser, CardioSession, CardioSessionDescription, CardioSessionId, Create, Db,
    Delete, GetById, GetByUser, NewCardioSession, NewRoute, Route, RouteId, Unverified,
    UnverifiedId, Update, VerifyIdForUser,
};

use crate::handler::{IntoJson, NaiveDateTimeWrapper};

#[post("/route", format = "application/json", data = "<route>")]
pub async fn create_route(
    route: Unverified<NewRoute>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Route>, Status> {
    let route = route.verify(&auth)?;
    conn.run(|c| Route::create(route, c)).await.into_json()
}

#[get("/route/<route_id>")]
pub async fn get_route(
    route_id: UnverifiedId<RouteId>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Route>, Status> {
    let route_id = conn.run(move |c| route_id.verify(&auth, c)).await?;
    conn.run(move |c| Route::get_by_id(route_id, c))
        .await
        .into_json()
}

#[get("/route")]
pub async fn get_routes(auth: AuthenticatedUser, conn: Db) -> Result<Json<Vec<Route>>, Status> {
    conn.run(move |c| Route::get_by_user(*auth, c))
        .await
        .into_json()
}

#[put("/route", format = "application/json", data = "<route>")]
pub async fn update_route(
    route: Unverified<Route>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Route>, Status> {
    let route = conn.run(move |c| route.verify(&auth, c)).await?;
    conn.run(|c| Route::update(route, c)).await.into_json()
}

#[delete("/route/<route_id>")]
pub async fn delete_route(
    route_id: UnverifiedId<RouteId>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Status, Status> {
    conn.run(move |c| {
        Route::delete(route_id.verify(&auth, c)?, c)
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
    cardio_session: Unverified<NewCardioSession>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<CardioSession>, Status> {
    let cardio_session = cardio_session.verify(&auth)?;
    conn.run(|c| CardioSession::create(cardio_session, c))
        .await
        .into_json()
}

#[get("/cardio_session/<cardio_session_id>")]
pub async fn get_cardio_session(
    cardio_session_id: UnverifiedId<CardioSessionId>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<CardioSession>, Status> {
    let cardio_session_id = conn
        .run(move |c| cardio_session_id.verify(&auth, c))
        .await?;
    conn.run(move |c| CardioSession::get_by_id(cardio_session_id, c))
        .await
        .into_json()
}

#[get("/cardio_session")]
pub async fn get_cardio_sessions(
    auth: AuthenticatedUser,
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
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<CardioSession>, Status> {
    let cardio_session = conn.run(move |c| cardio_session.verify(&auth, c)).await?;
    conn.run(|c| CardioSession::update(cardio_session, c))
        .await
        .into_json()
}

#[delete("/cardio_session/<cardio_session_id>")]
pub async fn delete_cardio_session(
    cardio_session_id: UnverifiedId<CardioSessionId>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Status, Status> {
    conn.run(move |c| {
        CardioSession::delete(cardio_session_id.verify(&auth, c)?, c)
            .map(|_| Status::NoContent)
            .map_err(|_| Status::InternalServerError)
    })
    .await
}

#[get("/cardio_session_description/<cardio_session_id>")]
pub async fn get_cardio_session_description(
    cardio_session_id: UnverifiedId<CardioSessionId>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<CardioSessionDescription>, Status> {
    let cardio_session_id = conn
        .run(move |c| cardio_session_id.verify(&auth, c))
        .await?;
    conn.run(move |c| CardioSessionDescription::get_by_id(cardio_session_id, c))
        .await
        .into_json()
}

#[get("/cardio_session_description")]
pub async fn get_cardio_session_descriptions(
    auth: AuthenticatedUser,
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
    auth: AuthenticatedUser,
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
