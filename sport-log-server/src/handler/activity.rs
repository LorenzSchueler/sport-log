use sport_log_types::{Activity, AuthUserOrAP, Db, GetByUser};

use crate::handler::{DateTimeWrapper, IntoJson, JsonResult};

#[get("/activity")]
pub async fn get_activities(auth: AuthUserOrAP, conn: Db) -> JsonResult<Vec<Activity>> {
    conn.run(move |c| Activity::get_by_user(*auth, c))
        .await
        .into_json()
}

#[get("/activity/timespan/<start_datetime>/<end_datetime>")]
pub async fn get_ordered_activities_by_timespan(
    start_datetime: DateTimeWrapper,
    end_datetime: DateTimeWrapper,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Vec<Activity>> {
    conn.run(move |c| {
        Activity::get_ordered_by_user_and_timespan(*auth, *start_datetime, *end_datetime, c)
    })
    .await
    .into_json()
}
