use rocket::{http::Status, serde::json::Json};

use sport_log_types::{
    AuthUserOrAP, Create, CreateMultiple, Db, GetById, GetByUser, StrengthSession,
    StrengthSessionDescription, StrengthSessionId, StrengthSet, StrengthSetId, Unverified,
    UnverifiedId, Update, VerifyForUserOrAPWithDb, VerifyForUserOrAPWithoutDb, VerifyIdForUserOrAP,
    VerifyMultipleForUserOrAPWithDb, VerifyMultipleForUserOrAPWithoutDb,
};

use crate::handler::{DateTimeWrapper, IntoJson};

#[post(
    "/strength_session",
    format = "application/json",
    data = "<strength_session>"
)]
pub async fn create_strength_session(
    strength_session: Unverified<StrengthSession>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<StrengthSession>, Status> {
    let strength_session = strength_session.verify_user_ap_without_db(&auth)?;
    conn.run(|c| StrengthSession::create(strength_session, c))
        .await
        .into_json()
}

#[post(
    "/strength_session",
    format = "application/json",
    data = "<strength_sessions>",
    rank = 2
)]
pub async fn create_strength_sessions(
    strength_sessions: Unverified<Vec<StrengthSession>>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<Vec<StrengthSession>>, Status> {
    let strength_session = strength_sessions.verify_user_ap_without_db(&auth)?;
    conn.run(|c| StrengthSession::create_multiple(strength_session, c))
        .await
        .into_json()
}

#[get("/strength_session/<strength_session_id>")]
pub async fn get_strength_session(
    strength_session_id: UnverifiedId<StrengthSessionId>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<StrengthSession>, Status> {
    let strength_session_id = conn
        .run(move |c| strength_session_id.verify_user_ap(&auth, c))
        .await?;
    conn.run(move |c| StrengthSession::get_by_id(strength_session_id, c))
        .await
        .into_json()
}

#[get("/strength_session")]
pub async fn get_strength_sessions(
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<Vec<StrengthSession>>, Status> {
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
) -> Result<Json<StrengthSession>, Status> {
    let strength_session = conn
        .run(move |c| strength_session.verify_user_ap(&auth, c))
        .await?;
    conn.run(|c| StrengthSession::update(strength_session, c))
        .await
        .into_json()
}

#[put(
    "/strength_session",
    format = "application/json",
    data = "<strength_sessions>",
    rank = 2
)]
pub async fn update_strength_sessions(
    strength_sessions: Unverified<Vec<StrengthSession>>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<Vec<StrengthSession>>, Status> {
    let strength_sessions = conn
        .run(move |c| strength_sessions.verify_user_ap(&auth, c))
        .await?;
    conn.run(|c| StrengthSession::update_multiple(strength_sessions, c))
        .await
        .into_json()
}

#[post("/strength_set", format = "application/json", data = "<strength_set>")]
pub async fn create_strength_set(
    strength_set: Unverified<StrengthSet>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<StrengthSet>, Status> {
    let strength_set = conn
        .run(move |c| strength_set.verify_user_ap(&auth, c))
        .await?;
    conn.run(|c| StrengthSet::create(strength_set, c))
        .await
        .into_json()
}

#[post(
    "/strength_set",
    format = "application/json",
    data = "<strength_sets>",
    rank = 2
)]
pub async fn create_strength_sets(
    strength_sets: Unverified<Vec<StrengthSet>>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<Vec<StrengthSet>>, Status> {
    let strength_set = conn
        .run(move |c| strength_sets.verify_user_ap(&auth, c))
        .await?;
    conn.run(|c| StrengthSet::create_multiple(strength_set, c))
        .await
        .into_json()
}

#[get("/strength_set/<strength_set_id>")]
pub async fn get_strength_set(
    strength_set_id: UnverifiedId<StrengthSetId>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<StrengthSet>, Status> {
    let strength_set_id = conn
        .run(move |c| strength_set_id.verify_user_ap(&auth, c))
        .await?;
    conn.run(move |c| StrengthSet::get_by_id(strength_set_id, c))
        .await
        .into_json()
}

#[get("/strength_set/strength_session/<strength_session_id>")]
pub async fn get_strength_sets_by_strength_session(
    strength_session_id: UnverifiedId<StrengthSessionId>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<Vec<StrengthSet>>, Status> {
    let strength_session_id = conn
        .run(move |c| strength_session_id.verify_user_ap(&auth, c))
        .await?;
    conn.run(move |c| StrengthSet::get_by_strength_session(strength_session_id, c))
        .await
        .into_json()
}

#[put("/strength_set", format = "application/json", data = "<strength_set>")]
pub async fn update_strength_set(
    strength_set: Unverified<StrengthSet>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<StrengthSet>, Status> {
    let strength_set = conn
        .run(move |c| strength_set.verify_user_ap(&auth, c))
        .await?;
    conn.run(|c| StrengthSet::update(strength_set, c))
        .await
        .into_json()
}

#[put(
    "/strength_set",
    format = "application/json",
    data = "<strength_sets>",
    rank = 2
)]
pub async fn update_strength_sets(
    strength_sets: Unverified<Vec<StrengthSet>>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<Vec<StrengthSet>>, Status> {
    let strength_sets = conn
        .run(move |c| strength_sets.verify_user_ap(&auth, c))
        .await?;
    conn.run(|c| StrengthSet::update_multiple(strength_sets, c))
        .await
        .into_json()
}

#[get("/strength_session_description/<strength_session_id>")]
pub async fn get_strength_session_description(
    strength_session_id: UnverifiedId<StrengthSessionId>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<StrengthSessionDescription>, Status> {
    let strength_session_id = conn
        .run(move |c| strength_session_id.verify_user_ap(&auth, c))
        .await?;
    conn.run(move |c| StrengthSessionDescription::get_by_id(strength_session_id, c))
        .await
        .into_json()
}

#[get("/strength_session_description")]
pub async fn get_strength_session_descriptions(
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<Vec<StrengthSessionDescription>>, Status> {
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
) -> Result<Json<Vec<StrengthSessionDescription>>, Status> {
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
