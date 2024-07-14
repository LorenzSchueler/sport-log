use axum::{extract::Query, http::StatusCode};
use serde::Deserialize;

use crate::{auth::AuthAdmin, db::*, error::HandlerResult, state::DbConn};

#[derive(Debug, Deserialize)]
pub struct Epoch {
    epoch: i64,
}

pub async fn adm_do_garbage_collection(
    _auth: AuthAdmin,
    Query(Epoch { epoch }): Query<Epoch>,
    mut db: DbConn,
) -> HandlerResult<StatusCode> {
    PlatformDb::hard_delete(epoch, &mut db).await?;
    PlatformCredentialDb::hard_delete(epoch, &mut db).await?;
    ActionDb::hard_delete(epoch, &mut db).await?;
    ActionProviderDb::hard_delete(epoch, &mut db).await?;
    ActionRuleDb::hard_delete(epoch, &mut db).await?;
    ActionEventDb::hard_delete(epoch, &mut db).await?;
    DiaryDb::hard_delete(epoch, &mut db).await?;
    WodDb::hard_delete(epoch, &mut db).await?;
    MovementDb::hard_delete(epoch, &mut db).await?;
    StrengthSessionDb::hard_delete(epoch, &mut db).await?;
    StrengthSetDb::hard_delete(epoch, &mut db).await?;
    MetconDb::hard_delete(epoch, &mut db).await?;
    MetconSessionDb::hard_delete(epoch, &mut db).await?;
    RouteDb::hard_delete(epoch, &mut db).await?;
    CardioSessionDb::hard_delete(epoch, &mut db).await?;

    Ok(StatusCode::OK)
}
