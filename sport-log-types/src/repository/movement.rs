use diesel::prelude::*;

use crate::{schema::movement, GetByUser, GetByUserSync, Movement, MovementId, UserId};

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

impl Movement {
    pub fn check_user_id_null(
        id: MovementId,
        user_id: UserId,
        conn: &PgConnection,
    ) -> QueryResult<bool> {
        movement::table
            .filter(movement::columns::id.eq(id))
            .filter(
                movement::columns::user_id
                    .eq(user_id)
                    .or(movement::columns::user_id.is_null()),
            )
            .count()
            .get_result(conn)
            .map(|count: i64| count == 1)
    }

    pub fn check_user_ids_null(
        ids: &Vec<MovementId>,
        user_id: UserId,
        conn: &PgConnection,
    ) -> QueryResult<bool> {
        movement::table
            .filter(movement::columns::id.eq_any(ids))
            .filter(
                movement::columns::user_id
                    .eq(user_id)
                    .or(movement::columns::user_id.is_null()),
            )
            .count()
            .get_result(conn)
            .map(|count: i64| count == ids.len() as i64)
    }
}
