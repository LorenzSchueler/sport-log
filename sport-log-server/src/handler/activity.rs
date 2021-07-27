use rocket::{http::Status, serde::json::Json};

use sport_log_types::{Activity, AuthenticatedUser, Db, GetByUser};

use crate::handler::{IntoJson, NaiveDateTimeWrapper};

#[get("/activity")]
pub async fn get_activities(
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Vec<Activity>>, Status> {
    conn.run(move |c| Activity::get_by_user(*auth, c))
        .await
        .into_json()
}

#[get("/activity/timespan/<start_datetime>/<end_datetime>")]
pub async fn get_ordered_activities_by_timespan(
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
