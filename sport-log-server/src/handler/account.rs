use axum::Json;
use sport_log_types::{AccountData, EpochMap};

use crate::{auth::AuthUser, db::AccountDataDb, error::HandlerResult, state::DbConn};

pub async fn get_account_data(
    auth: AuthUser,
    mut db: DbConn,
    Json(epoch_map): Json<Option<EpochMap>>,
) -> HandlerResult<Json<AccountData>> {
    match epoch_map {
        Some(epoch) => AccountDataDb::get_by_user_and_epoch(*auth, epoch, &mut db).await,
        None => AccountDataDb::get_by_user(*auth, &mut db).await,
    }
    .map(Json)
    .map_err(Into::into)
}
