use sport_log_types::{
    AuthUserOrAP, Create, CreateMultiple, Db, Eorm, GetAll, GetById, GetByUser, Movement,
    MovementId, MovementMuscle, MovementMuscleId, MuscleGroup, Unverified, UnverifiedId, Update,
    VerifyForUserOrAPCreate, VerifyForUserOrAPWithDb, VerifyForUserOrAPWithoutDb,
    VerifyIdForUserOrAP, VerifyMultipleForUserOrAPCreate, VerifyMultipleForUserOrAPWithDb,
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

#[post(
    "/movement_muscle",
    format = "application/json",
    data = "<movement_muscle>"
)]
pub async fn create_movement_muscle(
    movement_muscle: Unverified<MovementMuscle>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<MovementMuscle> {
    let movement_muscle = conn
        .run(move |c| movement_muscle.verify_user_ap_create(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| MovementMuscle::create(movement_muscle, c))
        .await
        .into_json()
}

#[post(
    "/movement_muscles",
    format = "application/json",
    data = "<movement_muscles>"
)]
pub async fn create_movement_muscles(
    movement_muscles: Unverified<Vec<MovementMuscle>>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Vec<MovementMuscle>> {
    let movement_muscles = conn
        .run(move |c| movement_muscles.verify_user_ap_create(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| MovementMuscle::create_multiple(movement_muscles, c))
        .await
        .into_json()
}

#[get("/movement_muscle/<movement_muscle_id>")]
pub async fn get_movement_muscle(
    movement_muscle_id: UnverifiedId<MovementMuscleId>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<MovementMuscle> {
    let movement_muscle_id = conn
        .run(move |c| movement_muscle_id.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(move |c| MovementMuscle::get_by_id(movement_muscle_id, c))
        .await
        .into_json()
}

#[get("/movement_muscle")]
pub async fn get_movement_muscles(auth: AuthUserOrAP, conn: Db) -> JsonResult<Vec<MovementMuscle>> {
    conn.run(move |c| MovementMuscle::get_by_user(*auth, c))
        .await
        .into_json()
}

#[put(
    "/movement_muscle",
    format = "application/json",
    data = "<movement_muscle>"
)]
pub async fn update_movement_muscle(
    movement_muscle: Unverified<MovementMuscle>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<MovementMuscle> {
    let movement_muscle = conn
        .run(move |c| movement_muscle.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| MovementMuscle::update(movement_muscle, c))
        .await
        .into_json()
}

#[put(
    "/movement_muscles",
    format = "application/json",
    data = "<movement_muscles>"
)]
pub async fn update_movement_muscles(
    movement_muscles: Unverified<Vec<MovementMuscle>>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Vec<MovementMuscle>> {
    let movement_muscles = conn
        .run(move |c| movement_muscles.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| MovementMuscle::update_multiple(movement_muscles, c))
        .await
        .into_json()
}

#[get("/muscle_group")]
pub async fn get_muscle_groups(_auth: AuthUserOrAP, conn: Db) -> JsonResult<Vec<MuscleGroup>> {
    conn.run(move |c| MuscleGroup::get_all(c)).await.into_json()
}

#[get("/eorm")]
pub async fn get_eorms(_auth: AuthUserOrAP, conn: Db) -> JsonResult<Vec<Eorm>> {
    conn.run(move |c| Eorm::get_all(c)).await.into_json()
}
