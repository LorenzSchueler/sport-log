use axum::{extract::Query, http::StatusCode, Json};
use sport_log_types::{Eorm, StrengthSession, StrengthSessionId, StrengthSet, StrengthSetId};

use crate::{
    auth::AuthUserOrAP,
    db::*,
    handler::{HandlerResult, IdOption, TimeSpanOption, UnverifiedSingleOrVec},
    state::DbConn,
};

//pub async fn create_strength_blueprint(
//auth: AuthUserOrAP,
//mut db: DbConn,
//Json(strength_blueprint): Json<Unverified<StrengthBlueprint>>,
//) -> HandlerResult<Json<StrengthBlueprint>> {
//let strength_blueprint = strength_blueprint
//.verify_user_ap_without_db(auth)
//.map_err(Error::from)?;
//StrengthBlueprintDb::create(&strength_blueprint, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

//pub async fn create_strength_blueprints(
//auth: AuthUserOrAP,
//mut db: DbConn,
//Json(strength_blueprints): Json<UnverifiedSingleOrVec<StrengthBlueprint>>>,
//) -> HandlerResult<Json<Vec<StrengthBlueprint>>> {
//let strength_blueprint = strength_blueprints
//.verify_user_ap_without_db(auth)
//.map_err(Error::from)?;
//StrengthBlueprintDb::create_multiple(&strength_blueprint, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

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
//StrengthBlueprintDb::get_by_id(strength_blueprint_id, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

//pub async fn get_strength_blueprints(
//auth: AuthUserOrAP,
//mut db: DbConn,
//) -> HandlerResult<Json<Vec<StrengthBlueprint>>> {
//StrengthBlueprintDb::get_by_user(*auth, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

//pub async fn update_strength_blueprint(
//auth: AuthUserOrAP,
//mut db: DbConn,
//Json(strength_blueprint): Json<Unverified<StrengthBlueprint>>,
//) -> HandlerResult<Json<StrengthBlueprint>> {
//let strength_blueprint = strength_blueprint
//.verify_user_ap(auth, &mut db)
//.map_err(Error::from)?;
//StrengthBlueprintDb::update(&strength_blueprint, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

//pub async fn update_strength_blueprints(
//auth: AuthUserOrAP,
//mut db: DbConn,
//Json(strength_blueprints): Json<UnverifiedSingleOrVec<StrengthBlueprint>>>,
//) -> HandlerResult<Json<Vec<StrengthBlueprint>>> {
//let strength_blueprints = strength_blueprints
//.verify_user_ap(auth, &mut db)
//.map_err(Error::from)?;
//StrengthBlueprintDb::update_multiple(&strength_blueprints, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

//pub async fn create_strength_blueprint_set(
//auth: AuthUserOrAP,
//mut db: DbConn,
//Json(strength_blueprint_set): Json<Unverified<StrengthBlueprintSet>>,
//) -> HandlerResult<Json<StrengthBlueprintSet>> {
//let strength_blueprint_set = strength_blueprint_set
//.verify_user_ap_create(auth, &mut db)
//.map_err(Error::from)?;
//StrengthBlueprintSetDb::create(&strength_blueprint_set, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

//pub async fn create_strength_blueprint_sets(
//auth: AuthUserOrAP,
//mut db: DbConn,
//Json(strength_blueprint_sets): Json<UnverifiedSingleOrVec<StrengthBlueprintSet>>>,
//) -> HandlerResult<Json<Vec<StrengthBlueprintSet>>> {
//let strength_blueprint_set = strength_blueprint_sets
//.verify_user_ap_create(auth, &mut db)
//.map_err(Error::from)?;
//StrengthBlueprintSetDb::create_multiple(&strength_blueprint_set, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

//pub async fn get_strength_blueprint_set(
//auth: AuthUserOrAP,
//Path(strength_blueprint_set_id): Path<UnverifiedId<StrengthBlueprintSetId>>,
//mut db: DbConn,
//) -> HandlerResult<Json<StrengthBlueprintSet>> {
//let strength_blueprint_set_id = strength_blueprint_set_id
//.verify_user_ap(auth, &mut db)
//.map_err(Error::from)?;
//StrengthBlueprintSetDb::get_by_id(strength_blueprint_set_id, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

//pub async fn get_strength_blueprint_sets(
//auth: AuthUserOrAP,
//mut db: DbConn,
//) -> HandlerResult<Json<Vec<StrengthBlueprintSet>>> {
//StrengthBlueprintSetDb::get_by_user(*auth, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

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
//StrengthBlueprintSetDb::get_by_strength_blueprint(strength_blueprint_id, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

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
//StrengthBlueprintSetDb::update(&strength_blueprint_set, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

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
//StrengthBlueprintSetDb::update_multiple(&strength_blueprint_sets, &mut db)
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
            StrengthSessionDb::create(&strength_session, &mut db).await
        }
        UnverifiedSingleOrVec::Vec(strength_sessions) => {
            let strength_sessions = strength_sessions.verify_user_ap_without_db(auth)?;
            StrengthSessionDb::create_multiple(&strength_sessions, &mut db).await
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

pub async fn get_strength_sessions(
    auth: AuthUserOrAP,
    Query(IdOption { id }): Query<IdOption<UnverifiedId<StrengthSessionId>>>,
    Query(time_span_option): Query<TimeSpanOption>,
    mut db: DbConn,
) -> HandlerResult<Json<Vec<StrengthSession>>> {
    match id {
        Some(id) => {
            let strength_session_id = id.verify_user_ap(auth, &mut db).await?;
            StrengthSessionDb::get_by_id(strength_session_id, &mut db)
                .await
                .map(|s| vec![s])
        }
        None => {
            StrengthSessionDb::get_by_user_and_timespan(*auth, time_span_option.into(), &mut db)
                .await
        }
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
            let strength_session = strength_session.verify_user_ap(auth, &mut db).await?;
            StrengthSessionDb::update(&strength_session, &mut db).await
        }
        UnverifiedSingleOrVec::Vec(strength_sessions) => {
            let strength_sessions = strength_sessions.verify_user_ap(auth, &mut db).await?;
            StrengthSessionDb::update_multiple(&strength_sessions, &mut db).await
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
            let strength_set = strength_set.verify_user_ap_create(auth, &mut db).await?;
            StrengthSetDb::create(&strength_set, &mut db).await
        }
        UnverifiedSingleOrVec::Vec(strength_sets) => {
            let strength_sets = strength_sets.verify_user_ap_create(auth, &mut db).await?;
            StrengthSetDb::create_multiple(&strength_sets, &mut db).await
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
            let strength_set_id = id.verify_user_ap(auth, &mut db).await?;
            StrengthSetDb::get_by_id(strength_set_id, &mut db)
                .await
                .map(|s| vec![s])
        }
        None => StrengthSetDb::get_by_user(*auth, &mut db).await,
    }
    .map(Json)
    .map_err(Into::into)
}

//pub async fn get_strength_sets_by_strength_session(
//auth: AuthUserOrAP,
//Path(strength_session_id): Path<UnverifiedId<StrengthSessionId>>,
//mut db: DbConn,
//) -> HandlerResult<Json<Vec<StrengthSet>>> {
//let strength_session_id = strength_session_id
//.verify_user_ap(auth, &mut db)
//.map_err(Error::from)?;
//StrengthSetDb::get_by_strength_session(strength_session_id, &mut db)
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
            let strength_set = strength_set.verify_user_ap(auth, &mut db).await?;
            StrengthSetDb::update(&strength_set, &mut db).await
        }
        UnverifiedSingleOrVec::Vec(strength_sets) => {
            let strength_sets = strength_sets.verify_user_ap(auth, &mut db).await?;
            StrengthSetDb::update_multiple(&strength_sets, &mut db).await
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

pub async fn get_eorms(_auth: AuthUserOrAP, mut db: DbConn) -> HandlerResult<Json<Vec<Eorm>>> {
    EormDb::get_all(&mut db).await.map(Json).map_err(Into::into)
}
