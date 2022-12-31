use axum::{extract::Query, http::StatusCode, Json};
use sport_log_types::{
    AuthUserOrAP, Create, DbConn, GetById, GetByUser, Metcon, MetconId, MetconMovement,
    MetconMovementId, MetconSession, MetconSessionId, UnverifiedId, Update,
    VerifyForUserOrAPCreate, VerifyForUserOrAPWithDb, VerifyForUserOrAPWithoutDb,
    VerifyIdForUserOrAP, VerifyMultipleForUserOrAPCreate, VerifyMultipleForUserOrAPWithDb,
    VerifyMultipleForUserOrAPWithoutDb,
};

use crate::handler::{HandlerResult, IdOption, UnverifiedSingleOrVec};

pub async fn create_metcon_sessions(
    auth: AuthUserOrAP,
    db: DbConn,
    Json(metcon_sessions): Json<UnverifiedSingleOrVec<MetconSession>>,
) -> HandlerResult<StatusCode> {
    match metcon_sessions {
        UnverifiedSingleOrVec::Single(metcon_session) => {
            let metcon_session = metcon_session.verify_user_ap_without_db(auth)?;
            MetconSession::create(metcon_session, &db)
        }
        UnverifiedSingleOrVec::Vec(metcon_sessions) => {
            let metcon_sessions = metcon_sessions.verify_user_ap_without_db(auth)?;
            MetconSession::create_multiple(metcon_sessions, &db)
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

pub async fn get_metcon_sessions(
    auth: AuthUserOrAP,
    Query(IdOption { id }): Query<IdOption<UnverifiedId<MetconSessionId>>>,
    db: DbConn,
) -> HandlerResult<Json<Vec<MetconSession>>> {
    match id {
        Some(id) => {
            let metcon_session_id = id.verify_user_ap(auth, &db)?;
            MetconSession::get_by_id(metcon_session_id, &db).map(|m| vec![m])
        }
        None => MetconSession::get_by_user(*auth, &db),
    }
    .map(Json)
    .map_err(Into::into)
}

pub async fn update_metcon_sessions(
    auth: AuthUserOrAP,
    db: DbConn,
    Json(metcon_sessions): Json<UnverifiedSingleOrVec<MetconSession>>,
) -> HandlerResult<StatusCode> {
    match metcon_sessions {
        UnverifiedSingleOrVec::Single(metcon_session) => {
            let metcon_session = metcon_session.verify_user_ap(auth, &db)?;
            MetconSession::update(metcon_session, &db)
        }
        UnverifiedSingleOrVec::Vec(metcon_sessions) => {
            let metcon_sessions = metcon_sessions.verify_user_ap(auth, &db)?;
            MetconSession::update_multiple(metcon_sessions, &db)
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

pub async fn create_metcons(
    auth: AuthUserOrAP,
    db: DbConn,
    Json(metcons): Json<UnverifiedSingleOrVec<Metcon>>,
) -> HandlerResult<StatusCode> {
    match metcons {
        UnverifiedSingleOrVec::Single(metcon) => {
            let metcon = metcon.verify_user_ap_without_db(auth)?;
            Metcon::create(metcon, &db)
        }
        UnverifiedSingleOrVec::Vec(metcons) => {
            let metcons = metcons.verify_user_ap_without_db(auth)?;
            Metcon::create_multiple(metcons, &db)
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

pub async fn get_metcons(
    auth: AuthUserOrAP,
    Query(IdOption { id }): Query<IdOption<UnverifiedId<MetconId>>>,
    db: DbConn,
) -> HandlerResult<Json<Vec<Metcon>>> {
    match id {
        Some(id) => {
            let metcon_id = id.verify_user_ap(auth, &db)?;
            Metcon::get_by_id(metcon_id, &db).map(|m| vec![m])
        }
        None => Metcon::get_by_user(*auth, &db),
    }
    .map(Json)
    .map_err(Into::into)
}

pub async fn update_metcons(
    auth: AuthUserOrAP,
    db: DbConn,
    Json(metcons): Json<UnverifiedSingleOrVec<Metcon>>,
) -> HandlerResult<StatusCode> {
    match metcons {
        UnverifiedSingleOrVec::Single(metcon) => {
            let metcon = metcon.verify_user_ap(auth, &db)?;
            Metcon::update(metcon, &db)
        }
        UnverifiedSingleOrVec::Vec(metcons) => {
            let metcons = metcons.verify_user_ap(auth, &db)?;
            Metcon::update_multiple(metcons, &db)
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

pub async fn create_metcon_movements(
    auth: AuthUserOrAP,
    db: DbConn,
    Json(metcon_movements): Json<UnverifiedSingleOrVec<MetconMovement>>,
) -> HandlerResult<StatusCode> {
    match metcon_movements {
        UnverifiedSingleOrVec::Single(metcon_movement) => {
            let metcon_movement = metcon_movement.verify_user_ap_create(auth, &db)?;
            MetconMovement::create(metcon_movement, &db)
        }
        UnverifiedSingleOrVec::Vec(metcon_movements) => {
            let metcon_movements = metcon_movements.verify_user_ap_create(auth, &db)?;
            MetconMovement::create_multiple(metcon_movements, &db)
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

pub async fn get_metcon_movements(
    auth: AuthUserOrAP,
    Query(IdOption { id }): Query<IdOption<UnverifiedId<MetconMovementId>>>,
    db: DbConn,
) -> HandlerResult<Json<Vec<MetconMovement>>> {
    match id {
        Some(id) => {
            let metcon_movement_id = id.verify_user_ap(auth, &db)?;
            MetconMovement::get_by_id(metcon_movement_id, &db).map(|m| vec![m])
        }
        None => MetconMovement::get_by_user(*auth, &db),
    }
    .map(Json)
    .map_err(Into::into)
}

////#[get("/metcon_movement/metcon/<metcon_id>")]
//pub async fn get_metcon_movements_by_metcon(
//auth: AuthUserOrAP,
//Path(metcon_id): Path<UnverifiedId<MetconId>>,
//db: DbConn,
//) -> HandlerResult<Json<Vec<MetconMovement>>> {
//let metcon_id = metcon_id.verify_user_ap(auth, &db).map_err(Error::from)?;
//MetconMovement::get_by_metcon(metcon_id, &db)
//.map(Json)
//.map_err(Into::into)
//}

pub async fn update_metcon_movements(
    auth: AuthUserOrAP,
    db: DbConn,
    Json(metcon_movements): Json<UnverifiedSingleOrVec<MetconMovement>>,
) -> HandlerResult<StatusCode> {
    match metcon_movements {
        UnverifiedSingleOrVec::Single(metcon_movement) => {
            let metcon_movement = metcon_movement.verify_user_ap(auth, &db)?;
            MetconMovement::update(metcon_movement, &db)
        }
        UnverifiedSingleOrVec::Vec(metcon_movements) => {
            let metcon_movements = metcon_movements.verify_user_ap(auth, &db)?;
            MetconMovement::update_multiple(metcon_movements, &db)
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

//#[post("/metcon_item", format = "application/json", data = "<metcon_item>")]
//pub async fn create_metcon_item(
//auth: AuthUserOrAP,
//db: DbConn,
//Json(metcon_item): Json<Unverified<MetconItem>>,
//) -> HandlerResult<Json<MetconItem>> {
//let metcon_item = metcon_item
//.verify_user_ap_create(auth, &db)
//.map_err(Error::from)?;
//MetconItem::create(metcon_item, &db)
//.map(Json)
//.map_err(Into::into)
//}

//#[post("/metcon_items", format = "application/json", data = "<metcon_items>")]
//pub async fn create_metcon_items(
//auth: AuthUserOrAP,
//db: DbConn,
//Json(metcon_items): Json<UnverifiedSingleOrVec<MetconItem>>>,
//) -> HandlerResult<Json<Vec<MetconItem>>> {
//let metcon_items = metcon_items
//.verify_user_ap_create(auth, &db)
//;
//MetconItem::create_multiple(metcon_items, &db)
//.map(Json)
//.map_err(Into::into)
//}

////#[get("/metcon_item/<metcon_item_id>")]
//pub async fn get_metcon_item(
//auth: AuthUserOrAP,
//Path(metcon_item_id): Path<UnverifiedId<MetconItemId>>,
//db: DbConn,
//) -> HandlerResult<Json<MetconItem>> {
//let metcon_item_id = metcon_item_id
//.verify_user_ap(auth, &db)
//;
//MetconItem::get_by_id(metcon_item_id, &db)
//.map(Json)
//.map_err(Into::into)
//}

////#[get("/metcon_item")]
//pub async fn get_metcon_items(
//auth: AuthUserOrAP,
//db: DbConn,
//) -> HandlerResult<Json<Vec<MetconItem>>> {
//MetconItem::get_by_user(*auth, &db)
//.map(Json)
//.map_err(Into::into)
//}

//#[put("/metcon_item", format = "application/json", data = "<metcon_item>")]
//pub async fn update_metcon_item(
//auth: AuthUserOrAP,
//db: DbConn,
//Json(metcon_item): Json<Unverified<MetconItem>>,
//) -> HandlerResult<Json<MetconItem>> {
//let metcon_item = metcon_item.verify_user_ap(auth, &db).map_err(Error::from)?;
//MetconItem::update(metcon_item, &db)
//.map(Json)
//.map_err(Into::into)
//}

//#[put("/metcon_items", format = "application/json", data = "<metcon_items>")]
//pub async fn update_metcon_items(
//auth: AuthUserOrAP,
//db: DbConn,
//Json(metcon_items): Json<UnverifiedSingleOrVec<MetconItem>>>,
//) -> HandlerResult<Json<Vec<MetconItem>>> {
//let metcon_items = metcon_items
//.verify_user_ap(auth, &db)
//;
//MetconItem::update_multiple(metcon_items, &db)
//.map(Json)
//.map_err(Into::into)
//}

////#[get("/metcon_session_description/<metcon_session_id>")]
//pub async fn get_metcon_session_description(
//auth: AuthUserOrAP,
//Path(metcon_session_id): Path<UnverifiedId<MetconSessionId>>,
//db: DbConn,
//) -> HandlerResult<Json<MetconSessionDescription>> {
//let metcon_session_id = metcon_session_id
//.verify_user_ap(auth, &db)
//.map_err(Error::from)?;
//MetconSessionDescription::get_by_id(metcon_session_id, &db)
//.map(Json)
//.map_err(Into::into)
//}

////#[get("/metcon_session_description")]
//pub async fn get_metcon_session_descriptions(
//auth: AuthUserOrAP,
//db: DbConn,
//) -> HandlerResult<Json<Vec<MetconSessionDescription>>> {
//MetconSessionDescription::get_by_user(*auth, &db)
//.map(Json)
//.map_err(Into::into)
//}

////#[get("/metcon_session_description/timespan/<start_datetime>/<end_datetime>")]
//pub async fn get_ordered_metcon_session_descriptions_by_timespan(
//auth: AuthUserOrAP,
//Path(start_datetime): Path<DateTime<Utc>>,
//Path(end_datetime): Path<DateTime<Utc>>,
//db: DbConn,
//) -> HandlerResult<Json<Vec<MetconSessionDescription>>> {
//MetconSessionDescription::get_ordered_by_user_and_timespan(
//*auth,
//start_datetime,
//end_datetime,
//&db,
//)
//.map(Json)
//.map_err(Into::into)
//}
