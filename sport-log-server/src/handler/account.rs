use axum::{extract::Query, Json};
use serde::Deserialize;
use sport_log_types::AccountData;

use crate::{auth::AuthUser, db::AccountDataDb, error::HandlerResult, state::DbConn};

#[derive(Debug, Deserialize)]
pub struct Epoch {
    #[serde(default)]
    epoch: Option<i64>,
}

pub async fn get_account_data(
    auth: AuthUser,
    Query(Epoch { epoch }): Query<Epoch>,
    mut db: DbConn,
) -> HandlerResult<Json<AccountData>> {
    match epoch {
        Some(epoch) => AccountDataDb::get_by_user_and_epoch(*auth, epoch, &mut db).await,
        None => AccountDataDb::get_by_user(*auth, &mut db).await,
    }
    .map(Json)
    .map_err(Into::into)
}
