use chrono::{DateTime, Utc};
use diesel::{prelude::*, PgConnection, QueryResult};

use crate::{
    schema::{cardio_blueprint, cardio_session, movement},
    CardioBlueprint, CardioBlueprintId, CardioSession, CardioSessionDescription, CardioSessionId,
    CheckUserId, GetById, GetByUser, Movement, Route, UserId,
};

impl CheckUserId for CardioBlueprint {
    type Id = CardioBlueprintId;

    fn check_user_id(id: Self::Id, user_id: UserId, db: &mut PgConnection) -> QueryResult<bool> {
        cardio_blueprint::table
            .inner_join(movement::table)
            .filter(cardio_blueprint::columns::id.eq(id))
            .filter(cardio_blueprint::columns::user_id.eq(user_id))
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
        cardio_blueprint::table
            .inner_join(movement::table)
            .filter(cardio_blueprint::columns::id.eq_any(ids))
            .filter(cardio_blueprint::columns::user_id.eq(user_id))
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

impl CheckUserId for CardioSession {
    type Id = CardioSessionId;

    fn check_user_id(id: Self::Id, user_id: UserId, db: &mut PgConnection) -> QueryResult<bool> {
        cardio_session::table
            .inner_join(movement::table)
            .filter(cardio_session::columns::id.eq(id))
            .filter(cardio_session::columns::user_id.eq(user_id))
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
        cardio_session::table
            .inner_join(movement::table)
            .filter(cardio_session::columns::id.eq_any(ids))
            .filter(cardio_session::columns::user_id.eq(user_id))
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

impl CardioSession {
    pub fn get_ordered_by_user_and_timespan(
        user_id: UserId,
        start_datetime: DateTime<Utc>,
        end_datetime: DateTime<Utc>,
        db: &mut PgConnection,
    ) -> QueryResult<Vec<Self>> {
        cardio_session::table
            .filter(cardio_session::columns::user_id.eq(user_id))
            .filter(cardio_session::columns::datetime.between(start_datetime, end_datetime))
            .order_by(cardio_session::columns::datetime)
            .select(CardioSession::as_select())
            .get_results(db)
    }
}

impl GetById for CardioSessionDescription {
    type Id = CardioSessionId;

    fn get_by_id(cardio_session_id: Self::Id, db: &mut PgConnection) -> QueryResult<Self> {
        let cardio_session = CardioSession::get_by_id(cardio_session_id, db)?;
        CardioSessionDescription::from_session(cardio_session, db)
    }
}

impl GetByUser for CardioSessionDescription {
    fn get_by_user(user_id: UserId, db: &mut PgConnection) -> QueryResult<Vec<Self>> {
        let cardio_sessions = CardioSession::get_by_user(user_id, db)?;
        CardioSessionDescription::from_sessions(cardio_sessions, db)
    }
}

impl CardioSessionDescription {
    fn from_session(cardio_session: CardioSession, db: &mut PgConnection) -> QueryResult<Self> {
        let route = match cardio_session.route_id {
            Some(route_id) => Some(Route::get_by_id(route_id, db)?),
            None => None,
        };
        let movement = Movement::get_by_id(cardio_session.movement_id, db)?;
        Ok(CardioSessionDescription {
            cardio_session,
            route,
            movement,
        })
    }

    fn from_sessions(
        cardio_sessions: Vec<CardioSession>,
        db: &mut PgConnection,
    ) -> QueryResult<Vec<Self>> {
        let mut routes = vec![];
        for cardio_session in &cardio_sessions {
            routes.push(match cardio_session.route_id {
                Some(route_id) => Some(Route::get_by_id(route_id, db)?),
                None => None,
            });
        }
        let mut movements = vec![];
        for cardio_session in &cardio_sessions {
            movements.push(Movement::get_by_id(cardio_session.movement_id, db)?);
        }
        Ok(cardio_sessions
            .into_iter()
            .zip(routes)
            .zip(movements)
            .map(
                |((cardio_session, route), movement)| CardioSessionDescription {
                    cardio_session,
                    route,
                    movement,
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
        let cardio_sessions = CardioSession::get_ordered_by_user_and_timespan(
            user_id,
            start_datetime,
            end_datetime,
            db,
        )?;
        CardioSessionDescription::from_sessions(cardio_sessions, db)
    }
}
