use rocket::{http::Status, serde::json::Json};

use sport_log_types::{
    AuthUserOrAP, Create, CreateMultiple, Db, Delete, DeleteMultiple, GetById, GetByUser,
    NewStrengthSession, NewStrengthSet, StrengthSession, StrengthSessionDescription,
    StrengthSessionId, StrengthSet, StrengthSetId, Unverified, UnverifiedId, UnverifiedIds, Update,
    VerifyForUserOrAPWithDb, VerifyForUserOrAPWithoutDb, VerifyIdForUserOrAP, VerifyIdsForUserOrAP,
    VerifyMultipleForUserOrAPWithDb, VerifyMultipleForUserOrAPWithoutDb,
};

use crate::handler::{IntoJson, NaiveDateTimeWrapper};

#[post(
    "/strength_session",
    format = "application/json",
    data = "<strength_session>"
)]
pub async fn create_strength_session(
    strength_session: Unverified<NewStrengthSession>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<StrengthSession>, Status> {
    let strength_session = strength_session.verify(&auth)?;
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
    strength_sessions: Unverified<Vec<NewStrengthSession>>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<Vec<StrengthSession>>, Status> {
    let strength_session = strength_sessions.verify(&auth)?;
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
        .run(move |c| strength_session_id.verify(&auth, c))
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
    let strength_session = conn.run(move |c| strength_session.verify(&auth, c)).await?;
    conn.run(|c| StrengthSession::update(strength_session, c))
        .await
        .into_json()
}

#[delete("/strength_session/<strength_session_id>")]
pub async fn delete_strength_session(
    strength_session_id: UnverifiedId<StrengthSessionId>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Status, Status> {
    conn.run(move |c| {
        StrengthSession::delete(strength_session_id.verify(&auth, c)?, c)
            .map(|_| Status::NoContent)
            .map_err(|_| Status::InternalServerError)
    })
    .await
}

#[delete(
    "/strength_sessions",
    format = "application/json",
    data = "<strength_session_ids>"
)]
pub async fn delete_strength_sessions(
    strength_session_ids: UnverifiedIds<StrengthSessionId>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Status, Status> {
    conn.run(move |c| {
        StrengthSession::delete_multiple(strength_session_ids.verify(&auth, c)?, c)
            .map(|_| Status::NoContent)
            .map_err(|_| Status::InternalServerError)
    })
    .await
}

#[post("/strength_set", format = "application/json", data = "<strength_set>")]
pub async fn create_strength_set(
    strength_set: Unverified<NewStrengthSet>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<StrengthSet>, Status> {
    let strength_set = conn.run(move |c| strength_set.verify(&auth, c)).await?;
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
    strength_sets: Unverified<Vec<NewStrengthSet>>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<Vec<StrengthSet>>, Status> {
    let strength_set = conn.run(move |c| strength_sets.verify(&auth, c)).await?;
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
    let strength_set_id = conn.run(move |c| strength_set_id.verify(&auth, c)).await?;
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
        .run(move |c| strength_session_id.verify(&auth, c))
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
    let strength_set = conn.run(move |c| strength_set.verify(&auth, c)).await?;
    conn.run(|c| StrengthSet::update(strength_set, c))
        .await
        .into_json()
}

#[delete(
    "/strength_sets",
    format = "application/json",
    data = "<strength_set_ids>"
)]
pub async fn delete_strength_sets(
    strength_set_ids: UnverifiedIds<StrengthSetId>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Status, Status> {
    conn.run(move |c| {
        StrengthSet::delete_multiple(strength_set_ids.verify(&auth, c)?, c)
            .map(|_| Status::NoContent)
            .map_err(|_| Status::InternalServerError)
    })
    .await
}

#[delete("/strength_set/<strength_set_id>")]
pub async fn delete_strength_set(
    strength_set_id: UnverifiedId<StrengthSetId>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Status, Status> {
    conn.run(move |c| {
        StrengthSet::delete(strength_set_id.verify(&auth, c)?, c)
            .map(|_| Status::NoContent)
            .map_err(|_| Status::InternalServerError)
    })
    .await
}

#[get("/strength_session_description/<strength_session_id>")]
pub async fn get_strength_session_description(
    strength_session_id: UnverifiedId<StrengthSessionId>,
    auth: AuthUserOrAP,
    conn: Db,
) -> Result<Json<StrengthSessionDescription>, Status> {
    let strength_session_id = conn
        .run(move |c| strength_session_id.verify(&auth, c))
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
    start_datetime: NaiveDateTimeWrapper,
    end_datetime: NaiveDateTimeWrapper,
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
