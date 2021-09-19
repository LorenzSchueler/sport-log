use sport_log_types::{
    AuthUserOrAP, Create, CreateMultiple, Db, GetById, GetByUser, StrengthBlueprint,
    StrengthBlueprintId, StrengthBlueprintSet, StrengthBlueprintSetId, StrengthSession,
    StrengthSessionDescription, StrengthSessionId, StrengthSet, StrengthSetId, Unverified,
    UnverifiedId, Update, VerifyForUserOrAPWithDb, VerifyForUserOrAPWithoutDb, VerifyIdForUserOrAP,
    VerifyMultipleForUserOrAPWithDb, VerifyMultipleForUserOrAPWithoutDb,
};

use crate::handler::{DateTimeWrapper, IntoJson, JsonError, JsonResult};

#[post(
    "/strength_blueprint",
    format = "application/json",
    data = "<strength_blueprint>"
)]
pub async fn create_strength_blueprint(
    strength_blueprint: Unverified<StrengthBlueprint>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<StrengthBlueprint> {
    let strength_blueprint = strength_blueprint
        .verify_user_ap_without_db(&auth)
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| StrengthBlueprint::create(strength_blueprint, c))
        .await
        .into_json()
}

#[post(
    "/strength_blueprints",
    format = "application/json",
    data = "<strength_blueprints>"
)]
pub async fn create_strength_blueprints(
    strength_blueprints: Unverified<Vec<StrengthBlueprint>>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Vec<StrengthBlueprint>> {
    let strength_blueprint = strength_blueprints
        .verify_user_ap_without_db(&auth)
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| StrengthBlueprint::create_multiple(strength_blueprint, c))
        .await
        .into_json()
}

#[get("/strength_blueprint/<strength_blueprint_id>")]
pub async fn get_strength_blueprint(
    strength_blueprint_id: UnverifiedId<StrengthBlueprintId>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<StrengthBlueprint> {
    let strength_blueprint_id = conn
        .run(move |c| strength_blueprint_id.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(move |c| StrengthBlueprint::get_by_id(strength_blueprint_id, c))
        .await
        .into_json()
}

#[get("/strength_blueprint")]
pub async fn get_strength_blueprints(
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Vec<StrengthBlueprint>> {
    conn.run(move |c| StrengthBlueprint::get_by_user(*auth, c))
        .await
        .into_json()
}

#[put(
    "/strength_blueprint",
    format = "application/json",
    data = "<strength_blueprint>"
)]
pub async fn update_strength_blueprint(
    strength_blueprint: Unverified<StrengthBlueprint>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<StrengthBlueprint> {
    let strength_blueprint = conn
        .run(move |c| strength_blueprint.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| StrengthBlueprint::update(strength_blueprint, c))
        .await
        .into_json()
}

#[put(
    "/strength_blueprints",
    format = "application/json",
    data = "<strength_blueprints>"
)]
pub async fn update_strength_blueprints(
    strength_blueprints: Unverified<Vec<StrengthBlueprint>>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Vec<StrengthBlueprint>> {
    let strength_blueprints = conn
        .run(move |c| strength_blueprints.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| StrengthBlueprint::update_multiple(strength_blueprints, c))
        .await
        .into_json()
}

#[post(
    "/strength_blueprint_set",
    format = "application/json",
    data = "<strength_blueprint_set>"
)]
pub async fn create_strength_blueprint_set(
    strength_blueprint_set: Unverified<StrengthBlueprintSet>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<StrengthBlueprintSet> {
    let strength_blueprint_set = conn
        .run(move |c| strength_blueprint_set.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| StrengthBlueprintSet::create(strength_blueprint_set, c))
        .await
        .into_json()
}

#[post(
    "/strength_blueprint_sets",
    format = "application/json",
    data = "<strength_blueprint_sets>"
)]
pub async fn create_strength_blueprint_sets(
    strength_blueprint_sets: Unverified<Vec<StrengthBlueprintSet>>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Vec<StrengthBlueprintSet>> {
    let strength_blueprint_set = conn
        .run(move |c| strength_blueprint_sets.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| StrengthBlueprintSet::create_multiple(strength_blueprint_set, c))
        .await
        .into_json()
}

#[get("/strength_blueprint_set/<strength_blueprint_set_id>")]
pub async fn get_strength_blueprint_set(
    strength_blueprint_set_id: UnverifiedId<StrengthBlueprintSetId>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<StrengthBlueprintSet> {
    let strength_blueprint_set_id = conn
        .run(move |c| strength_blueprint_set_id.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(move |c| StrengthBlueprintSet::get_by_id(strength_blueprint_set_id, c))
        .await
        .into_json()
}

#[get("/strength_blueprint_set")]
pub async fn get_strength_blueprint_sets(
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Vec<StrengthBlueprintSet>> {
    conn.run(move |c| StrengthBlueprintSet::get_by_user(*auth, c))
        .await
        .into_json()
}

#[get("/strength_blueprint_set/strength_blueprint/<strength_blueprint_id>")]
pub async fn get_strength_blueprint_sets_by_strength_blueprint(
    strength_blueprint_id: UnverifiedId<StrengthBlueprintId>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Vec<StrengthBlueprintSet>> {
    let strength_blueprint_id = conn
        .run(move |c| strength_blueprint_id.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(move |c| StrengthBlueprintSet::get_by_strength_blueprint(strength_blueprint_id, c))
        .await
        .into_json()
}

#[put(
    "/strength_blueprint_set",
    format = "application/json",
    data = "<strength_blueprint_set>"
)]
pub async fn update_strength_blueprint_set(
    strength_blueprint_set: Unverified<StrengthBlueprintSet>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<StrengthBlueprintSet> {
    let strength_blueprint_set = conn
        .run(move |c| strength_blueprint_set.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| StrengthBlueprintSet::update(strength_blueprint_set, c))
        .await
        .into_json()
}

#[put(
    "/strength_blueprint_sets",
    format = "application/json",
    data = "<strength_blueprint_sets>"
)]
pub async fn update_strength_blueprint_sets(
    strength_blueprint_sets: Unverified<Vec<StrengthBlueprintSet>>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Vec<StrengthBlueprintSet>> {
    let strength_blueprint_sets = conn
        .run(move |c| strength_blueprint_sets.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| StrengthBlueprintSet::update_multiple(strength_blueprint_sets, c))
        .await
        .into_json()
}

#[post(
    "/strength_session",
    format = "application/json",
    data = "<strength_session>"
)]
pub async fn create_strength_session(
    strength_session: Unverified<StrengthSession>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<StrengthSession> {
    let strength_session = strength_session
        .verify_user_ap_without_db(&auth)
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| StrengthSession::create(strength_session, c))
        .await
        .into_json()
}

#[post(
    "/strength_sessions",
    format = "application/json",
    data = "<strength_sessions>"
)]
pub async fn create_strength_sessions(
    strength_sessions: Unverified<Vec<StrengthSession>>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Vec<StrengthSession>> {
    let strength_session =
        strength_sessions
            .verify_user_ap_without_db(&auth)
            .map_err(|status| JsonError {
                status,
                message: None,
            })?;
    conn.run(|c| StrengthSession::create_multiple(strength_session, c))
        .await
        .into_json()
}

#[get("/strength_session/<strength_session_id>")]
pub async fn get_strength_session(
    strength_session_id: UnverifiedId<StrengthSessionId>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<StrengthSession> {
    let strength_session_id = conn
        .run(move |c| strength_session_id.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(move |c| StrengthSession::get_by_id(strength_session_id, c))
        .await
        .into_json()
}

#[get("/strength_session")]
pub async fn get_strength_sessions(
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Vec<StrengthSession>> {
    conn.run(move |c| StrengthSession::get_by_user(*auth, c))
        .await
        .into_json()
}

#[put(
    "/strength_session",
    format = "application/json",
    data = "<strength_session>"
)]
pub async fn update_strength_session(
    strength_session: Unverified<StrengthSession>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<StrengthSession> {
    let strength_session = conn
        .run(move |c| strength_session.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| StrengthSession::update(strength_session, c))
        .await
        .into_json()
}

#[put(
    "/strength_sessions",
    format = "application/json",
    data = "<strength_sessions>"
)]
pub async fn update_strength_sessions(
    strength_sessions: Unverified<Vec<StrengthSession>>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Vec<StrengthSession>> {
    let strength_sessions = conn
        .run(move |c| strength_sessions.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| StrengthSession::update_multiple(strength_sessions, c))
        .await
        .into_json()
}

#[post("/strength_set", format = "application/json", data = "<strength_set>")]
pub async fn create_strength_set(
    strength_set: Unverified<StrengthSet>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<StrengthSet> {
    let strength_set = conn
        .run(move |c| strength_set.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| StrengthSet::create(strength_set, c))
        .await
        .into_json()
}

#[post(
    "/strength_sets",
    format = "application/json",
    data = "<strength_sets>"
)]
pub async fn create_strength_sets(
    strength_sets: Unverified<Vec<StrengthSet>>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Vec<StrengthSet>> {
    let strength_set = conn
        .run(move |c| strength_sets.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| StrengthSet::create_multiple(strength_set, c))
        .await
        .into_json()
}

#[get("/strength_set/<strength_set_id>")]
pub async fn get_strength_set(
    strength_set_id: UnverifiedId<StrengthSetId>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<StrengthSet> {
    let strength_set_id = conn
        .run(move |c| strength_set_id.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(move |c| StrengthSet::get_by_id(strength_set_id, c))
        .await
        .into_json()
}

#[get("/strength_set")]
pub async fn get_strength_sets(auth: AuthUserOrAP, conn: Db) -> JsonResult<Vec<StrengthSet>> {
    conn.run(move |c| StrengthSet::get_by_user(*auth, c))
        .await
        .into_json()
}

#[get("/strength_set/strength_session/<strength_session_id>")]
pub async fn get_strength_sets_by_strength_session(
    strength_session_id: UnverifiedId<StrengthSessionId>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Vec<StrengthSet>> {
    let strength_session_id = conn
        .run(move |c| strength_session_id.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(move |c| StrengthSet::get_by_strength_session(strength_session_id, c))
        .await
        .into_json()
}

#[put("/strength_set", format = "application/json", data = "<strength_set>")]
pub async fn update_strength_set(
    strength_set: Unverified<StrengthSet>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<StrengthSet> {
    let strength_set = conn
        .run(move |c| strength_set.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| StrengthSet::update(strength_set, c))
        .await
        .into_json()
}

#[put(
    "/strength_sets",
    format = "application/json",
    data = "<strength_sets>"
)]
pub async fn update_strength_sets(
    strength_sets: Unverified<Vec<StrengthSet>>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Vec<StrengthSet>> {
    let strength_sets = conn
        .run(move |c| strength_sets.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| StrengthSet::update_multiple(strength_sets, c))
        .await
        .into_json()
}

#[get("/strength_session_description/<strength_session_id>")]
pub async fn get_strength_session_description(
    strength_session_id: UnverifiedId<StrengthSessionId>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<StrengthSessionDescription> {
    let strength_session_id = conn
        .run(move |c| strength_session_id.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(move |c| StrengthSessionDescription::get_by_id(strength_session_id, c))
        .await
        .into_json()
}

#[get("/strength_session_description")]
pub async fn get_strength_session_descriptions(
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Vec<StrengthSessionDescription>> {
    conn.run(move |c| StrengthSessionDescription::get_by_user(*auth, c))
        .await
        .into_json()
}

#[get("/strength_session_description/timespan/<start_datetime>/<end_datetime>")]
pub async fn get_ordered_strength_session_descriptions_by_timespan(
    start_datetime: DateTimeWrapper,
    end_datetime: DateTimeWrapper,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Vec<StrengthSessionDescription>> {
    conn.run(move |c| {
        StrengthSessionDescription::get_ordered_by_user_and_timespan(
            *auth,
            *start_datetime,
            *end_datetime,
            c,
        )
    })
    .await
    .into_json()
}
