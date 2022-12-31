use chrono::{DateTime, Utc};
use diesel::{prelude::*, PgConnection, QueryResult};

use crate::{
    schema::{diary, wod},
    Diary, UserId, Wod,
};

impl Diary {
    pub fn get_ordered_by_user_and_timespan(
        user_id: UserId,
        start: DateTime<Utc>,
        end: DateTime<Utc>,
        db: &mut PgConnection,
    ) -> QueryResult<Vec<Self>> {
        diary::table
            .filter(diary::columns::user_id.eq(user_id))
            .filter(diary::columns::date.between(start.date_naive(), end.date_naive()))
            .order_by(diary::columns::date)
            .get_results(db)
    }
}

impl Wod {
    pub fn get_ordered_by_user_and_timespan(
        user_id: UserId,
        start: DateTime<Utc>,
        end: DateTime<Utc>,
        db: &mut PgConnection,
    ) -> QueryResult<Vec<Self>> {
        wod::table
            .filter(wod::columns::user_id.eq(user_id))
            .filter(wod::columns::date.between(start.date_naive(), end.date_naive()))
            .order_by(wod::columns::date)
            .get_results(db)
    }
}
