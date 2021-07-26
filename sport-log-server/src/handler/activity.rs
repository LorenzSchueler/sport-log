use rocket::{http::Status, serde::json::Json};

use sport_log_types::types::{Activity, AuthenticatedUser, Db};

use crate::handler::{IntoJson, NaiveDateTimeWrapper};

#[get("/activity/timespan/<start_datetime>/<end_datetime>")]
pub async fn get_activities_ordered_by_user_and_timespan(
    start_datetime: NaiveDateTimeWrapper,
    end_datetime: NaiveDateTimeWrapper,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Vec<Activity>>, Status> {
    conn.run(move |c| {
        Activity::get_ordered_by_user_and_timespan(*auth, *start_datetime, *end_datetime, c)
    })
    .await
    .into_json()
}
