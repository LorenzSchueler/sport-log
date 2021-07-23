use rocket::{http::Status, serde::json::Json};

use sport_log_types::types::{
    AuthenticatedUser, Db, Metcon, MetconId, NewMetcon, Unverified, UnverifiedId,
};

use crate::handler::IntoJson;

#[post("/metcon", format = "application/json", data = "<metcon>")]
pub async fn create_metcon(
    metcon: Unverified<NewMetcon>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Metcon>, Status> {
    let metcon = metcon.verify(&auth)?;
    conn.run(|c| Metcon::create(metcon, c)).await.into_json()
}

#[get("/metcon/<metcon_id>")]
pub async fn get_metcon(
    metcon_id: UnverifiedId<MetconId>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Metcon>, Status> {
    let metcon_id = conn.run(move |c| metcon_id.verify(&auth, c)).await?;
    conn.run(move |c| Metcon::get_by_id(metcon_id, c))
        .await
        .into_json()
}

#[get("/metcon")]
pub async fn get_metcons_by_user(
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Vec<Metcon>>, Status> {
    conn.run(move |c| Metcon::get_by_user(*auth, c))
        .await
        .into_json()
}

#[put("/metcon", format = "application/json", data = "<metcon>")]
pub async fn update_metcon(
    metcon: Unverified<Metcon>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Metcon>, Status> {
    let metcon = conn.run(move |c| metcon.verify(&auth, c)).await?;
    conn.run(|c| Metcon::update(metcon, c)).await.into_json()
}

#[delete("/metcon/<metcon_id>")]
pub async fn delete_metcon(
    metcon_id: UnverifiedId<MetconId>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Status, Status> {
    conn.run(move |c| {
        Metcon::delete(metcon_id.verify(&auth, c)?, c)
            .map(|_| Status::NoContent)
            .map_err(|_| Status::InternalServerError)
    })
    .await
}
