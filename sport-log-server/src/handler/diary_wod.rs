use rocket::{http::Status, serde::json::Json};

use crate::{
    auth::{AuthenticatedActionProvider, AuthenticatedUser},
    handler::IntoJson,
    model::{NewWod, Wod},
    verification::UnverifiedWodId,
    Db,
};

#[post("/wod", format = "application/json", data = "<wod>")]
pub async fn create_wod(
    wod: Json<NewWod>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Wod>, Status> {
    let wod = NewWod::verify(wod, &auth)?;
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
    wod: Json<Wod>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Wod>, Status> {
    let wod = conn.run(move |c| Wod::verify(wod, &auth, c)).await?;
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
