use axum::{extract::Query, http::StatusCode, Json};
use sport_log_types::{
    Metcon, MetconId, MetconMovement, MetconMovementId, MetconSession, MetconSessionId,
};

use crate::{
    auth::AuthUserOrAP,
    db::*,
    handler::{HandlerResult, IdOption, UnverifiedSingleOrVec},
    state::DbConn,
};

pub async fn create_metcon_sessions(
    auth: AuthUserOrAP,
    mut db: DbConn,
    Json(metcon_sessions): Json<UnverifiedSingleOrVec<MetconSession>>,
) -> HandlerResult<StatusCode> {
    match metcon_sessions {
        UnverifiedSingleOrVec::Single(metcon_session) => {
            let metcon_session = metcon_session.verify_user_ap_without_db(auth)?;
            MetconSessionDb::create(&metcon_session, &mut db)
        }
        UnverifiedSingleOrVec::Vec(metcon_sessions) => {
            let metcon_sessions = metcon_sessions.verify_user_ap_without_db(auth)?;
            MetconSessionDb::create_multiple(&metcon_sessions, &mut db)
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

pub async fn get_metcon_sessions(
    auth: AuthUserOrAP,
    Query(IdOption { id }): Query<IdOption<UnverifiedId<MetconSessionId>>>,
    mut db: DbConn,
) -> HandlerResult<Json<Vec<MetconSession>>> {
    match id {
        Some(id) => {
            let metcon_session_id = id.verify_user_ap(auth, &mut db)?;
            MetconSessionDb::get_by_id(metcon_session_id, &mut db).map(|m| vec![m])
        }
        None => MetconSessionDb::get_by_user(*auth, &mut db),
    }
    .map(Json)
    .map_err(Into::into)
}

pub async fn update_metcon_sessions(
    auth: AuthUserOrAP,
    mut db: DbConn,
    Json(metcon_sessions): Json<UnverifiedSingleOrVec<MetconSession>>,
) -> HandlerResult<StatusCode> {
    match metcon_sessions {
        UnverifiedSingleOrVec::Single(metcon_session) => {
            let metcon_session = metcon_session.verify_user_ap(auth, &mut db)?;
            MetconSessionDb::update(&metcon_session, &mut db)
        }
        UnverifiedSingleOrVec::Vec(metcon_sessions) => {
            let metcon_sessions = metcon_sessions.verify_user_ap(auth, &mut db)?;
            MetconSessionDb::update_multiple(&metcon_sessions, &mut db)
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

pub async fn create_metcons(
    auth: AuthUserOrAP,
    mut db: DbConn,
    Json(metcons): Json<UnverifiedSingleOrVec<Metcon>>,
) -> HandlerResult<StatusCode> {
    match metcons {
        UnverifiedSingleOrVec::Single(metcon) => {
            let metcon = metcon.verify_user_ap_without_db(auth)?;
            MetconDb::create(&metcon, &mut db)
        }
        UnverifiedSingleOrVec::Vec(metcons) => {
            let metcons = metcons.verify_user_ap_without_db(auth)?;
            MetconDb::create_multiple(&metcons, &mut db)
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

pub async fn get_metcons(
    auth: AuthUserOrAP,
    Query(IdOption { id }): Query<IdOption<UnverifiedId<MetconId>>>,
    mut db: DbConn,
) -> HandlerResult<Json<Vec<Metcon>>> {
    match id {
        Some(id) => {
            let metcon_id = id.verify_user_ap(auth, &mut db)?;
            MetconDb::get_by_id(metcon_id, &mut db).map(|m| vec![m])
        }
        None => MetconDb::get_by_user(*auth, &mut db),
    }
    .map(Json)
    .map_err(Into::into)
}

pub async fn update_metcons(
    auth: AuthUserOrAP,
    mut db: DbConn,
    Json(metcons): Json<UnverifiedSingleOrVec<Metcon>>,
) -> HandlerResult<StatusCode> {
    match metcons {
        UnverifiedSingleOrVec::Single(metcon) => {
            let metcon = metcon.verify_user_ap(auth, &mut db)?;
            MetconDb::update(&metcon, &mut db)
        }
        UnverifiedSingleOrVec::Vec(metcons) => {
            let metcons = metcons.verify_user_ap(auth, &mut db)?;
            MetconDb::update_multiple(&metcons, &mut db)
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

pub async fn create_metcon_movements(
    auth: AuthUserOrAP,
    mut db: DbConn,
    Json(metcon_movements): Json<UnverifiedSingleOrVec<MetconMovement>>,
) -> HandlerResult<StatusCode> {
    match metcon_movements {
        UnverifiedSingleOrVec::Single(metcon_movement) => {
            let metcon_movement = metcon_movement.verify_user_ap_create(auth, &mut db)?;
            MetconMovementDb::create(&metcon_movement, &mut db)
        }
        UnverifiedSingleOrVec::Vec(metcon_movements) => {
            let metcon_movements = metcon_movements.verify_user_ap_create(auth, &mut db)?;
            MetconMovementDb::create_multiple(&metcon_movements, &mut db)
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

pub async fn get_metcon_movements(
    auth: AuthUserOrAP,
    Query(IdOption { id }): Query<IdOption<UnverifiedId<MetconMovementId>>>,
    mut db: DbConn,
) -> HandlerResult<Json<Vec<MetconMovement>>> {
    match id {
        Some(id) => {
            let metcon_movement_id = id.verify_user_ap(auth, &mut db)?;
            MetconMovementDb::get_by_id(metcon_movement_id, &mut db).map(|m| vec![m])
        }
        None => MetconMovementDb::get_by_user(*auth, &mut db),
    }
    .map(Json)
    .map_err(Into::into)
}

////#[get("/metcon_movement/metcon/<metcon_id>")]
//pub async fn get_metcon_movements_by_metcon(
//auth: AuthUserOrAP,
//Path(metcon_id): Path<UnverifiedId<MetconId>>,
//mut db: DbConn,
//) -> HandlerResult<Json<Vec<MetconMovement>>> {
//let metcon_id = metcon_id.verify_user_ap(auth, &mut db).map_err(Error::from)?;
//MetconMovementDb::get_by_metcon(metcon_id, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

pub async fn update_metcon_movements(
    auth: AuthUserOrAP,
    mut db: DbConn,
    Json(metcon_movements): Json<UnverifiedSingleOrVec<MetconMovement>>,
) -> HandlerResult<StatusCode> {
    match metcon_movements {
        UnverifiedSingleOrVec::Single(metcon_movement) => {
            let metcon_movement = metcon_movement.verify_user_ap(auth, &mut db)?;
            MetconMovementDb::update(&metcon_movement, &mut db)
        }
        UnverifiedSingleOrVec::Vec(metcon_movements) => {
            let metcon_movements = metcon_movements.verify_user_ap(auth, &mut db)?;
            MetconMovementDb::update_multiple(&metcon_movements, &mut db)
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

//#[post("/metcon_item", format = "application/json", data = "<metcon_item>")]
//pub async fn create_metcon_item(
//auth: AuthUserOrAP,
//mut db: DbConn,
//Json(metcon_item): Json<Unverified<MetconItem>>,
//) -> HandlerResult<Json<MetconItem>> {
//let metcon_item = metcon_item
//.verify_user_ap_create(auth, &mut db)
//.map_err(Error::from)?;
//MetconItemDb::create(&metcon_item, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

//#[post("/metcon_items", format = "application/json", data = "<metcon_items>")]
//pub async fn create_metcon_items(
//auth: AuthUserOrAP,
//mut db: DbConn,
//Json(metcon_items): Json<UnverifiedSingleOrVec<MetconItem>>>,
//) -> HandlerResult<Json<Vec<MetconItem>>> {
//let metcon_items = metcon_items
//.verify_user_ap_create(auth, &mut db)
//;
//MetconItemDb::create_multiple(&metcon_items, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

////#[get("/metcon_item/<metcon_item_id>")]
//pub async fn get_metcon_item(
//auth: AuthUserOrAP,
//Path(metcon_item_id): Path<UnverifiedId<MetconItemId>>,
//mut db: DbConn,
//) -> HandlerResult<Json<MetconItem>> {
//let metcon_item_id = metcon_item_id
//.verify_user_ap(auth, &mut db)
//;
//MetconItemDb::get_by_id(metcon_item_id, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

////#[get("/metcon_item")]
//pub async fn get_metcon_items(
//auth: AuthUserOrAP,
//mut db: DbConn,
//) -> HandlerResult<Json<Vec<MetconItem>>> {
//MetconItemDb::get_by_user(*auth, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

//#[put("/metcon_item", format = "application/json", data = "<metcon_item>")]
//pub async fn update_metcon_item(
//auth: AuthUserOrAP,
//mut db: DbConn,
//Json(metcon_item): Json<Unverified<MetconItem>>,
//) -> HandlerResult<Json<MetconItem>> {
//let metcon_item = metcon_item.verify_user_ap(auth, &mut db).map_err(Error::from)?;
//MetconItemDb::update(&metcon_item, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

//#[put("/metcon_items", format = "application/json", data = "<metcon_items>")]
//pub async fn update_metcon_items(
//auth: AuthUserOrAP,
//mut db: DbConn,
//Json(metcon_items): Json<UnverifiedSingleOrVec<MetconItem>>>,
//) -> HandlerResult<Json<Vec<MetconItem>>> {
//let metcon_items = metcon_items
//.verify_user_ap(auth, &mut db)
//;
//MetconItemDb::update_multiple(&metcon_items, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

////#[get("/metcon_session_description/<metcon_session_id>")]
//pub async fn get_metcon_session_description(
//auth: AuthUserOrAP,
//Path(metcon_session_id): Path<UnverifiedId<MetconSessionId>>,
//mut db: DbConn,
//) -> HandlerResult<Json<MetconSessionDescription>> {
//let metcon_session_id = metcon_session_id
//.verify_user_ap(auth, &mut db)
//.map_err(Error::from)?;
//MetconSessionDescriptionDb::get_by_id(metcon_session_id, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

////#[get("/metcon_session_description")]
//pub async fn get_metcon_session_descriptions(
//auth: AuthUserOrAP,
//mut db: DbConn,
//) -> HandlerResult<Json<Vec<MetconSessionDescription>>> {
//MetconSessionDescriptionDb::get_by_user(*auth, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

////#[get("/metcon_session_description/timespan/<start_datetime>/<end_datetime>")]
//pub async fn get_ordered_metcon_session_descriptions_by_timespan(
//auth: AuthUserOrAP,
//Path(start_datetime): Path<DateTime<Utc>>,
//Path(end_datetime): Path<DateTime<Utc>>,
//mut db: DbConn,
//) -> HandlerResult<Json<Vec<MetconSessionDescription>>> {
//MetconSessionDescriptionDb::get_ordered_by_user_and_timespan(
//*auth,
//start_datetime,
//end_datetime,
//&mut db,
//)
//.map(Json)
//.map_err(Into::into)
//}
