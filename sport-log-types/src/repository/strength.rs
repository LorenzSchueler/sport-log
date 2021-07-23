use diesel::{prelude::*, PgConnection, QueryResult};

use crate::{
    schema::strength_set,
    types::{StrengthSessionId, StrengthSet},
};

impl StrengthSet {
    pub fn get_by_strength_session(
        strength_session_id: StrengthSessionId,
        conn: &PgConnection,
    ) -> QueryResult<Vec<StrengthSet>> {
        strength_set::table
            .filter(strength_set::columns::strength_session_id.eq(strength_session_id))
            .get_results(conn)
    }
}
