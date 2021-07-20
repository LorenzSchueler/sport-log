use rocket::{http::Status, serde::json::Json};

use sport_log_types::types::{
    AuthenticatedUser, Db, Movement, MovementId, NewMovement, Unverified, UnverifiedId,
};

use crate::handler::IntoJson;

#[post("/movement", format = "application/json", data = "<movement>")]
pub async fn create_movement(
    movement: Unverified<NewMovement>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Movement>, Status> {
    let movement = movement.verify(&auth)?;
    conn.run(|c| Movement::create(movement, c))
        .await
        .into_json()
}

#[get("/movement/<movement_id>")]
pub async fn get_movement(
    movement_id: UnverifiedId<MovementId>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Movement>, Status> {
    let movement_id = conn
        .run(move |c| movement_id.verify_if_owned(&auth, c))
        .await?;
    conn.run(move |c| Movement::get_by_id(movement_id, c))
        .await
        .into_json()
}

#[get("/movement")]
pub async fn get_movements_by_user(
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Vec<Movement>>, Status> {
    conn.run(move |c| Movement::get_by_user(*auth, c))
        .await
        .into_json()
}

#[put("/movement", format = "application/json", data = "<movement>")]
pub async fn update_movement(
    movement: Unverified<Movement>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Movement>, Status> {
    let movement = conn.run(move |c| movement.verify(&auth, c)).await?;
    conn.run(|c| Movement::update(movement, c))
        .await
        .into_json()
}

#[delete("/movement/<movement_id>")]
pub async fn delete_movement(
    movement_id: UnverifiedId<MovementId>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Status, Status> {
    conn.run(move |c| {
        Movement::delete(movement_id.verify(&auth, c)?, c)
            .map(|_| Status::NoContent)
            .map_err(|_| Status::InternalServerError)
    })
    .await
}
