use chrono::{DateTime, Utc};
use diesel::{prelude::*, PgConnection, QueryResult};

use crate::{
    schema::{
        movement, strength_blueprint, strength_blueprint_set, strength_session, strength_set,
    },
    CheckUserId, GetById, GetByUser, GetByUserSync, Movement, StrengthBlueprint,
    StrengthBlueprintId, StrengthBlueprintSet, StrengthBlueprintSetId, StrengthSession,
    StrengthSessionDescription, StrengthSessionId, StrengthSet, StrengthSetId, UserId,
};

impl CheckUserId for StrengthBlueprint {
    type Id = StrengthBlueprintId;

    fn check_user_id(id: Self::Id, user_id: UserId, db: &PgConnection) -> QueryResult<bool> {
        strength_blueprint::table
            .inner_join(movement::table)
            .filter(strength_blueprint::columns::id.eq(id))
            .filter(strength_blueprint::columns::user_id.eq(user_id))
            .filter(
                movement::columns::user_id
                    .eq(user_id)
                    .or(movement::columns::user_id.is_null()),
            )
            .count()
            .get_result(db)
            .map(|count: i64| count == 1)
    }

    fn check_user_ids(ids: &[Self::Id], user_id: UserId, db: &PgConnection) -> QueryResult<bool> {
        strength_blueprint::table
            .inner_join(movement::table)
            .filter(strength_blueprint::columns::id.eq_any(ids))
            .filter(strength_blueprint::columns::user_id.eq(user_id))
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

impl GetByUser for StrengthBlueprintSet {
    fn get_by_user(user_id: UserId, db: &PgConnection) -> QueryResult<Vec<Self>> {
        strength_blueprint_set::table
            .filter(
                strength_blueprint_set::columns::strength_blueprint_id.eq_any(
                    strength_blueprint::table
                        .filter(strength_blueprint::columns::user_id.eq(user_id))
                        .select(strength_blueprint::columns::id),
                ),
            )
            .get_results(db)
    }
}

impl GetByUserSync for StrengthBlueprintSet {
    fn get_by_user_and_last_sync(
        user_id: UserId,
        last_sync: DateTime<Utc>,
        db: &PgConnection,
    ) -> QueryResult<Vec<Self>>
    where
        Self: Sized,
    {
        strength_blueprint_set::table
            .filter(
                strength_blueprint_set::columns::strength_blueprint_id.eq_any(
                    strength_blueprint::table
                        .filter(strength_blueprint::columns::user_id.eq(user_id))
                        .select(strength_blueprint::columns::id),
                ),
            )
            .filter(strength_blueprint_set::columns::last_change.ge(last_sync))
            .get_results(db)
    }
}

impl CheckUserId for StrengthBlueprintSet {
    type Id = StrengthBlueprintSetId;

    fn check_user_id(id: Self::Id, user_id: UserId, db: &PgConnection) -> QueryResult<bool> {
        strength_blueprint_set::table
            .inner_join(strength_blueprint::table)
            .filter(strength_blueprint_set::columns::id.eq(id))
            .filter(strength_blueprint::columns::user_id.eq(user_id))
            .count()
            .get_result(db)
            .map(|count: i64| count == 1)
    }

    fn check_user_ids(ids: &[Self::Id], user_id: UserId, db: &PgConnection) -> QueryResult<bool> {
        strength_blueprint_set::table
            .inner_join(strength_blueprint::table)
            .filter(strength_blueprint_set::columns::id.eq_any(ids))
            .filter(strength_blueprint::columns::user_id.eq(user_id))
            .count()
            .get_result(db)
            .map(|count: i64| count == ids.len() as i64)
    }
}

impl StrengthBlueprintSet {
    pub fn get_by_strength_blueprint(
        strength_blueprint_id: StrengthBlueprintId,
        db: &PgConnection,
    ) -> QueryResult<Vec<Self>> {
        strength_blueprint_set::table
            .filter(
                strength_blueprint_set::columns::strength_blueprint_id.eq(strength_blueprint_id),
            )
            .get_results(db)
    }
}

impl CheckUserId for StrengthSession {
    type Id = StrengthSessionId;

    fn check_user_id(id: Self::Id, user_id: UserId, db: &PgConnection) -> QueryResult<bool> {
        strength_session::table
            .inner_join(movement::table)
            .filter(strength_session::columns::id.eq(id))
            .filter(strength_session::columns::user_id.eq(user_id))
            .filter(
                movement::columns::user_id
                    .eq(user_id)
                    .or(movement::columns::user_id.is_null()),
            )
            .count()
            .get_result(db)
            .map(|count: i64| count == 1)
    }

    fn check_user_ids(ids: &[Self::Id], user_id: UserId, db: &PgConnection) -> QueryResult<bool> {
        strength_session::table
            .inner_join(movement::table)
            .filter(strength_session::columns::id.eq_any(ids))
            .filter(strength_session::columns::user_id.eq(user_id))
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

impl StrengthSession {
    pub fn get_ordered_by_user_and_timespan(
        user_id: UserId,
        start_datetime: DateTime<Utc>,
        end_datetime: DateTime<Utc>,
        db: &PgConnection,
    ) -> QueryResult<Vec<Self>> {
        strength_session::table
            .filter(strength_session::columns::user_id.eq(user_id))
            .filter(strength_session::columns::datetime.between(start_datetime, end_datetime))
            .order_by(strength_session::columns::datetime)
            .get_results(db)
    }
}

impl GetByUser for StrengthSet {
    fn get_by_user(user_id: UserId, db: &PgConnection) -> QueryResult<Vec<Self>> {
        strength_set::table
            .filter(
                strength_set::columns::strength_session_id.eq_any(
                    strength_session::table
                        .filter(strength_session::columns::user_id.eq(user_id))
                        .select(strength_session::columns::id),
                ),
            )
            .get_results(db)
    }
}

impl GetByUserSync for StrengthSet {
    fn get_by_user_and_last_sync(
        user_id: UserId,
        last_sync: DateTime<Utc>,
        db: &PgConnection,
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
            .get_results(db)
    }
}

impl CheckUserId for StrengthSet {
    type Id = StrengthSetId;

    fn check_user_id(id: Self::Id, user_id: UserId, db: &PgConnection) -> QueryResult<bool> {
        strength_set::table
            .inner_join(strength_session::table)
            .filter(strength_set::columns::id.eq(id))
            .filter(strength_session::columns::user_id.eq(user_id))
            .count()
            .get_result(db)
            .map(|count: i64| count == 1)
    }

    fn check_user_ids(ids: &[Self::Id], user_id: UserId, db: &PgConnection) -> QueryResult<bool> {
        strength_set::table
            .inner_join(strength_session::table)
            .filter(strength_set::columns::id.eq_any(ids))
            .filter(strength_session::columns::user_id.eq(user_id))
            .count()
            .get_result(db)
            .map(|count: i64| count == ids.len() as i64)
    }
}

impl StrengthSet {
    pub fn get_by_strength_session(
        strength_session_id: StrengthSessionId,
        db: &PgConnection,
    ) -> QueryResult<Vec<Self>> {
        strength_set::table
            .filter(strength_set::columns::strength_session_id.eq(strength_session_id))
            .get_results(db)
    }
}

impl GetById for StrengthSessionDescription {
    type Id = StrengthSessionId;

    fn get_by_id(strength_session_id: Self::Id, db: &PgConnection) -> QueryResult<Self> {
        let strength_session = StrengthSession::get_by_id(strength_session_id, db)?;
        StrengthSessionDescription::from_session(strength_session, db)
    }
}

impl GetByUser for StrengthSessionDescription {
    fn get_by_user(user_id: UserId, db: &PgConnection) -> QueryResult<Vec<Self>> {
        let strength_sessions = StrengthSession::get_by_user(user_id, db)?;
        StrengthSessionDescription::from_sessions(strength_sessions, db)
    }
}

impl StrengthSessionDescription {
    fn from_session(strength_session: StrengthSession, db: &PgConnection) -> QueryResult<Self> {
        let strength_sets = StrengthSet::belonging_to(&strength_session).get_results(db)?;
        let movement = Movement::get_by_id(strength_session.movement_id, db)?;
        Ok(StrengthSessionDescription {
            strength_session,
            strength_sets,
            movement,
        })
    }

    fn from_sessions(
        strength_sessions: Vec<StrengthSession>,
        db: &PgConnection,
    ) -> QueryResult<Vec<Self>> {
        let strength_sets = StrengthSet::belonging_to(&strength_sessions)
            .get_results(db)?
            .grouped_by(&strength_sessions);
        let mut movements = vec![];
        for strength_session in &strength_sessions {
            movements.push(Movement::get_by_id(strength_session.movement_id, db)?);
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
        db: &PgConnection,
    ) -> QueryResult<Vec<Self>> {
        let strength_sessions = StrengthSession::get_ordered_by_user_and_timespan(
            user_id,
            start_datetime,
            end_datetime,
            db,
        )?;
        StrengthSessionDescription::from_sessions(strength_sessions, db)
    }
}
