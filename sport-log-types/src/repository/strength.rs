use diesel::{prelude::*, PgConnection, QueryResult};

use crate::{
    schema::{strength_session, strength_set},
    types::{GetByUser, StrengthSessionId, StrengthSet, UserId},
};

impl GetByUser for StrengthSet {
    fn get_by_user(user_id: UserId, conn: &PgConnection) -> QueryResult<Vec<Self>> {
        strength_set::table
            .filter(
                strength_set::columns::strength_session_id.eq_any(
                    strength_session::table
                        .filter(strength_session::columns::user_id.eq(user_id))
                        .select(strength_session::columns::id)
                        .get_results::<StrengthSessionId>(conn)?,
                ),
            )
            .get_results(conn)
    }
}

impl StrengthSet {
    pub fn get_by_strength_session(
        strength_session_id: StrengthSessionId,
        conn: &PgConnection,
    ) -> QueryResult<Vec<Self>> {
        strength_set::table
            .filter(strength_set::columns::strength_session_id.eq(strength_session_id))
            .get_results(conn)
    }
}
