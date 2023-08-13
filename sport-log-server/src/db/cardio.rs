use diesel::{prelude::*, PgConnection, QueryResult};
use sport_log_types::{
    schema::{cardio_blueprint, cardio_session, movement},
    UserId,
};
use sport_log_types_derive::*;

use crate::db::*;

#[derive(
    Db,
    DbWithUserId,
    ModifiableDb,
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
    DbWithUserId,
    ModifiableDb,
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
    DbWithUserId,
    DbWithDateTime,
    ModifiableDb,
    VerifyIdForUserOrAP,
    Create,
    GetById,
    GetByIds,
    GetByUser,
    GetByUserTimespan,
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
