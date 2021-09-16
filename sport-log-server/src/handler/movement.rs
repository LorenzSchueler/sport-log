use sport_log_types::{
    AuthUserOrAP, Create, CreateMultiple, Db, Eorm, GetAll, GetById, GetByUser, Movement,
    MovementId, Unverified, UnverifiedId, Update, VerifyForUserOrAPWithDb,
    VerifyForUserOrAPWithoutDb, VerifyIdForUserOrAP, VerifyMultipleForUserOrAPWithDb,
    VerifyMultipleForUserOrAPWithoutDb,
};

use crate::handler::{IntoJson, JsonError, JsonResult};

#[post("/movement", format = "application/json", data = "<movement>")]
pub async fn create_movement(
    movement: Unverified<Movement>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Movement> {
    let movement = movement
        .verify_user_ap_without_db(&auth)
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| Movement::create(movement, c))
        .await
        .into_json()
}

#[post("/movements", format = "application/json", data = "<movements>")]
pub async fn create_movements(
    movements: Unverified<Vec<Movement>>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Vec<Movement>> {
    let movements = movements
        .verify_user_ap_without_db(&auth)
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| Movement::create_multiple(movements, c))
        .await
        .into_json()
}

#[get("/movement/<movement_id>")]
pub async fn get_movement(
    movement_id: UnverifiedId<MovementId>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Movement> {
    let movement_id = conn
        .run(move |c| movement_id.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(move |c| Movement::get_by_id(movement_id, c))
        .await
        .into_json()
}

#[get("/movement")]
pub async fn get_movements(auth: AuthUserOrAP, conn: Db) -> JsonResult<Vec<Movement>> {
    conn.run(move |c| Movement::get_by_user(*auth, c))
        .await
        .into_json()
}

#[put("/movement", format = "application/json", data = "<movement>")]
pub async fn update_movement(
    movement: Unverified<Movement>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Movement> {
    let movement = conn
        .run(move |c| movement.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| Movement::update(movement, c))
        .await
        .into_json()
}

#[put("/movements", format = "application/json", data = "<movements>")]
pub async fn update_movements(
    movements: Unverified<Vec<Movement>>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Vec<Movement>> {
    let movements = conn
        .run(move |c| movements.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| Movement::update_multiple(movements, c))
        .await
        .into_json()
}

#[get("/eorm")]
pub async fn get_eorms(_auth: AuthUserOrAP, conn: Db) -> JsonResult<Vec<Eorm>> {
    conn.run(move |c| Eorm::get_all(c)).await.into_json()
}
