use chrono::{DateTime, Utc};
use diesel::{prelude::*, PgConnection, QueryResult};

use crate::{
    schema::{strength_session, strength_set},
    GetById, GetByUser, GetByUserSync, Movement, StrengthSession, StrengthSessionDescription,
    StrengthSessionId, StrengthSet, UserId,
};

impl StrengthSession {
    pub fn get_ordered_by_user_and_timespan(
        user_id: UserId,
        start_datetime: DateTime<Utc>,
        end_datetime: DateTime<Utc>,
        conn: &PgConnection,
    ) -> QueryResult<Vec<Self>> {
        strength_session::table
            .filter(strength_session::columns::user_id.eq(user_id))
            .filter(strength_session::columns::datetime.between(start_datetime, end_datetime))
            .order_by(strength_session::columns::datetime)
            .get_results(conn)
    }
}

impl GetByUser for StrengthSet {
    fn get_by_user(user_id: UserId, conn: &PgConnection) -> QueryResult<Vec<Self>> {
        strength_set::table
            .filter(
                strength_set::columns::strength_session_id.eq_any(
                    strength_session::table
                        .filter(strength_session::columns::user_id.eq(user_id))
                        .select(strength_session::columns::id),
                ),
            )
            .get_results(conn)
    }
}

impl GetByUserSync for StrengthSet {
    fn get_by_user_and_last_sync(
        user_id: UserId,
        last_sync: DateTime<Utc>,
        conn: &PgConnection,
    ) -> QueryResult<Vec<Self>>
    where
        Self: Sized,
    {
        strength_set::table
            .filter(
                strength_set::columns::strength_session_id.eq_any(
                    strength_session::table
                        .filter(strength_session::columns::user_id.eq(user_id))
                        .select(strength_session::columns::id),
                ),
            )
            .filter(strength_set::columns::last_change.ge(last_sync))
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

impl GetById for StrengthSessionDescription {
    type Id = StrengthSessionId;

    fn get_by_id(strength_session_id: Self::Id, conn: &PgConnection) -> QueryResult<Self> {
        let strength_session = StrengthSession::get_by_id(strength_session_id, conn)?;
        StrengthSessionDescription::from_session(strength_session, conn)
    }
}

impl GetByUser for StrengthSessionDescription {
    fn get_by_user(user_id: UserId, conn: &PgConnection) -> QueryResult<Vec<Self>> {
        let strength_sessions = StrengthSession::get_by_user(user_id, conn)?;
        StrengthSessionDescription::from_sessions(strength_sessions, conn)
    }
}

impl StrengthSessionDescription {
    fn from_session(strength_session: StrengthSession, conn: &PgConnection) -> QueryResult<Self> {
        let strength_sets = StrengthSet::belonging_to(&strength_session).get_results(conn)?;
        let movement = Movement::get_by_id(strength_session.movement_id, conn)?;
        Ok(StrengthSessionDescription {
            strength_session,
            strength_sets,
            movement,
        })
    }

    fn from_sessions(
        strength_sessions: Vec<StrengthSession>,
        conn: &PgConnection,
    ) -> QueryResult<Vec<Self>> {
        let strength_sets = StrengthSet::belonging_to(&strength_sessions)
            .get_results(conn)?
            .grouped_by(&strength_sessions);
        let mut movements = vec![];
        for strength_session in &strength_sessions {
            movements.push(Movement::get_by_id(strength_session.movement_id, conn)?);
        }
        Ok(strength_sessions
            .into_iter()
            .zip(strength_sets)
            .zip(movements)
            .map(
                |((strength_session, strength_sets), movement)| StrengthSessionDescription {
                    strength_session,
                    strength_sets,
                    movement,
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
        let strength_sessions = StrengthSession::get_ordered_by_user_and_timespan(
            user_id,
            start_datetime,
            end_datetime,
            conn,
        )?;
        StrengthSessionDescription::from_sessions(strength_sessions, conn)
    }
}
