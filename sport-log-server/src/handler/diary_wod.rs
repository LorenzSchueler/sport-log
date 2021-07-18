use rocket::{http::Status, serde::json::Json};

use crate::{
    auth::{AuthenticatedActionProvider, AuthenticatedUser},
    handler::IntoJson,
    types::{NewWod, Wod},
    types::{Unverified, UnverifiedWodId},
    Db,
};

#[post("/ap/wod", format = "application/json", data = "<wod>")]
pub async fn create_wod_ap(
    wod: Unverified<NewWod>,
    auth: AuthenticatedActionProvider,
    conn: Db,
) -> Result<Json<Wod>, Status> {
    let wod = wod.verify_ap(&auth)?;
    conn.run(|c| Wod::create(wod, c)).await.into_json()
}

#[post("/wod", format = "application/json", data = "<wod>")]
pub async fn create_wod(
    wod: Unverified<NewWod>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Wod>, Status> {
    let wod = wod.verify(&auth)?;
    conn.run(|c| Wod::create(wod, c)).await.into_json()
}

#[get("/wod")]
pub async fn get_wods_by_user(auth: AuthenticatedUser, conn: Db) -> Result<Json<Vec<Wod>>, Status> {
    conn.run(move |c| Wod::get_by_user(*auth, c))
        .await
        .into_json()
}

#[put("/wod", format = "application/json", data = "<wod>")]
pub async fn update_wod(
    wod: Unverified<Wod>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Wod>, Status> {
    let wod = conn.run(move |c| wod.verify(&auth, c)).await?;
    conn.run(|c| Wod::update(wod, c)).await.into_json()
}

#[delete("/wod/<wod_id>")]
pub async fn delete_wod(
    wod_id: UnverifiedWodId,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Status, Status> {
    conn.run(move |c| {
        Wod::delete(wod_id.verify(&auth, c)?, c)
            .map(|_| Status::NoContent)
            .map_err(|_| Status::InternalServerError)
    })
    .await
}
