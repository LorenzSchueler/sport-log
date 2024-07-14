use axum::{extract::Query, Json};
use serde::Deserialize;
use sport_log_types::AccountData;

use crate::{auth::AuthUser, db::AccountDataDb, error::HandlerResult, state::DbConn};

#[derive(Debug, Deserialize)]
pub struct LastSync {
    #[serde(default)]
    last_sync: Option<i64>,
}

pub async fn get_account_data(
    auth: AuthUser,
    Query(LastSync { last_sync }): Query<LastSync>,
    mut db: DbConn,
) -> HandlerResult<Json<AccountData>> {
    match last_sync {
        Some(last_sync) => AccountDataDb::get_by_user_and_epoch(*auth, last_sync, &mut db).await,
        None => AccountDataDb::get_by_user(*auth, &mut db).await,
    }
    .map(Json)
    .map_err(Into::into)
}
