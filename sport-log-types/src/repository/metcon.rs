use chrono::{DateTime, Utc};
use diesel::{prelude::*, PgConnection, QueryResult};

use crate::{
    schema::{metcon, metcon_movement, metcon_session},
    CheckUserId, GetById, GetByUser, GetByUserSync, Metcon, MetconId, MetconMovement,
    MetconMovementId, MetconSession, MetconSessionDescription, MetconSessionId, Movement, UserId,
};

impl GetByUser for Metcon {
    fn get_by_user(user_id: UserId, conn: &PgConnection) -> QueryResult<Vec<Self>> {
        metcon::table
            .filter(
                metcon::columns::user_id
                    .eq(user_id)
                    .or(metcon::columns::user_id.is_null()),
            )
            .get_results(conn)
    }
}

impl GetByUserSync for Metcon {
    fn get_by_user_and_last_sync(
        user_id: UserId,
        last_sync: DateTime<Utc>,
        conn: &PgConnection,
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
            .get_results(conn)
    }
}

impl Metcon {
    pub fn check_user_id_null(
        id: MetconId,
        user_id: UserId,
        conn: &PgConnection,
    ) -> QueryResult<bool> {
        metcon::table
            .filter(metcon::columns::id.eq(id))
            .filter(
                metcon::columns::user_id
                    .eq(user_id)
                    .or(metcon::columns::user_id.is_null()),
            )
            .count()
            .get_result(conn)
            .map(|count: i64| count == 1)
    }

    pub fn check_user_ids_null(
        ids: &Vec<MetconId>,
        user_id: UserId,
        conn: &PgConnection,
    ) -> QueryResult<bool> {
        metcon::table
            .filter(metcon::columns::id.eq_any(ids))
            .filter(
                metcon::columns::user_id
                    .eq(user_id)
                    .or(metcon::columns::user_id.is_null()),
            )
            .count()
            .get_result(conn)
            .map(|count: i64| count == ids.len() as i64)
    }
}

impl MetconSession {
    pub fn get_ordered_by_user_and_timespan(
        user_id: UserId,
        start_datetime: DateTime<Utc>,
        end_datetime: DateTime<Utc>,
        conn: &PgConnection,
    ) -> QueryResult<Vec<Self>> {
        metcon_session::table
            .filter(metcon_session::columns::user_id.eq(user_id))
            .filter(metcon_session::columns::datetime.between(start_datetime, end_datetime))
            .order_by(metcon_session::columns::datetime)
            .get_results(conn)
    }
}

impl GetByUser for MetconMovement {
    fn get_by_user(user_id: UserId, conn: &PgConnection) -> QueryResult<Vec<Self>> {
        metcon_movement::table
            .filter(
                metcon_movement::columns::metcon_id.eq_any(
                    metcon::table
                        .filter(metcon::columns::user_id.eq(user_id))
                        .select(metcon::columns::id),
                ),
            )
            .get_results(conn)
    }
}

impl GetByUserSync for MetconMovement {
    fn get_by_user_and_last_sync(
        user_id: UserId,
        last_sync: DateTime<Utc>,
        conn: &PgConnection,
    ) -> QueryResult<Vec<Self>>
    where
        Self: Sized,
    {
        metcon_movement::table
            .filter(
                metcon_movement::columns::metcon_id.eq_any(
                    metcon::table
                        .filter(metcon::columns::user_id.eq(user_id))
                        .select(metcon::columns::id),
                ),
            )
            .filter(metcon_movement::columns::last_change.ge(last_sync))
            .get_results(conn)
    }
}

impl CheckUserId for MetconMovement {
    type Id = MetconMovementId;

    fn check_user_id(id: Self::Id, user_id: UserId, conn: &PgConnection) -> QueryResult<bool> {
        metcon_movement::table
            .inner_join(metcon::table)
            .filter(metcon_movement::columns::id.eq(id))
            .filter(metcon::columns::user_id.eq(user_id))
            .count()
            .get_result(conn)
            .map(|count: i64| count == 1)
    }

    fn check_user_ids(
        ids: &Vec<Self::Id>,
        user_id: UserId,
        conn: &PgConnection,
    ) -> QueryResult<bool> {
        metcon_movement::table
            .inner_join(metcon::table)
            .filter(metcon_movement::columns::id.eq_any(ids))
            .filter(metcon::columns::user_id.eq(user_id))
            .count()
            .get_result(conn)
            .map(|count: i64| count == ids.len() as i64)
    }
}

impl MetconMovement {
    pub fn check_user_id_null(
        id: MetconMovementId,
        user_id: UserId,
        conn: &PgConnection,
    ) -> QueryResult<bool> {
        metcon_movement::table
            .inner_join(metcon::table)
            .filter(metcon_movement::columns::id.eq(id))
            .filter(
                metcon::columns::user_id
                    .eq(user_id)
                    .or(metcon::columns::user_id.is_null()),
            )
            .count()
            .get_result(conn)
            .map(|count: i64| count == 1)
    }

    pub fn check_user_ids_null(
        ids: &Vec<MetconMovementId>,
        user_id: UserId,
        conn: &PgConnection,
    ) -> QueryResult<bool> {
        metcon_movement::table
            .inner_join(metcon::table)
            .filter(metcon_movement::columns::id.eq_any(ids))
            .filter(
                metcon::columns::user_id
                    .eq(user_id)
                    .or(metcon::columns::user_id.is_null()),
            )
            .count()
            .get_result(conn)
            .map(|count: i64| count == ids.len() as i64)
    }
}

impl MetconMovement {
    pub fn get_by_metcon(metcon_id: MetconId, conn: &PgConnection) -> QueryResult<Vec<Self>> {
        metcon_movement::table
            .filter(metcon_movement::columns::metcon_id.eq(metcon_id))
            .get_results(conn)
    }
}

impl GetById for MetconSessionDescription {
    type Id = MetconSessionId;

    fn get_by_id(metcon_session_id: Self::Id, conn: &PgConnection) -> QueryResult<Self> {
        let metcon_session = MetconSession::get_by_id(metcon_session_id, conn)?;
        MetconSessionDescription::from_session(metcon_session, conn)
    }
}

impl GetByUser for MetconSessionDescription {
    fn get_by_user(user_id: UserId, conn: &PgConnection) -> QueryResult<Vec<Self>> {
        let metcon_sessions = MetconSession::get_by_user(user_id, conn)?;
        MetconSessionDescription::from_sessions(metcon_sessions, conn)
    }
}

impl MetconSessionDescription {
    fn from_session(metcon_session: MetconSession, conn: &PgConnection) -> QueryResult<Self> {
        let metcon = Metcon::get_by_id(metcon_session.metcon_id, conn)?;
        let metcon_movements: Vec<MetconMovement> =
            MetconMovement::belonging_to(&metcon).get_results(conn)?;
        let mut movements = vec![];
        for metcon_movement in &metcon_movements {
            movements.push(Movement::get_by_id(metcon_movement.movement_id, conn)?);
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
        conn: &PgConnection,
    ) -> QueryResult<Vec<Self>> {
        let mut metcons = vec![];
        for metcon_session in &metcon_sessions {
            metcons.push(Metcon::get_by_id(metcon_session.metcon_id, conn)?);
        }
        let metcon_movements: Vec<Vec<MetconMovement>> = MetconMovement::belonging_to(&metcons)
            .get_results(conn)?
            .grouped_by(&metcons);
        let mut movements = vec![];
        let mut movements_len;
        for metcon_movements in &metcon_movements {
            movements.push(vec![]);
            movements_len = movements.len();
            for metcon_session in metcon_movements {
                movements[movements_len - 1]
                    .push(Movement::get_by_id(metcon_session.movement_id, conn)?);
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
        conn: &PgConnection,
    ) -> QueryResult<Vec<Self>> {
        let metcon_sessions = MetconSession::get_ordered_by_user_and_timespan(
            user_id,
            start_datetime,
            end_datetime,
            conn,
        )?;
        MetconSessionDescription::from_sessions(metcon_sessions, conn)
    }
}
