use rocket::{http::Status, serde::json::Json};

use sport_log_types::{AccountData, AuthUser, Db};

use crate::handler::{DateTimeWrapper, IntoJson};

#[get("/account_data")]
pub async fn get_account_data(auth: AuthUser, conn: Db) -> Result<Json<AccountData>, Status> {
    conn.run(move |c| AccountData::get_by_user(*auth, c))
        .await
        .into_json()
}

#[get("/account_data/<last_sync>")]
pub async fn sync(
    last_sync: DateTimeWrapper,
    auth: AuthUser,
    conn: Db,
) -> Result<Json<AccountData>, Status> {
    conn.run(move |c| AccountData::get_by_user_and_last_sync(*auth, *last_sync, c))
        .await
        .into_json()
}
