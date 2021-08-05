use rocket::{http::Status, serde::json::Json};

use sport_log_types::{AccountData, AuthUser, Db};

use crate::handler::IntoJson;

#[get("/account_data")]
pub async fn get_account_data(auth: AuthUser, conn: Db) -> Result<Json<AccountData>, Status> {
    conn.run(move |c| AccountData::get_by_user(*auth, c))
        .await
        .into_json()
}
