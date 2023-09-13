use axum::{extract::Query, Json};
use chrono::{DateTime, Utc};
use serde::Deserialize;
use sport_log_types::AccountData;

use crate::{auth::AuthUser, db::AccountDataDb, error::HandlerResult, state::DbConn};

// DateTime cannot contain the timezone in `+00:00` format because `+` is not allowed as a HTTP query string character.
// Therefor the datetime must be converted like so:
// `2023-03-29T11:30:39.376536597+00:00` -> `2023-03-29T11:30:39.376536597Z`
#[derive(Debug, Deserialize)]
pub struct LastSync {
    #[serde(default)]
    last_sync: Option<DateTime<Utc>>,
}

pub async fn get_account_data(
    auth: AuthUser,
    Query(LastSync { last_sync }): Query<LastSync>,
    mut db: DbConn,
) -> HandlerResult<Json<AccountData>> {
    match last_sync {
        Some(last_sync) => {
            AccountDataDb::get_by_user_and_last_sync(*auth, last_sync, &mut db).await
        }
        None => AccountDataDb::get_by_user(*auth, &mut db).await,
    }
    .map(Json)
    .map_err(Into::into)
}
