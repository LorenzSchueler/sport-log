use chrono::{DateTime, Utc};
use diesel::{prelude::*, PgConnection, QueryResult};

use crate::{
    schema::{metcon, metcon_item, metcon_movement, metcon_session, movement, training_plan},
    CheckOptionalUserId, CheckUserId, GetById, GetByUser, GetByUserSync, Metcon, MetconId,
    MetconItem, MetconItemId, MetconMovement, MetconMovementId, MetconSession,
    MetconSessionDescription, MetconSessionId, Movement, UserId,
};

impl GetByUser for Metcon {
    fn get_by_user(user_id: UserId, db: &mut PgConnection) -> QueryResult<Vec<Self>> {
        metcon::table
            .filter(
                metcon::columns::user_id
                    .eq(user_id)
                    .or(metcon::columns::user_id.is_null()),
            )
            .get_results(db)
    }
}

impl GetByUserSync for Metcon {
    fn get_by_user_and_last_sync(
        user_id: UserId,
        last_sync: DateTime<Utc>,
        db: &mut PgConnection,
    ) -> QueryResult<Vec<Self>>
    where
        Self: Sized,
    {
        metcon::table
            .filter(
                metcon::columns::user_id
                    .eq(user_id)
                    .or(metcon::columns::user_id.is_null()),
            )
            .filter(metcon::columns::last_change.ge(last_sync))
            .get_results(db)
    }
}

impl CheckOptionalUserId for Metcon {
    type Id = MetconId;

    fn check_optional_user_id(
        id: Self::Id,
        user_id: UserId,
        db: &mut PgConnection,
    ) -> QueryResult<bool> {
        metcon::table
            .filter(metcon::columns::id.eq(id))
            .filter(
                metcon::columns::user_id
                    .eq(user_id)
                    .or(metcon::columns::user_id.is_null()),
            )
            .count()
            .get_result(db)
            .map(|count: i64| count == 1)
    }

    fn check_optional_user_ids(
        ids: &[Self::Id],
        user_id: UserId,
        db: &mut PgConnection,
    ) -> QueryResult<bool> {
        metcon::table
            .filter(metcon::columns::id.eq_any(ids))
            .filter(
                metcon::columns::user_id
                    .eq(user_id)
                    .or(metcon::columns::user_id.is_null()),
            )
            .count()
            .get_result(db)
            .map(|count: i64| count == ids.len() as i64)
    }
}

impl MetconSession {
    pub fn get_ordered_by_user_and_timespan(
        user_id: UserId,
        start_datetime: DateTime<Utc>,
        end_datetime: DateTime<Utc>,
        db: &mut PgConnection,
    ) -> QueryResult<Vec<Self>> {
        metcon_session::table
            .filter(metcon_session::columns::user_id.eq(user_id))
            .filter(metcon_session::columns::datetime.between(start_datetime, end_datetime))
            .order_by(metcon_session::columns::datetime)
            .get_results(db)
    }
}

impl GetByUser for MetconMovement {
    fn get_by_user(user_id: UserId, db: &mut PgConnection) -> QueryResult<Vec<Self>> {
        metcon_movement::table
            .filter(
                metcon_movement::columns::metcon_id.eq_any(
                    metcon::table
                        .filter(
                            metcon::columns::user_id
                                .eq(user_id)
                                .or(metcon::columns::user_id.is_null()),
                        )
                        .select(metcon::columns::id),
                ),
            )
            .get_results(db)
    }
}

impl GetByUserSync for MetconMovement {
    fn get_by_user_and_last_sync(
        user_id: UserId,
        last_sync: DateTime<Utc>,
        db: &mut PgConnection,
    ) -> QueryResult<Vec<Self>>
    where
        Self: Sized,
    {
        metcon_movement::table
            .filter(
                metcon_movement::columns::metcon_id.eq_any(
                    metcon::table
                        .filter(
                            metcon::columns::user_id
                                .eq(user_id)
                                .or(metcon::columns::user_id.is_null()),
                        )
                        .select(metcon::columns::id),
                ),
            )
            .filter(metcon_movement::columns::last_change.ge(last_sync))
            .get_results(db)
    }
}

impl CheckUserId for MetconMovement {
    type Id = MetconMovementId;

    fn check_user_id(id: Self::Id, user_id: UserId, db: &mut PgConnection) -> QueryResult<bool> {
        metcon_movement::table
            .inner_join(metcon::table)
            .inner_join(movement::table)
            .filter(metcon_movement::columns::id.eq(id))
            .filter(metcon::columns::user_id.eq(user_id))
            .filter(
                movement::columns::user_id
                    .eq(user_id)
                    .or(movement::columns::user_id.is_null()),
            )
            .count()
            .get_result(db)
            .map(|count: i64| count == 1)
    }

    fn check_user_ids(
        ids: &[Self::Id],
        user_id: UserId,
        db: &mut PgConnection,
    ) -> QueryResult<bool> {
        metcon_movement::table
            .inner_join(metcon::table)
            .inner_join(movement::table)
            .filter(metcon_movement::columns::id.eq_any(ids))
            .filter(metcon::columns::user_id.eq(user_id))
            .filter(
                movement::columns::user_id
                    .eq(user_id)
                    .or(movement::columns::user_id.is_null()),
            )
            .count()
            .get_result(db)
            .map(|count: i64| count == ids.len() as i64)
    }
}

impl CheckOptionalUserId for MetconMovement {
    type Id = MetconMovementId;

    fn check_optional_user_id(
        id: Self::Id,
        user_id: UserId,
        db: &mut PgConnection,
    ) -> QueryResult<bool> {
        metcon_movement::table
            .inner_join(metcon::table)
            .inner_join(movement::table)
            .filter(metcon_movement::columns::id.eq(id))
            .filter(
                metcon::columns::user_id
                    .eq(user_id)
                    .or(metcon::columns::user_id.is_null()),
            )
            .filter(
                movement::columns::user_id
                    .eq(user_id)
                    .or(movement::columns::user_id.is_null()),
            )
            .count()
            .get_result(db)
            .map(|count: i64| count == 1)
    }

    fn check_optional_user_ids(
        ids: &[Self::Id],
        user_id: UserId,
        db: &mut PgConnection,
    ) -> QueryResult<bool> {
        metcon_movement::table
            .inner_join(metcon::table)
            .inner_join(movement::table)
            .filter(metcon_movement::columns::id.eq_any(ids))
            .filter(
                metcon::columns::user_id
                    .eq(user_id)
                    .or(metcon::columns::user_id.is_null()),
            )
            .filter(
                movement::columns::user_id
                    .eq(user_id)
                    .or(movement::columns::user_id.is_null()),
            )
            .count()
            .get_result(db)
            .map(|count: i64| count == ids.len() as i64)
    }
}

impl MetconMovement {
    pub fn get_by_metcon(metcon_id: MetconId, db: &mut PgConnection) -> QueryResult<Vec<Self>> {
        metcon_movement::table
            .filter(metcon_movement::columns::metcon_id.eq(metcon_id))
            .get_results(db)
    }
}

impl GetByUser for MetconItem {
    fn get_by_user(user_id: UserId, db: &mut PgConnection) -> QueryResult<Vec<Self>> {
        metcon_item::table
            .filter(
                metcon_item::columns::training_plan_id.eq_any(
                    training_plan::table
                        .filter(training_plan::columns::user_id.eq(user_id))
                        .select(training_plan::columns::id),
                ),
            )
            .get_results(db)
    }
}

impl GetByUserSync for MetconItem {
    fn get_by_user_and_last_sync(
        user_id: UserId,
        last_sync: DateTime<Utc>,
        db: &mut PgConnection,
    ) -> QueryResult<Vec<Self>>
    where
        Self: Sized,
    {
        metcon_item::table
            .filter(
                metcon_item::columns::training_plan_id.eq_any(
                    training_plan::table
                        .filter(training_plan::columns::user_id.eq(user_id))
                        .select(training_plan::columns::id),
                ),
            )
            .filter(metcon_item::columns::last_change.ge(last_sync))
            .get_results(db)
    }
}

impl CheckUserId for MetconItem {
    type Id = MetconItemId;

    fn check_user_id(id: Self::Id, user_id: UserId, db: &mut PgConnection) -> QueryResult<bool> {
        metcon_item::table
            .inner_join(metcon::table)
            .inner_join(training_plan::table)
            .filter(metcon_item::columns::id.eq(id))
            .filter(metcon::columns::user_id.eq(user_id))
            .filter(training_plan::columns::user_id.eq(user_id))
            .count()
            .get_result(db)
            .map(|count: i64| count == 1)
    }

    fn check_user_ids(
        ids: &[Self::Id],
        user_id: UserId,
        db: &mut PgConnection,
    ) -> QueryResult<bool> {
        metcon_item::table
            .inner_join(metcon::table)
            .inner_join(training_plan::table)
            .filter(metcon_item::columns::id.eq_any(ids))
            .filter(metcon::columns::user_id.eq(user_id))
            .filter(training_plan::columns::user_id.eq(user_id))
            .count()
            .get_result(db)
            .map(|count: i64| count == ids.len() as i64)
    }
}

impl CheckOptionalUserId for MetconItem {
    type Id = MetconItemId;

    fn check_optional_user_id(
        id: Self::Id,
        user_id: UserId,
        db: &mut PgConnection,
    ) -> QueryResult<bool> {
        metcon_item::table
            .inner_join(metcon::table)
            .inner_join(training_plan::table)
            .filter(metcon_item::columns::id.eq(id))
            .filter(
                metcon::columns::user_id
                    .eq(user_id)
                    .or(metcon::columns::user_id.is_null()),
            )
            .filter(training_plan::columns::user_id.eq(user_id))
            .count()
            .get_result(db)
            .map(|count: i64| count == 1)
    }

    fn check_optional_user_ids(
        ids: &[Self::Id],
        user_id: UserId,
        db: &mut PgConnection,
    ) -> QueryResult<bool> {
        metcon_item::table
            .inner_join(metcon::table)
            .inner_join(training_plan::table)
            .filter(metcon_item::columns::id.eq_any(ids))
            .filter(
                metcon::columns::user_id
                    .eq(user_id)
                    .or(metcon::columns::user_id.is_null()),
            )
            .filter(training_plan::columns::user_id.eq(user_id))
            .count()
            .get_result(db)
            .map(|count: i64| count == ids.len() as i64)
    }
}

impl GetById for MetconSessionDescription {
    type Id = MetconSessionId;

    fn get_by_id(metcon_session_id: Self::Id, db: &mut PgConnection) -> QueryResult<Self> {
        let metcon_session = MetconSession::get_by_id(metcon_session_id, db)?;
        MetconSessionDescription::from_session(metcon_session, db)
    }
}

impl GetByUser for MetconSessionDescription {
    fn get_by_user(user_id: UserId, db: &mut PgConnection) -> QueryResult<Vec<Self>> {
        let metcon_sessions = MetconSession::get_by_user(user_id, db)?;
        MetconSessionDescription::from_sessions(metcon_sessions, db)
    }
}

impl MetconSessionDescription {
    fn from_session(metcon_session: MetconSession, db: &mut PgConnection) -> QueryResult<Self> {
        let metcon = Metcon::get_by_id(metcon_session.metcon_id, db)?;
        let metcon_movements: Vec<MetconMovement> =
            MetconMovement::belonging_to(&metcon).get_results(db)?;
        let mut movements = vec![];
        for metcon_movement in &metcon_movements {
            movements.push(Movement::get_by_id(metcon_movement.movement_id, db)?);
        }
        let movements = metcon_movements.into_iter().zip(movements).collect();
        Ok(MetconSessionDescription {
            metcon_session,
            metcon,
            movements,
        })
    }

    fn from_sessions(
        metcon_sessions: Vec<MetconSession>,
        db: &mut PgConnection,
    ) -> QueryResult<Vec<Self>> {
        let mut metcons = vec![];
        for metcon_session in &metcon_sessions {
            metcons.push(Metcon::get_by_id(metcon_session.metcon_id, db)?);
        }
        let metcon_movements: Vec<Vec<MetconMovement>> = MetconMovement::belonging_to(&metcons)
            .get_results(db)?
            .grouped_by(&metcons);
        let mut movements = vec![];
        let mut movements_len;
        for metcon_movements in &metcon_movements {
            movements.push(vec![]);
            movements_len = movements.len();
            for metcon_session in metcon_movements {
                movements[movements_len - 1]
                    .push(Movement::get_by_id(metcon_session.movement_id, db)?);
            }
        }
        let movements: Vec<Vec<(MetconMovement, Movement)>> = metcon_movements
            .into_iter()
            .zip(movements)
            .map(|(metcon_movements, movements)| {
                metcon_movements.into_iter().zip(movements).collect()
            })
            .collect();
        Ok(metcon_sessions
            .into_iter()
            .zip(metcons)
            .zip(movements)
            .map(
                |((metcon_session, metcon), movements)| MetconSessionDescription {
                    metcon_session,
                    metcon,
                    movements,
                },
            )
            .collect())
    }

    pub fn get_ordered_by_user_and_timespan(
        user_id: UserId,
        start_datetime: DateTime<Utc>,
        end_datetime: DateTime<Utc>,
        db: &mut PgConnection,
    ) -> QueryResult<Vec<Self>> {
        let metcon_sessions = MetconSession::get_ordered_by_user_and_timespan(
            user_id,
            start_datetime,
            end_datetime,
            db,
        )?;
        MetconSessionDescription::from_sessions(metcon_sessions, db)
    }
}
