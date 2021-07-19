use diesel::prelude::*;

use crate::{
    schema::{diary, wod},
    types::{UserId, Wod},
};

impl Wod {
    pub fn get_by_user(user_id: UserId, conn: &PgConnection) -> QueryResult<Vec<Wod>> {
        wod::table
            .filter(wod::columns::user_id.eq(user_id))
            .get_results(conn)
    }
}
