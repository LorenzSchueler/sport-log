use axum::{extract::Query, http::StatusCode};
use chrono::{DateTime, Utc};
use serde::Deserialize;

use crate::{auth::AuthAdmin, db::*, error::HandlerResult, state::DbConn};

#[derive(Debug, Deserialize)]
pub struct LastChange {
    last_change: DateTime<Utc>,
}

pub async fn adm_do_garbage_collection(
    _auth: AuthAdmin,
    Query(LastChange { last_change }): Query<LastChange>,
    mut db: DbConn,
) -> HandlerResult<StatusCode> {
    PlatformDb::hard_delete(last_change, &mut db)?;
    PlatformCredentialDb::hard_delete(last_change, &mut db)?;
    ActionDb::hard_delete(last_change, &mut db)?;
    ActionProviderDb::hard_delete(last_change, &mut db)?;
    ActionRuleDb::hard_delete(last_change, &mut db)?;
    ActionEventDb::hard_delete(last_change, &mut db)?;
    DiaryDb::hard_delete(last_change, &mut db)?;
    WodDb::hard_delete(last_change, &mut db)?;
    MovementDb::hard_delete(last_change, &mut db)?;
    MovementMuscleDb::hard_delete(last_change, &mut db)?;
    StrengthSessionDb::hard_delete(last_change, &mut db)?;
    StrengthSetDb::hard_delete(last_change, &mut db)?;
    MetconDb::hard_delete(last_change, &mut db)?;
    MetconMovementDb::hard_delete(last_change, &mut db)?;
    MetconSessionDb::hard_delete(last_change, &mut db)?;
    RouteDb::hard_delete(last_change, &mut db)?;
    CardioSessionDb::hard_delete(last_change, &mut db)?;
    GroupDb::hard_delete(last_change, &mut db)?;
    GroupUserDb::hard_delete(last_change, &mut db)?;
    SharedDiaryDb::hard_delete(last_change, &mut db)?;
    SharedStrengthSessionDb::hard_delete(last_change, &mut db)?;
    SharedMetconSessionDb::hard_delete(last_change, &mut db)?;
    SharedCardioSessionDb::hard_delete(last_change, &mut db)?;

    Ok(StatusCode::OK)
}
