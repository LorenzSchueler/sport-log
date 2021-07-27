use chrono::NaiveDateTime;
use diesel::{prelude::*, PgConnection, QueryResult};

use crate::{
    schema::{metcon, metcon_movement, metcon_session},
    types::{
        GetById, GetByUser, Metcon, MetconId, MetconMovement, MetconSession,
        MetconSessionDescription, MetconSessionId, Movement, UserId,
    },
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

impl MetconSession {
    pub fn get_ordered_by_user_and_timespan(
        user_id: UserId,
        start: NaiveDateTime,
        end: NaiveDateTime,
        conn: &PgConnection,
    ) -> QueryResult<Vec<Self>> {
        metcon_session::table
            .filter(metcon_session::columns::user_id.ge(user_id))
            .filter(metcon_session::columns::datetime.ge(start))
            .filter(metcon_session::columns::datetime.le(end))
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
                        .select(metcon::columns::id)
                        .get_results::<MetconId>(conn)?,
                ),
            )
            .get_results(conn)
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
        start_datetime: NaiveDateTime,
        end_datetime: NaiveDateTime,
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
