use rocket::{http::Status, serde::json::Json};

use sport_log_types::types::{AccountData, AuthenticatedUser, Db};

use crate::handler::IntoJson;

#[get("/account")]
pub async fn get_account_data_by_user(
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<AccountData>, Status> {
    conn.run(move |c| AccountData::get_by_user(*auth, c))
        .await
        .into_json()
}
