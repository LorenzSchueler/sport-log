use sport_log_types::{
    AuthUserOrAP, Create, CreateMultiple, Db, GetById, GetByUser, Metcon, MetconId, MetconItem,
    MetconItemId, MetconMovement, MetconMovementId, MetconSession, MetconSessionDescription,
    MetconSessionId, Unverified, UnverifiedId, Update, VerifyForUserOrAPWithDb,
    VerifyForUserOrAPWithoutDb, VerifyIdForUserOrAP, VerifyMultipleForUserOrAPWithDb,
    VerifyMultipleForUserOrAPWithoutDb,
};

use crate::handler::{DateTimeWrapper, IntoJson, JsonError, JsonResult};

#[post(
    "/metcon_session",
    format = "application/json",
    data = "<metcon_session>"
)]
pub async fn create_metcon_session(
    metcon_session: Unverified<MetconSession>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<MetconSession> {
    let metcon_session = metcon_session
        .verify_user_ap_without_db(&auth)
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
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
) -> JsonResult<Vec<MetconSession>> {
    let metcon_sessions = metcon_sessions
        .verify_user_ap_without_db(&auth)
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| MetconSession::create_multiple(metcon_sessions, c))
        .await
        .into_json()
}

#[get("/metcon_session/<metcon_session_id>")]
pub async fn get_metcon_session(
    metcon_session_id: UnverifiedId<MetconSessionId>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<MetconSession> {
    let metcon_session_id = conn
        .run(move |c| metcon_session_id.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(move |c| MetconSession::get_by_id(metcon_session_id, c))
        .await
        .into_json()
}

#[get("/metcon_session")]
pub async fn get_metcon_sessions(auth: AuthUserOrAP, conn: Db) -> JsonResult<Vec<MetconSession>> {
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
) -> JsonResult<MetconSession> {
    let metcon_session = conn
        .run(move |c| metcon_session.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| MetconSession::update(metcon_session, c))
        .await
        .into_json()
}

#[put(
    "/metcon_sessions",
    format = "application/json",
    data = "<metcon_sessions>"
)]
pub async fn update_metcon_sessions(
    metcon_sessions: Unverified<Vec<MetconSession>>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Vec<MetconSession>> {
    let metcon_sessions = conn
        .run(move |c| metcon_sessions.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| MetconSession::update_multiple(metcon_sessions, c))
        .await
        .into_json()
}

#[post("/metcon", format = "application/json", data = "<metcon>")]
pub async fn create_metcon(
    metcon: Unverified<Metcon>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Metcon> {
    let metcon = metcon
        .verify_user_ap_without_db(&auth)
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| Metcon::create(metcon, c)).await.into_json()
}

#[post("/metcons", format = "application/json", data = "<metcons>")]
pub async fn create_metcons(
    metcons: Unverified<Vec<Metcon>>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Vec<Metcon>> {
    let metcons = metcons
        .verify_user_ap_without_db(&auth)
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| Metcon::create_multiple(metcons, c))
        .await
        .into_json()
}

#[get("/metcon/<metcon_id>")]
pub async fn get_metcon(
    metcon_id: UnverifiedId<MetconId>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Metcon> {
    let metcon_id = conn
        .run(move |c| metcon_id.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(move |c| Metcon::get_by_id(metcon_id, c))
        .await
        .into_json()
}

#[get("/metcon")]
pub async fn get_metcons(auth: AuthUserOrAP, conn: Db) -> JsonResult<Vec<Metcon>> {
    conn.run(move |c| Metcon::get_by_user(*auth, c))
        .await
        .into_json()
}

#[put("/metcon", format = "application/json", data = "<metcon>")]
pub async fn update_metcon(
    metcon: Unverified<Metcon>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Metcon> {
    let metcon = conn
        .run(move |c| metcon.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| Metcon::update(metcon, c)).await.into_json()
}

#[put("/metcons", format = "application/json", data = "<metcons>")]
pub async fn update_metcons(
    metcons: Unverified<Vec<Metcon>>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Vec<Metcon>> {
    let metcons = conn
        .run(move |c| metcons.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| Metcon::update_multiple(metcons, c))
        .await
        .into_json()
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
) -> JsonResult<MetconMovement> {
    let metcon_movement = conn
        .run(move |c| metcon_movement.verify_user_ap_create(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
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
) -> JsonResult<Vec<MetconMovement>> {
    let metcon_movements = conn
        .run(move |c| metcon_movements.verify_user_ap_create(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| MetconMovement::create_multiple(metcon_movements, c))
        .await
        .into_json()
}

#[get("/metcon_movement/<metcon_movement_id>")]
pub async fn get_metcon_movement(
    metcon_movement_id: UnverifiedId<MetconMovementId>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<MetconMovement> {
    let metcon_movement_id = conn
        .run(move |c| metcon_movement_id.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(move |c| MetconMovement::get_by_id(metcon_movement_id, c))
        .await
        .into_json()
}

#[get("/metcon_movement")]
pub async fn get_metcon_movements(auth: AuthUserOrAP, conn: Db) -> JsonResult<Vec<MetconMovement>> {
    conn.run(move |c| MetconMovement::get_by_user(*auth, c))
        .await
        .into_json()
}

#[get("/metcon_movement/metcon/<metcon_id>")]
pub async fn get_metcon_movements_by_metcon(
    metcon_id: UnverifiedId<MetconId>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Vec<MetconMovement>> {
    let metcon_id = conn
        .run(move |c| metcon_id.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
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
) -> JsonResult<MetconMovement> {
    let metcon_movement = conn
        .run(move |c| metcon_movement.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| MetconMovement::update(metcon_movement, c))
        .await
        .into_json()
}

#[put(
    "/metcon_movements",
    format = "application/json",
    data = "<metcon_movements>"
)]
pub async fn update_metcon_movements(
    metcon_movements: Unverified<Vec<MetconMovement>>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Vec<MetconMovement>> {
    let metcon_movements = conn
        .run(move |c| metcon_movements.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| MetconMovement::update_multiple(metcon_movements, c))
        .await
        .into_json()
}

#[post("/metcon_item", format = "application/json", data = "<metcon_item>")]
pub async fn create_metcon_item(
    metcon_item: Unverified<MetconItem>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<MetconItem> {
    let metcon_item = conn
        .run(move |c| metcon_item.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| MetconItem::create(metcon_item, c))
        .await
        .into_json()
}

#[post("/metcon_items", format = "application/json", data = "<metcon_items>")]
pub async fn create_metcon_items(
    metcon_items: Unverified<Vec<MetconItem>>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Vec<MetconItem>> {
    let metcon_items = conn
        .run(move |c| metcon_items.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| MetconItem::create_multiple(metcon_items, c))
        .await
        .into_json()
}

#[get("/metcon_item/<metcon_item_id>")]
pub async fn get_metcon_item(
    metcon_item_id: UnverifiedId<MetconItemId>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<MetconItem> {
    let metcon_item_id = conn
        .run(move |c| metcon_item_id.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(move |c| MetconItem::get_by_id(metcon_item_id, c))
        .await
        .into_json()
}

#[get("/metcon_item")]
pub async fn get_metcon_items(auth: AuthUserOrAP, conn: Db) -> JsonResult<Vec<MetconItem>> {
    conn.run(move |c| MetconItem::get_by_user(*auth, c))
        .await
        .into_json()
}

#[put("/metcon_item", format = "application/json", data = "<metcon_item>")]
pub async fn update_metcon_item(
    metcon_item: Unverified<MetconItem>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<MetconItem> {
    let metcon_item = conn
        .run(move |c| metcon_item.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| MetconItem::update(metcon_item, c))
        .await
        .into_json()
}

#[put("/metcon_items", format = "application/json", data = "<metcon_items>")]
pub async fn update_metcon_items(
    metcon_items: Unverified<Vec<MetconItem>>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Vec<MetconItem>> {
    let metcon_items = conn
        .run(move |c| metcon_items.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| MetconItem::update_multiple(metcon_items, c))
        .await
        .into_json()
}

#[get("/metcon_session_description/<metcon_session_id>")]
pub async fn get_metcon_session_description(
    metcon_session_id: UnverifiedId<MetconSessionId>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<MetconSessionDescription> {
    let metcon_session_id = conn
        .run(move |c| metcon_session_id.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(move |c| MetconSessionDescription::get_by_id(metcon_session_id, c))
        .await
        .into_json()
}

#[get("/metcon_session_description")]
pub async fn get_metcon_session_descriptions(
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Vec<MetconSessionDescription>> {
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
) -> JsonResult<Vec<MetconSessionDescription>> {
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
