use rocket::{http::Status, serde::json::Json};

use sport_log_types::types::{
    AuthenticatedUser, Db, NewStrengthSession, StrengthSession, StrengthSessionId, Unverified,
    UnverifiedId,
};

use crate::handler::IntoJson;

#[post(
    "/strength_session",
    format = "application/json",
    data = "<strength_session>"
)]
pub async fn create_strength_session(
    strength_session: Unverified<NewStrengthSession>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<StrengthSession>, Status> {
    let strength_session = strength_session.verify(&auth)?;
    conn.run(|c| StrengthSession::create(strength_session, c))
        .await
        .into_json()
}

#[get("/strength_session/<strength_session_id>")]
pub async fn get_strength_session(
    strength_session_id: UnverifiedId<StrengthSessionId>,
    auth: AuthenticatedUser,
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
pub async fn get_strength_sessions_by_user(
    auth: AuthenticatedUser,
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
    auth: AuthenticatedUser,
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
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Status, Status> {
    conn.run(move |c| {
        StrengthSession::delete(strength_session_id.verify(&auth, c)?, c)
            .map(|_| Status::NoContent)
            .map_err(|_| Status::InternalServerError)
    })
    .await
}
