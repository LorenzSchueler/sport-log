use rocket::{http::Status, serde::json::Json};

use sport_log_types::{
    AuthUserOrAP, Create, CreateMultiple, Db, Delete, DeleteMultiple, Eorm, GetAll, GetById,
    GetByUser, Movement, MovementId, Unverified, UnverifiedId, UnverifiedIds, Update,
    VerifyForUserOrAPWithDb, VerifyForUserOrAPWithoutDb, VerifyIdForUserOrAP, VerifyIdsForUserOrAP,
    VerifyMultipleForUserOrAPWithoutDb,
};

use crate::handler::IntoJson;

#[post("/movement", format = "application/json", data = "<movement>")]
pub async fn create_movement(
    movement: Unverified<Movement>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<Movement>, Status> {
    let movement = movement.verify_user_ap_without_db(&auth)?;
    conn.run(|c| Movement::create(movement, c))
        .await
        .into_json()
}

#[post("/movements", format = "application/json", data = "<movements>")]
pub async fn create_movements(
    movements: Unverified<Vec<Movement>>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<Vec<Movement>>, Status> {
    let movements = movements.verify_user_ap_without_db(&auth)?;
    conn.run(|c| Movement::create_multiple(movements, c))
        .await
        .into_json()
}

#[get("/movement/<movement_id>")]
pub async fn get_movement(
    movement_id: UnverifiedId<MovementId>,
    auth: AuthUserOrAP,
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
pub async fn get_movements(auth: AuthUserOrAP, conn: Db) -> Result<Json<Vec<Movement>>, Status> {
    conn.run(move |c| Movement::get_by_user(*auth, c))
        .await
        .into_json()
}

#[put("/movement", format = "application/json", data = "<movement>")]
pub async fn update_movement(
    movement: Unverified<Movement>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<Movement>, Status> {
    let movement = conn.run(move |c| movement.verify_user_ap(&auth, c)).await?;
    conn.run(|c| Movement::update(movement, c))
        .await
        .into_json()
}

#[get("/eorm")]
pub async fn get_eorms(_auth: AuthUserOrAP, conn: Db) -> Result<Json<Vec<Eorm>>, Status> {
    conn.run(move |c| Eorm::get_all(c)).await.into_json()
}
