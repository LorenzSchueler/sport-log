use rocket::{http::Status, serde::json::Json};

use sport_log_types::types::{
    AuthenticatedUser, Db, NewRoute, Route, RouteId, Unverified, UnverifiedId,
};

use crate::handler::IntoJson;

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
pub async fn get_routes_by_user(
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Vec<Route>>, Status> {
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
