use axum::{extract::Query, http::StatusCode, Json};
use sport_log_types::{
    AuthUserOrAP, Create, DbConn, GetById, GetByUser, StrengthSession, StrengthSessionId,
    StrengthSet, StrengthSetId, UnverifiedId, Update, VerifyForUserOrAPCreate,
    VerifyForUserOrAPWithDb, VerifyForUserOrAPWithoutDb, VerifyIdForUserOrAP,
    VerifyMultipleForUserOrAPCreate, VerifyMultipleForUserOrAPWithDb,
    VerifyMultipleForUserOrAPWithoutDb,
};

use crate::handler::{HandlerResult, IdOption, UnverifiedSingleOrVec};

//#[post(
//"/strength_blueprint",
//format = "application/json",
//data = "<strength_blueprint>"
//)]
//pub async fn create_strength_blueprint(
//auth: AuthUserOrAP,
//mut db: DbConn,
//Json(strength_blueprint): Json<Unverified<StrengthBlueprint>>,
//) -> HandlerResult<Json<StrengthBlueprint>> {
//let strength_blueprint = strength_blueprint
//.verify_user_ap_without_db(auth)
//.map_err(Error::from)?;
//StrengthBlueprint::create(strength_blueprint, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

////#[post(
////"/strength_blueprints",
////format = "application/json",
////data = "<strength_blueprints>"
////)]
//pub async fn create_strength_blueprints(
//auth: AuthUserOrAP,
//mut db: DbConn,
//Json(strength_blueprints): Json<UnverifiedSingleOrVec<StrengthBlueprint>>>,
//) -> HandlerResult<Json<Vec<StrengthBlueprint>>> {
//let strength_blueprint = strength_blueprints
//.verify_user_ap_without_db(auth)
//.map_err(Error::from)?;
//StrengthBlueprint::create_multiple(strength_blueprint, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

////#[get("/strength_blueprint/<strength_blueprint_id>")]
//pub async fn get_strength_blueprint(
//auth: AuthUserOrAP,
//Path(strength_blueprint_id): Path<UnverifiedId<StrengthBlueprintId>>,
//mut db: DbConn,
//) -> HandlerResult<Json<StrengthBlueprint>> {
//let strength_blueprint_id =
//strength_blueprint_id
//.verify_user_ap(auth, &mut db)
//.map_err(|status| Error {
//status,
//message: None,
//})?;
//StrengthBlueprint::get_by_id(strength_blueprint_id, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

////#[get("/strength_blueprint")]
//pub async fn get_strength_blueprints(
//auth: AuthUserOrAP,
//mut db: DbConn,
//) -> HandlerResult<Json<Vec<StrengthBlueprint>>> {
//StrengthBlueprint::get_by_user(*auth, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

////#[put(
////"/strength_blueprint",
////format = "application/json",
////data = "<strength_blueprint>"
////)]
//pub async fn update_strength_blueprint(
//auth: AuthUserOrAP,
//mut db: DbConn,
//Json(strength_blueprint): Json<Unverified<StrengthBlueprint>>,
//) -> HandlerResult<Json<StrengthBlueprint>> {
//let strength_blueprint = strength_blueprint
//.verify_user_ap(auth, &mut db)
//.map_err(Error::from)?;
//StrengthBlueprint::update(strength_blueprint, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

////#[put(
////"/strength_blueprints",
////format = "application/json",
////data = "<strength_blueprints>"
////)]
//pub async fn update_strength_blueprints(
//auth: AuthUserOrAP,
//mut db: DbConn,
//Json(strength_blueprints): Json<UnverifiedSingleOrVec<StrengthBlueprint>>>,
//) -> HandlerResult<Json<Vec<StrengthBlueprint>>> {
//let strength_blueprints = strength_blueprints
//.verify_user_ap(auth, &mut db)
//.map_err(Error::from)?;
//StrengthBlueprint::update_multiple(strength_blueprints, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

////#[post(
////"/strength_blueprint_set",
////format = "application/json",
////data = "<strength_blueprint_set>"
////)]
//pub async fn create_strength_blueprint_set(
//auth: AuthUserOrAP,
//mut db: DbConn,
//Json(strength_blueprint_set): Json<Unverified<StrengthBlueprintSet>>,
//) -> HandlerResult<Json<StrengthBlueprintSet>> {
//let strength_blueprint_set = strength_blueprint_set
//.verify_user_ap_create(auth, &mut db)
//.map_err(Error::from)?;
//StrengthBlueprintSet::create(strength_blueprint_set, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

////#[post(
////"/strength_blueprint_sets",
////format = "application/json",
////data = "<strength_blueprint_sets>"
////)]
//pub async fn create_strength_blueprint_sets(
//auth: AuthUserOrAP,
//mut db: DbConn,
//Json(strength_blueprint_sets): Json<UnverifiedSingleOrVec<StrengthBlueprintSet>>>,
//) -> HandlerResult<Json<Vec<StrengthBlueprintSet>>> {
//let strength_blueprint_set = strength_blueprint_sets
//.verify_user_ap_create(auth, &mut db)
//.map_err(Error::from)?;
//StrengthBlueprintSet::create_multiple(strength_blueprint_set, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

////#[get("/strength_blueprint_set/<strength_blueprint_set_id>")]
//pub async fn get_strength_blueprint_set(
//auth: AuthUserOrAP,
//Path(strength_blueprint_set_id): Path<UnverifiedId<StrengthBlueprintSetId>>,
//mut db: DbConn,
//) -> HandlerResult<Json<StrengthBlueprintSet>> {
//let strength_blueprint_set_id = strength_blueprint_set_id
//.verify_user_ap(auth, &mut db)
//.map_err(Error::from)?;
//StrengthBlueprintSet::get_by_id(strength_blueprint_set_id, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

////#[get("/strength_blueprint_set")]
//pub async fn get_strength_blueprint_sets(
//auth: AuthUserOrAP,
//mut db: DbConn,
//) -> HandlerResult<Json<Vec<StrengthBlueprintSet>>> {
//StrengthBlueprintSet::get_by_user(*auth, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

////#[get("/strength_blueprint_set/strength_blueprint/<strength_blueprint_id>")]
//pub async fn get_strength_blueprint_sets_by_strength_blueprint(
//auth: AuthUserOrAP,
//Path(strength_blueprint_id): Path<UnverifiedId<StrengthBlueprintId>>,
//mut db: DbConn,
//) -> HandlerResult<Json<Vec<StrengthBlueprintSet>>> {
//let strength_blueprint_id =
//strength_blueprint_id
//.verify_user_ap(auth, &mut db)
//.map_err(|status| Error {
//status,
//message: None,
//})?;
//StrengthBlueprintSet::get_by_strength_blueprint(strength_blueprint_id, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

////#[put(
////"/strength_blueprint_set",
////format = "application/json",
////data = "<strength_blueprint_set>"
////)]
//pub async fn update_strength_blueprint_set(
//auth: AuthUserOrAP,
//mut db: DbConn,
//Json(strength_blueprint_set): Json<Unverified<StrengthBlueprintSet>>,
//) -> HandlerResult<Json<StrengthBlueprintSet>> {
//let strength_blueprint_set =
//strength_blueprint_set
//.verify_user_ap(auth, &mut db)
//.map_err(|status| Error {
//status,
//message: None,
//})?;
//StrengthBlueprintSet::update(strength_blueprint_set, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

////#[put(
////"/strength_blueprint_sets",
////format = "application/json",
////data = "<strength_blueprint_sets>"
////)]
//pub async fn update_strength_blueprint_sets(
//auth: AuthUserOrAP,
//mut db: DbConn,
//Json(strength_blueprint_sets): Json<UnverifiedSingleOrVec<StrengthBlueprintSet>>>,
//) -> HandlerResult<Json<Vec<StrengthBlueprintSet>>> {
//let strength_blueprint_sets =
//strength_blueprint_sets
//.verify_user_ap(auth, &mut db)
//.map_err(|status| Error {
//status,
//message: None,
//})?;
//StrengthBlueprintSet::update_multiple(strength_blueprint_sets, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

pub async fn create_strength_sessions(
    auth: AuthUserOrAP,
    mut db: DbConn,
    Json(strength_sessions): Json<UnverifiedSingleOrVec<StrengthSession>>,
) -> HandlerResult<StatusCode> {
    match strength_sessions {
        UnverifiedSingleOrVec::Single(strength_session) => {
            let strength_session = strength_session.verify_user_ap_without_db(auth)?;
            StrengthSession::create(strength_session, &mut db)
        }
        UnverifiedSingleOrVec::Vec(strength_sessions) => {
            let strength_sessions = strength_sessions.verify_user_ap_without_db(auth)?;
            StrengthSession::create_multiple(strength_sessions, &mut db)
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

pub async fn get_strength_sessions(
    auth: AuthUserOrAP,
    Query(IdOption { id }): Query<IdOption<UnverifiedId<StrengthSessionId>>>,
    mut db: DbConn,
) -> HandlerResult<Json<Vec<StrengthSession>>> {
    match id {
        Some(id) => {
            let strength_session_id = id.verify_user_ap(auth, &mut db)?;
            StrengthSession::get_by_id(strength_session_id, &mut db).map(|s| vec![s])
        }
        None => StrengthSession::get_by_user(*auth, &mut db),
    }
    .map(Json)
    .map_err(Into::into)
}

pub async fn update_strength_sessions(
    auth: AuthUserOrAP,
    mut db: DbConn,
    Json(strength_sessions): Json<UnverifiedSingleOrVec<StrengthSession>>,
) -> HandlerResult<StatusCode> {
    match strength_sessions {
        UnverifiedSingleOrVec::Single(strength_session) => {
            let strength_session = strength_session.verify_user_ap(auth, &mut db)?;
            StrengthSession::update(strength_session, &mut db)
        }
        UnverifiedSingleOrVec::Vec(strength_sessions) => {
            let strength_sessions = strength_sessions.verify_user_ap(auth, &mut db)?;
            StrengthSession::update_multiple(strength_sessions, &mut db)
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

pub async fn create_strength_sets(
    auth: AuthUserOrAP,
    mut db: DbConn,
    Json(strength_sets): Json<UnverifiedSingleOrVec<StrengthSet>>,
) -> HandlerResult<StatusCode> {
    match strength_sets {
        UnverifiedSingleOrVec::Single(strength_set) => {
            let strength_set = strength_set.verify_user_ap_create(auth, &mut db)?;
            StrengthSet::create(strength_set, &mut db)
        }
        UnverifiedSingleOrVec::Vec(strength_sets) => {
            let strength_sets = strength_sets.verify_user_ap_create(auth, &mut db)?;
            StrengthSet::create_multiple(strength_sets, &mut db)
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

pub async fn get_strength_sets(
    auth: AuthUserOrAP,
    Query(IdOption { id }): Query<IdOption<UnverifiedId<StrengthSetId>>>,
    mut db: DbConn,
) -> HandlerResult<Json<Vec<StrengthSet>>> {
    match id {
        Some(id) => {
            let strength_set_id = id.verify_user_ap(auth, &mut db)?;
            StrengthSet::get_by_id(strength_set_id, &mut db).map(|s| vec![s])
        }
        None => StrengthSet::get_by_user(*auth, &mut db),
    }
    .map(Json)
    .map_err(Into::into)
}

//#[get("/strength_set/strength_session/<strength_session_id>")]
//pub async fn get_strength_sets_by_strength_session(
//auth: AuthUserOrAP,
//Path(strength_session_id): Path<UnverifiedId<StrengthSessionId>>,
//mut db: DbConn,
//) -> HandlerResult<Json<Vec<StrengthSet>>> {
//let strength_session_id = strength_session_id
//.verify_user_ap(auth, &mut db)
//.map_err(Error::from)?;
//StrengthSet::get_by_strength_session(strength_session_id, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

pub async fn update_strength_sets(
    auth: AuthUserOrAP,
    mut db: DbConn,
    Json(strength_sets): Json<UnverifiedSingleOrVec<StrengthSet>>,
) -> HandlerResult<StatusCode> {
    match strength_sets {
        UnverifiedSingleOrVec::Single(strength_set) => {
            let strength_set = strength_set.verify_user_ap(auth, &mut db)?;
            StrengthSet::update(strength_set, &mut db)
        }
        UnverifiedSingleOrVec::Vec(strength_sets) => {
            let strength_sets = strength_sets.verify_user_ap(auth, &mut db)?;
            StrengthSet::update_multiple(strength_sets, &mut db)
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

//#[get("/strength_session_description/<strength_session_id>")]
//pub async fn get_strength_session_description(
//auth: AuthUserOrAP,
//Path(strength_session_id): Path<UnverifiedId<StrengthSessionId>>,
//mut db: DbConn,
//) -> HandlerResult<Json<StrengthSessionDescription>> {
//let strength_session_id = strength_session_id
//.verify_user_ap(auth, &mut db)
//.map_err(Error::from)?;
//StrengthSessionDescription::get_by_id(strength_session_id, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

////#[get("/strength_session_description")]
//pub async fn get_strength_session_descriptions(
//auth: AuthUserOrAP,
//mut db: DbConn,
//) -> HandlerResult<Json<Vec<StrengthSessionDescription>>> {
//StrengthSessionDescription::get_by_user(*auth, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

////#[get("/strength_session_description/timespan/<start_datetime>/<end_datetime>")]
//pub async fn get_ordered_strength_session_descriptions_by_timespan(
//auth: AuthUserOrAP,
//Path(start_datetime): Path<DateTime<Utc>>,
//Path(end_datetime): Path<DateTime<Utc>>,
//mut db: DbConn,
//) -> HandlerResult<Json<Vec<StrengthSessionDescription>>> {
//StrengthSessionDescription::get_ordered_by_user_and_timespan(
//*auth,
//start_datetime,
//end_datetime,
//&mut db,
//)
//.map(Json)
//.map_err(Into::into)
//}
