use chrono::NaiveDateTime;
use diesel::{prelude::*, PgConnection, QueryResult};

use crate::{
    schema::{diary, wod},
    types::{Diary, UserId, Wod},
};

impl Diary {
    pub fn get_ordered_by_user_and_timespan(
        user_id: UserId,
        start: NaiveDateTime,
        end: NaiveDateTime,
        conn: &PgConnection,
    ) -> QueryResult<Vec<Self>> {
        diary::table
            .filter(diary::columns::user_id.eq(user_id))
            .filter(diary::columns::date.between(start.date(), end.date()))
            .order_by(diary::columns::date)
            .get_results(conn)
    }
}

impl Wod {
    pub fn get_ordered_by_user_and_timespan(
        user_id: UserId,
        start: NaiveDateTime,
        end: NaiveDateTime,
        conn: &PgConnection,
    ) -> QueryResult<Vec<Self>> {
        wod::table
            .filter(wod::columns::user_id.eq(user_id))
            .filter(wod::columns::date.between(start.date(), end.date()))
            .order_by(wod::columns::date)
            .get_results(conn)
    }
}
