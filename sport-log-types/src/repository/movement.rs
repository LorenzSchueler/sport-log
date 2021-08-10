use diesel::prelude::*;

use crate::{schema::movement, GetByUser, GetByUserSync, Movement, UserId};

impl GetByUser for Movement {
    fn get_by_user(user_id: UserId, conn: &PgConnection) -> QueryResult<Vec<Self>> {
        movement::table
            .filter(
                movement::columns::user_id
                    .eq(user_id)
                    .or(movement::columns::user_id.is_null()),
            )
            .get_results(conn)
    }
}

impl GetByUserSync for Movement {
    fn get_by_user_and_last_sync(
        user_id: UserId,
        last_sync: chrono::DateTime<chrono::Utc>,
        conn: &PgConnection,
    ) -> QueryResult<Vec<Self>>
    where
        Self: Sized,
    {
        movement::table
            .filter(
                movement::columns::user_id
                    .eq(user_id)
                    .or(movement::columns::user_id.is_null()),
            )
            .filter(movement::columns::last_change.ge(last_sync))
            .get_results(conn)
    }
}
