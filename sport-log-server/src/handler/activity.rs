use axum::Json;
use sport_log_types::{Activity, AuthUserOrAP, DbConn, GetByUser};

use crate::handler::HandlerResult;

pub async fn get_activities(
    auth: AuthUserOrAP,
    mut db: DbConn,
) -> HandlerResult<Json<Vec<Activity>>> {
    Activity::get_by_user(*auth, &mut db)
        .map(Json)
        .map_err(Into::into)
}

//#[get("/activity/timespan/<start_datetime>/<end_datetime>")]
//pub async fn get_ordered_activities_by_timespan(
//auth: AuthUserOrAP,
//Path(start_datetime): Path<DateTime<Utc>>,
//Path(end_datetime): Path<DateTime<Utc>>,
//mut db: DbConn,
//) -> HandlerResult<Json<Vec<Activity>>> {
//Activity::get_ordered_by_user_and_timespan(*auth, start_datetime, end_datetime, &mut db)
//.map(Json)
//.map_err(Into::into)
//}
