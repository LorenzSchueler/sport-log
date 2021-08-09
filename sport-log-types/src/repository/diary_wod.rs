use chrono::NaiveDate;
use diesel::{prelude::*, PgConnection, QueryResult};

use crate::{
    schema::{diary, wod},
    Diary, UserId, Wod,
};

impl Diary {
    pub fn get_ordered_by_user_and_timespan(
        user_id: UserId,
        start: NaiveDate,
        end: NaiveDate,
        conn: &PgConnection,
    ) -> QueryResult<Vec<Self>> {
        diary::table
            .filter(diary::columns::user_id.eq(user_id))
            .filter(diary::columns::date.between(start, end))
            .order_by(diary::columns::date)
            .get_results(conn)
    }
}

impl Wod {
    pub fn get_ordered_by_user_and_timespan(
        user_id: UserId,
        start_date: NaiveDate,
        end_end: NaiveDate,
        conn: &PgConnection,
    ) -> QueryResult<Vec<Self>> {
        wod::table
            .filter(wod::columns::user_id.eq(user_id))
            .filter(wod::columns::date.between(start_date, end_end))
            .order_by(wod::columns::date)
            .get_results(conn)
    }
}
