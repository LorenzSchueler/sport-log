use axum::http::StatusCode;
use chrono::{DateTime, Utc};
use diesel::prelude::*;
use sport_log_types::{
    schema::{movement, movement_muscle},
    Movement, MovementId, MovementMuscle, MovementMuscleId, UserId,
};
use sport_log_types_derive::*;

use crate::{auth::*, db::*};

#[derive(
    Db,
    VerifyIdForAdmin,
    VerifyIdUnchecked,
    Create,
    GetById,
    GetByIds,
    Update,
    HardDelete,
    CheckOptionalUserId,
    VerifyForAdminWithoutDb,
)]
pub struct MovementDb;

impl GetByUser for MovementDb {
    fn get_by_user(
        user_id: UserId,
        db: &mut PgConnection,
    ) -> QueryResult<Vec<<Self as Db>::Entity>> {
        movement::table
            .filter(
                movement::columns::user_id
                    .eq(user_id)
                    .or(movement::columns::user_id.is_null()),
            )
            .select(Movement::as_select())
            .get_results(db)
    }
}

impl GetByUserSync for MovementDb {
    fn get_by_user_and_last_sync(
        user_id: UserId,
        last_sync: chrono::DateTime<chrono::Utc>,
        db: &mut PgConnection,
    ) -> QueryResult<Vec<<Self as Db>::Entity>>
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
            .select(Movement::as_select())
            .get_results(db)
    }
}

impl VerifyIdForUserOrAP for UnverifiedId<MovementId> {
    type Id = MovementId;

    fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Self::Id, StatusCode> {
        if MovementDb::check_optional_user_id(self.0, *auth, db)
            .map_err(|_| StatusCode::FORBIDDEN)?
        {
            Ok(self.0)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

impl VerifyForUserOrAPWithDb for Unverified<Movement> {
    type Entity = Movement;

    fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Self::Entity, StatusCode> {
        let movement = self.0;
        if movement.user_id == Some(*auth)
            && MovementDb::get_by_id(movement.id, db)
                .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
                .user_id
                == Some(*auth)
        {
            Ok(movement)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

impl VerifyMultipleForUserOrAPWithDb for Unverified<Vec<Movement>> {
    type Entity = Movement;

    fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Vec<Self::Entity>, StatusCode> {
        let movements = self.0;
        let movement_ids: Vec<_> = movements.iter().map(|movement| movement.id).collect();
        if movements
            .iter()
            .all(|movement| movement.user_id == Some(*auth))
            && MovementDb::check_user_ids(&movement_ids, *auth, db)
                .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(movements)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

impl VerifyForUserOrAPWithoutDb for Unverified<Movement> {
    type Entity = Movement;

    fn verify_user_ap_without_db(self, auth: AuthUserOrAP) -> Result<Self::Entity, StatusCode> {
        let movement = self.0;
        if movement.user_id == Some(*auth) {
            Ok(movement)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

impl VerifyMultipleForUserOrAPWithoutDb for Unverified<Vec<Movement>> {
    type Entity = Movement;

    fn verify_user_ap_without_db(
        self,
        auth: AuthUserOrAP,
    ) -> Result<Vec<Self::Entity>, StatusCode> {
        let movements = self.0;
        if movements
            .iter()
            .all(|movement| movement.user_id == Some(*auth))
        {
            Ok(movements)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

#[derive(Db, VerifyIdForAdmin, GetById, GetByIds, GetAll)]
pub struct MuscleGroupDb;

#[derive(Db, Create, GetById, GetByIds, Update, HardDelete)]
pub struct MovementMuscleDb;

impl VerifyIdForUserOrAP for UnverifiedId<MovementMuscleId> {
    type Id = MovementMuscleId;

    fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Self::Id, StatusCode> {
        if MovementMuscleDb::check_optional_user_id(self.0, *auth, db)
            .map_err(|_| StatusCode::FORBIDDEN)?
        {
            Ok(self.0)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

impl VerifyForUserOrAPWithDb for Unverified<MovementMuscle> {
    type Entity = MovementMuscle;

    fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Self::Entity, StatusCode> {
        let movement_muscle = self.0;
        if MovementMuscleDb::check_user_id(movement_muscle.id, *auth, db)
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(movement_muscle)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

impl VerifyMultipleForUserOrAPWithDb for Unverified<Vec<MovementMuscle>> {
    type Entity = MovementMuscle;

    fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Vec<Self::Entity>, StatusCode> {
        let movement_muscle = self.0;
        let movement_muscle_ids: Vec<_> = movement_muscle
            .iter()
            .map(|metcon_movement| metcon_movement.id)
            .collect();
        if MovementMuscleDb::check_user_ids(&movement_muscle_ids, *auth, db)
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(movement_muscle)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

impl VerifyForUserOrAPCreate for Unverified<MovementMuscle> {
    type Entity = MovementMuscle;

    fn verify_user_ap_create(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Self::Entity, StatusCode> {
        let movement_muscle = self.0;
        if MovementDb::check_user_id(movement_muscle.movement_id, *auth, db)
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(movement_muscle)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

impl VerifyMultipleForUserOrAPCreate for Unverified<Vec<MovementMuscle>> {
    type Entity = MovementMuscle;

    fn verify_user_ap_create(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Vec<Self::Entity>, StatusCode> {
        let movement_muscle = self.0;
        let mut movement_ids: Vec<_> = movement_muscle
            .iter()
            .map(|metcon_movement| metcon_movement.movement_id)
            .collect();
        movement_ids.sort_unstable();
        movement_ids.dedup();
        if MovementDb::check_user_ids(&movement_ids, *auth, db)
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(movement_muscle)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

impl GetByUser for MovementMuscleDb {
    fn get_by_user(
        user_id: UserId,
        db: &mut PgConnection,
    ) -> QueryResult<Vec<<Self as Db>::Entity>> {
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
            .select(MovementMuscle::as_select())
            .get_results(db)
    }
}

impl GetByUserSync for MovementMuscleDb {
    fn get_by_user_and_last_sync(
        user_id: UserId,
        last_sync: DateTime<Utc>,
        db: &mut PgConnection,
    ) -> QueryResult<Vec<<Self as Db>::Entity>>
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
            .select(MovementMuscle::as_select())
            .get_results(db)
    }
}

impl CheckUserId for MovementMuscleDb {
    fn check_user_id(id: Self::Id, user_id: UserId, db: &mut PgConnection) -> QueryResult<bool> {
        movement_muscle::table
            .inner_join(movement::table)
            .filter(movement_muscle::columns::id.eq(id))
            .select(movement::columns::user_id.is_not_distinct_from(user_id))
            .get_result(db)
            .optional()
            .map(|eq| eq.unwrap_or(false))
    }

    fn check_user_ids(
        ids: &[Self::Id],
        user_id: UserId,
        db: &mut PgConnection,
    ) -> QueryResult<bool> {
        movement_muscle::table
            .inner_join(movement::table)
            .filter(movement_muscle::columns::id.eq_any(ids))
            .select(movement::columns::user_id.is_not_distinct_from(user_id))
            .get_results(db)
            .map(|eqs: Vec<bool>| eqs.into_iter().all(|eq| eq))
    }
}

impl CheckOptionalUserId for MovementMuscleDb {
    fn check_optional_user_id(
        id: Self::Id,
        user_id: UserId,
        db: &mut PgConnection,
    ) -> QueryResult<bool> {
        movement_muscle::table
            .inner_join(movement::table)
            .filter(movement_muscle::columns::id.eq(id))
            .select(
                movement::columns::user_id
                    .is_not_distinct_from(user_id)
                    .or(movement::columns::user_id.is_null()),
            )
            .get_result(db)
            .optional()
            .map(|eq| eq.unwrap_or(false))
    }

    fn check_optional_user_ids(
        ids: &[Self::Id],
        user_id: UserId,
        db: &mut PgConnection,
    ) -> QueryResult<bool> {
        movement_muscle::table
            .inner_join(movement::table)
            .filter(movement_muscle::columns::id.eq_any(ids))
            .select(
                movement::columns::user_id
                    .is_not_distinct_from(user_id)
                    .or(movement::columns::user_id.is_null()),
            )
            .get_results(db)
            .map(|eqs: Vec<bool>| eqs.into_iter().all(|eq| eq))
    }
}

#[derive(Db, VerifyIdForAdmin, GetById, GetByIds, GetAll)]
pub struct EormDb;
