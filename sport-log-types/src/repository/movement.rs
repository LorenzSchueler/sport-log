use chrono::{DateTime, Utc};
use diesel::prelude::*;

use crate::{
    schema::{movement, movement_muscle},
    CheckOptionalUserId, CheckUserId, GetByUser, GetByUserSync, Movement, MovementId,
    MovementMuscle, MovementMuscleId, UserId,
};

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

impl CheckOptionalUserId for Movement {
    type Id = MovementId;

    fn check_optional_user_id(
        id: Self::Id,
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

    fn check_optional_user_ids(
        ids: &[Self::Id],
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

impl GetByUser for MovementMuscle {
    fn get_by_user(user_id: UserId, conn: &PgConnection) -> QueryResult<Vec<Self>> {
        movement_muscle::table
            .filter(
                movement_muscle::columns::movement_id.eq_any(
                    movement::table
                        .filter(
                            movement::columns::user_id
                                .eq(user_id)
                                .or(movement::columns::user_id.is_null()),
                        )
                        .select(movement::columns::id),
                ),
            )
            .get_results(conn)
    }
}

impl GetByUserSync for MovementMuscle {
    fn get_by_user_and_last_sync(
        user_id: UserId,
        last_sync: DateTime<Utc>,
        conn: &PgConnection,
    ) -> QueryResult<Vec<Self>>
    where
        Self: Sized,
    {
        movement_muscle::table
            .filter(
                movement_muscle::columns::movement_id.eq_any(
                    movement::table
                        .filter(
                            movement::columns::user_id
                                .eq(user_id)
                                .or(movement::columns::user_id.is_null()),
                        )
                        .select(movement::columns::id),
                ),
            )
            .filter(movement_muscle::columns::last_change.ge(last_sync))
            .get_results(conn)
    }
}

impl CheckUserId for MovementMuscle {
    type Id = MovementMuscleId;

    fn check_user_id(id: Self::Id, user_id: UserId, conn: &PgConnection) -> QueryResult<bool> {
        movement_muscle::table
            .inner_join(movement::table)
            .filter(movement_muscle::columns::id.eq(id))
            .filter(movement::columns::user_id.eq(user_id))
            .count()
            .get_result(conn)
            .map(|count: i64| count == 1)
    }

    fn check_user_ids(ids: &[Self::Id], user_id: UserId, conn: &PgConnection) -> QueryResult<bool> {
        movement_muscle::table
            .inner_join(movement::table)
            .filter(movement_muscle::columns::id.eq_any(ids))
            .filter(movement::columns::user_id.eq(user_id))
            .count()
            .get_result(conn)
            .map(|count: i64| count == ids.len() as i64)
    }
}

impl CheckOptionalUserId for MovementMuscle {
    type Id = MovementMuscleId;

    fn check_optional_user_id(
        id: Self::Id,
        user_id: UserId,
        conn: &PgConnection,
    ) -> QueryResult<bool> {
        movement_muscle::table
            .inner_join(movement::table)
            .filter(movement_muscle::columns::id.eq(id))
            .filter(
                movement::columns::user_id
                    .eq(user_id)
                    .or(movement::columns::user_id.is_null()),
            )
            .count()
            .get_result(conn)
            .map(|count: i64| count == 1)
    }

    fn check_optional_user_ids(
        ids: &[Self::Id],
        user_id: UserId,
        conn: &PgConnection,
    ) -> QueryResult<bool> {
        movement_muscle::table
            .inner_join(movement::table)
            .filter(movement_muscle::columns::id.eq_any(ids))
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
