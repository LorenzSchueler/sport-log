use diesel::{prelude::*, PgConnection, QueryResult};
use sport_log_types::{
    schema::{cardio_blueprint, cardio_session, movement},
    CardioSession, CardioSessionDescription, CardioSessionId, UserId,
};
use sport_log_types_derive::*;

use crate::db::*;

#[derive(
    Db,
    VerifyIdForUserOrAP,
    Create,
    GetById,
    GetByIds,
    GetByUser,
    GetByUserSync,
    Update,
    HardDelete,
    CheckUserId,
    VerifyForUserOrAPWithDb,
    VerifyForUserOrAPWithoutDb,
)]
pub struct RouteDb;

#[derive(
    Db,
    VerifyIdForUserOrAP,
    Create,
    GetById,
    GetByIds,
    GetByUser,
    GetByUserSync,
    Update,
    HardDelete,
    VerifyForUserOrAPWithDb,
    VerifyForUserOrAPWithoutDb,
)]
pub struct CardioBlueprintDb;

impl CheckUserId for CardioBlueprintDb {
    fn check_user_id(id: Self::Id, user_id: UserId, db: &mut PgConnection) -> QueryResult<bool> {
        cardio_blueprint::table
            .inner_join(movement::table)
            .filter(cardio_blueprint::columns::id.eq(id))
            .select(cardio_blueprint::columns::user_id.eq(user_id))
            .get_result(db)
            .optional()
            .map(|eq| eq.unwrap_or(false))
    }

    fn check_user_ids(
        ids: &[Self::Id],
        user_id: UserId,
        db: &mut PgConnection,
    ) -> QueryResult<bool> {
        cardio_blueprint::table
            .inner_join(movement::table)
            .filter(cardio_blueprint::columns::id.eq_any(ids))
            .select(cardio_blueprint::columns::user_id.eq(user_id))
            .get_results(db)
            .map(|eqs: Vec<bool>| eqs.into_iter().all(|eq| eq))
    }
}

#[derive(
    Db,
    VerifyIdForUserOrAP,
    Create,
    GetById,
    GetByIds,
    GetByUser,
    GetByUserSync,
    Update,
    HardDelete,
    VerifyForUserOrAPWithDb,
    VerifyForUserOrAPWithoutDb,
)]
pub struct CardioSessionDb;

impl CheckUserId for CardioSessionDb {
    fn check_user_id(id: Self::Id, user_id: UserId, db: &mut PgConnection) -> QueryResult<bool> {
        cardio_session::table
            .filter(cardio_session::columns::id.eq(id))
            .select(cardio_session::columns::user_id.eq(user_id))
            .get_result(db)
            .optional()
            .map(|eq| eq.unwrap_or(false))
    }

    fn check_user_ids(
        ids: &[Self::Id],
        user_id: UserId,
        db: &mut PgConnection,
    ) -> QueryResult<bool> {
        cardio_session::table
            .filter(cardio_session::columns::id.eq_any(ids))
            .select(cardio_session::columns::user_id.eq(user_id))
            .get_results(db)
            .map(|eqs: Vec<bool>| eqs.into_iter().all(|eq| eq))
    }
}

pub struct CardioSessionDescriptionDb;

impl Db for CardioSessionDescriptionDb {
    type Id = CardioSessionId;
    type Entity = CardioSessionDescription;
}

impl GetById for CardioSessionDescriptionDb {
    fn get_by_id(
        cardio_session_id: Self::Id,
        db: &mut PgConnection,
    ) -> QueryResult<<Self as Db>::Entity> {
        let cardio_session = CardioSessionDb::get_by_id(cardio_session_id, db)?;
        CardioSessionDescriptionDb::from_session(cardio_session, db)
    }
}

impl GetByUser for CardioSessionDescriptionDb {
    fn get_by_user(
        user_id: UserId,
        db: &mut PgConnection,
    ) -> QueryResult<Vec<<Self as Db>::Entity>> {
        let cardio_sessions = CardioSessionDb::get_by_user(user_id, db)?;
        CardioSessionDescriptionDb::from_sessions(cardio_sessions, db)
    }
}

impl CardioSessionDescriptionDb {
    fn from_session(
        cardio_session: CardioSession,
        db: &mut PgConnection,
    ) -> QueryResult<<Self as Db>::Entity> {
        let route = match cardio_session.route_id {
            Some(route_id) => Some(RouteDb::get_by_id(route_id, db)?),
            None => None,
        };
        let movement = MovementDb::get_by_id(cardio_session.movement_id, db)?;
        Ok(CardioSessionDescription {
            cardio_session,
            route,
            movement,
        })
    }

    fn from_sessions(
        cardio_sessions: Vec<CardioSession>,
        db: &mut PgConnection,
    ) -> QueryResult<Vec<<Self as Db>::Entity>> {
        let mut routes = vec![];
        for cardio_session in &cardio_sessions {
            routes.push(match cardio_session.route_id {
                Some(route_id) => Some(RouteDb::get_by_id(route_id, db)?),
                None => None,
            });
        }
        let mut movements = vec![];
        for cardio_session in &cardio_sessions {
            movements.push(MovementDb::get_by_id(cardio_session.movement_id, db)?);
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
}
