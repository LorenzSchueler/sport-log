use rocket::{http::Status, serde::json::Json};

use sport_log_types::{
    AuthUserOrAP, Create, CreateMultiple, Db, GetById, GetByUser, Metcon, MetconId, MetconMovement,
    MetconMovementId, MetconSession, MetconSessionDescription, MetconSessionId, Unverified,
    UnverifiedId, UnverifiedIds, Update, VerifyForUserOrAPWithDb, VerifyForUserOrAPWithoutDb,
    VerifyIdForUserOrAP, VerifyIdsForUserOrAP, VerifyMultipleForUserOrAPWithDb,
    VerifyMultipleForUserOrAPWithoutDb,
};

use crate::handler::{DateTimeWrapper, IntoJson};

#[post(
    "/metcon_session",
    format = "application/json",
    data = "<metcon_session>"
)]
pub async fn create_metcon_session(
    metcon_session: Unverified<MetconSession>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<MetconSession>, Status> {
    let metcon_session = metcon_session.verify_user_ap_without_db(&auth)?;
    conn.run(|c| MetconSession::create(metcon_session, c))
        .await
        .into_json()
}

#[post(
    "/metcon_sessions",
    format = "application/json",
    data = "<metcon_sessions>"
)]
pub async fn create_metcon_sessions(
    metcon_sessions: Unverified<Vec<MetconSession>>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<Vec<MetconSession>>, Status> {
    let metcon_sessions = metcon_sessions.verify_user_ap_without_db(&auth)?;
    conn.run(|c| MetconSession::create_multiple(metcon_sessions, c))
        .await
        .into_json()
}

#[get("/metcon_session/<metcon_session_id>")]
pub async fn get_metcon_session(
    metcon_session_id: UnverifiedId<MetconSessionId>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<MetconSession>, Status> {
    let metcon_session_id = conn
        .run(move |c| metcon_session_id.verify_user_ap(&auth, c))
        .await?;
    conn.run(move |c| MetconSession::get_by_id(metcon_session_id, c))
        .await
        .into_json()
}

#[get("/metcon_session")]
pub async fn get_metcon_sessions(
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<Vec<MetconSession>>, Status> {
    conn.run(move |c| MetconSession::get_by_user(*auth, c))
        .await
        .into_json()
}

#[put(
    "/metcon_session",
    format = "application/json",
    data = "<metcon_session>"
)]
pub async fn update_metcon_session(
    metcon_session: Unverified<MetconSession>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<MetconSession>, Status> {
    let metcon_session = conn
        .run(move |c| metcon_session.verify_user_ap(&auth, c))
        .await?;
    conn.run(|c| MetconSession::update(metcon_session, c))
        .await
        .into_json()
}

#[post("/metcon", format = "application/json", data = "<metcon>")]
pub async fn create_metcon(
    metcon: Unverified<Metcon>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<Metcon>, Status> {
    let metcon = metcon.verify_user_ap_without_db(&auth)?;
    conn.run(|c| Metcon::create(metcon, c)).await.into_json()
}

#[post("/metcons", format = "application/json", data = "<metcons>")]
pub async fn create_metcons(
    metcons: Unverified<Vec<Metcon>>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<Vec<Metcon>>, Status> {
    let metcons = metcons.verify_user_ap_without_db(&auth)?;
    conn.run(|c| Metcon::create_multiple(metcons, c))
        .await
        .into_json()
}

#[get("/metcon/<metcon_id>")]
pub async fn get_metcon(
    metcon_id: UnverifiedId<MetconId>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<Metcon>, Status> {
    let metcon_id = conn
        .run(move |c| metcon_id.verify_user_ap(&auth, c))
        .await?;
    conn.run(move |c| Metcon::get_by_id(metcon_id, c))
        .await
        .into_json()
}

#[get("/metcon")]
pub async fn get_metcons(auth: AuthUserOrAP, conn: Db) -> Result<Json<Vec<Metcon>>, Status> {
    conn.run(move |c| Metcon::get_by_user(*auth, c))
        .await
        .into_json()
}

#[put("/metcon", format = "application/json", data = "<metcon>")]
pub async fn update_metcon(
    metcon: Unverified<Metcon>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<Metcon>, Status> {
    let metcon = conn.run(move |c| metcon.verify_user_ap(&auth, c)).await?;
    conn.run(|c| Metcon::update(metcon, c)).await.into_json()
}

#[post(
    "/metcon_movement",
    format = "application/json",
    data = "<metcon_movement>"
)]
pub async fn create_metcon_movement(
    metcon_movement: Unverified<MetconMovement>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<MetconMovement>, Status> {
    let metcon_movement = conn
        .run(move |c| metcon_movement.verify_user_ap(&auth, c))
        .await?;
    conn.run(|c| MetconMovement::create(metcon_movement, c))
        .await
        .into_json()
}

#[post(
    "/metcon_movements",
    format = "application/json",
    data = "<metcon_movements>"
)]
pub async fn create_metcon_movements(
    metcon_movements: Unverified<Vec<MetconMovement>>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<Vec<MetconMovement>>, Status> {
    let metcon_movements = conn
        .run(move |c| metcon_movements.verify_user_ap(&auth, c))
        .await?;
    conn.run(|c| MetconMovement::create_multiple(metcon_movements, c))
        .await
        .into_json()
}

#[get("/metcon_movement/<metcon_movement_id>")]
pub async fn get_metcon_movement(
    metcon_movement_id: UnverifiedId<MetconMovementId>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<MetconMovement>, Status> {
    let metcon_movement_id = conn
        .run(move |c| metcon_movement_id.verify_if_owned(&auth, c))
        .await?;
    conn.run(move |c| MetconMovement::get_by_id(metcon_movement_id, c))
        .await
        .into_json()
}

#[get("/metcon_movement/metcon/<metcon_id>")]
pub async fn get_metcon_movements_by_metcon(
    metcon_id: UnverifiedId<MetconId>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<Vec<MetconMovement>>, Status> {
    let metcon_id = conn
        .run(move |c| metcon_id.verify_user_ap(&auth, c))
        .await?;
    conn.run(move |c| MetconMovement::get_by_metcon(metcon_id, c))
        .await
        .into_json()
}

#[put(
    "/metcon_movement",
    format = "application/json",
    data = "<metcon_movement>"
)]
pub async fn update_metcon_movement(
    metcon_movement: Unverified<MetconMovement>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<MetconMovement>, Status> {
    let metcon_movement = conn
        .run(move |c| metcon_movement.verify_user_ap(&auth, c))
        .await?;
    conn.run(|c| MetconMovement::update(metcon_movement, c))
        .await
        .into_json()
}

#[get("/metcon_session_description/<metcon_session_id>")]
pub async fn get_metcon_session_description(
    metcon_session_id: UnverifiedId<MetconSessionId>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<MetconSessionDescription>, Status> {
    let metcon_session_id = conn
        .run(move |c| metcon_session_id.verify_user_ap(&auth, c))
        .await?;
    conn.run(move |c| MetconSessionDescription::get_by_id(metcon_session_id, c))
        .await
        .into_json()
}

#[get("/metcon_session_description")]
pub async fn get_metcon_session_descriptions(
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<Vec<MetconSessionDescription>>, Status> {
    conn.run(move |c| MetconSessionDescription::get_by_user(*auth, c))
        .await
        .into_json()
}

#[get("/metcon_session_description/timespan/<start_datetime>/<end_datetime>")]
pub async fn get_ordered_metcon_session_descriptions_by_timespan(
    start_datetime: DateTimeWrapper,
    end_datetime: DateTimeWrapper,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<Vec<MetconSessionDescription>>, Status> {
    conn.run(move |c| {
        MetconSessionDescription::get_ordered_by_user_and_timespan(
            *auth,
            *start_datetime,
            *end_datetime,
            c,
        )
    })
    .await
    .into_json()
}
