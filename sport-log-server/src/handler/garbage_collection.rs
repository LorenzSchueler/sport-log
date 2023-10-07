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
    PlatformDb::hard_delete(last_change, &mut db).await?;
    PlatformCredentialDb::hard_delete(last_change, &mut db).await?;
    ActionDb::hard_delete(last_change, &mut db).await?;
    ActionProviderDb::hard_delete(last_change, &mut db).await?;
    ActionRuleDb::hard_delete(last_change, &mut db).await?;
    ActionEventDb::hard_delete(last_change, &mut db).await?;
    DiaryDb::hard_delete(last_change, &mut db).await?;
    WodDb::hard_delete(last_change, &mut db).await?;
    MovementDb::hard_delete(last_change, &mut db).await?;
    MovementMuscleDb::hard_delete(last_change, &mut db).await?;
    StrengthSessionDb::hard_delete(last_change, &mut db).await?;
    StrengthSetDb::hard_delete(last_change, &mut db).await?;
    MetconDb::hard_delete(last_change, &mut db).await?;
    MetconMovementDb::hard_delete(last_change, &mut db).await?;
    MetconSessionDb::hard_delete(last_change, &mut db).await?;
    RouteDb::hard_delete(last_change, &mut db).await?;
    CardioSessionDb::hard_delete(last_change, &mut db).await?;
    GroupDb::hard_delete(last_change, &mut db).await?;
    GroupUserDb::hard_delete(last_change, &mut db).await?;
    SharedDiaryDb::hard_delete(last_change, &mut db).await?;
    SharedStrengthSessionDb::hard_delete(last_change, &mut db).await?;
    SharedMetconSessionDb::hard_delete(last_change, &mut db).await?;
    SharedCardioSessionDb::hard_delete(last_change, &mut db).await?;

    Ok(StatusCode::OK)
}
