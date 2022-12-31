use axum::{extract::Query, Json};
use chrono::{DateTime, Utc};
use serde::Deserialize;
use sport_log_types::{AccountData, AuthUser, DbConn};

use crate::handler::HandlerResult;

#[derive(Debug, Deserialize)]
pub struct LastSync {
    #[serde(default)]
    pub last_sync: Option<DateTime<Utc>>,
}

pub async fn get_account_data(
    auth: AuthUser,
    Query(LastSync { last_sync }): Query<LastSync>,
    mut db: DbConn,
) -> HandlerResult<Json<AccountData>> {
    match last_sync {
        Some(last_sync) => AccountData::get_by_user_and_last_sync(*auth, last_sync, &mut db),
        None => AccountData::get_by_user(*auth, &mut db),
    }
    .map(Json)
    .map_err(Into::into)
}
