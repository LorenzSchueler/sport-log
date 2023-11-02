use axum::http::StatusCode;
use chrono::{DateTime, Utc};
use diesel::{prelude::*, PgConnection, QueryResult};
use sport_log_types::{
    schema::{metcon, metcon_movement},
    Metcon, MetconId, MetconMovement, MetconMovementId, UserId,
};
use sport_log_types_derive::*;

use crate::{auth::*, db::*};

#[derive(
    Db,
    DbWithUserId,
    ModifiableDb,
    Create,
    GetById,
    GetByIds,
    Update,
    HardDelete,
    CheckOptionalUserId,
)]
pub struct MetconDb;

impl GetByUser for MetconDb {
    fn get_by_user(user_id: UserId, db: &mut PgConnection) -> QueryResult<Vec<<Self as Db>::Type>> {
        metcon::table
            .filter(
                metcon::columns::user_id
                    .eq(user_id)
                    .or(metcon::columns::user_id.is_null()),
            )
            .select(Metcon::as_select())
            .get_results(db)
    }
}

impl GetByUserSync for MetconDb {
    fn get_by_user_and_last_sync(
        user_id: UserId,
        last_sync: DateTime<Utc>,
        db: &mut PgConnection,
    ) -> QueryResult<Vec<<Self as Db>::Type>>
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
            .select(Metcon::as_select())
            .get_results(db)
    }
}

impl VerifyIdForUserOrAP for UnverifiedId<MetconId> {
    type Id = MetconId;

    fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Self::Id, StatusCode> {
        if MetconDb::check_optional_user_id(self.0, *auth, db).map_err(|_| StatusCode::FORBIDDEN)? {
            Ok(self.0)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

impl VerifyForUserOrAPWithDb for Unverified<Metcon> {
    type Type = Metcon;

    fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Self::Type, StatusCode> {
        let metcon = self.0;
        if metcon.user_id == Some(*auth)
            && MetconDb::check_user_id(metcon.id, *auth, db)
                .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(metcon)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

impl VerifyMultipleForUserOrAPWithDb for Unverified<Vec<Metcon>> {
    type Type = Metcon;

    fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Vec<Self::Type>, StatusCode> {
        let metcons = self.0;
        let metcon_ids: Vec<_> = metcons.iter().map(|metcon| metcon.id).collect();
        if metcons.iter().all(|metcon| metcon.user_id == Some(*auth))
            && MetconDb::check_user_ids(&metcon_ids, *auth, db)
                .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(metcons)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

impl VerifyForUserOrAPWithoutDb for Unverified<Metcon> {
    type Type = Metcon;

    fn verify_user_ap_without_db(self, auth: AuthUserOrAP) -> Result<Self::Type, StatusCode> {
        let metcon = self.0;
        if metcon.user_id == Some(*auth) {
            Ok(metcon)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

impl VerifyMultipleForUserOrAPWithoutDb for Unverified<Vec<Metcon>> {
    type Type = Metcon;

    fn verify_user_ap_without_db(self, auth: AuthUserOrAP) -> Result<Vec<Self::Type>, StatusCode> {
        let metcons = self.0;
        if metcons.iter().all(|metcon| metcon.user_id == Some(*auth)) {
            Ok(metcons)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

#[derive(Db, ModifiableDb, Create, GetById, GetByIds, Update, HardDelete)]
pub struct MetconMovementDb;

impl GetByUser for MetconMovementDb {
    fn get_by_user(user_id: UserId, db: &mut PgConnection) -> QueryResult<Vec<<Self as Db>::Type>> {
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
            .select(MetconMovement::as_select())
            .get_results(db)
    }
}

impl GetByUserSync for MetconMovementDb {
    fn get_by_user_and_last_sync(
        user_id: UserId,
        last_sync: DateTime<Utc>,
        db: &mut PgConnection,
    ) -> QueryResult<Vec<<Self as Db>::Type>>
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
            .select(MetconMovement::as_select())
            .get_results(db)
    }
}

impl CheckUserId for MetconMovementDb {
    fn check_user_id(id: Self::Id, user_id: UserId, db: &mut PgConnection) -> QueryResult<bool> {
        metcon_movement::table
            .inner_join(metcon::table)
            .filter(metcon_movement::columns::id.eq(id))
            .select(metcon::columns::user_id.is_not_distinct_from(user_id))
            .get_result(db)
            .optional()
            .map(|eq| eq.unwrap_or(false))
    }

    fn check_user_ids(
        ids: &[Self::Id],
        user_id: UserId,
        db: &mut PgConnection,
    ) -> QueryResult<bool> {
        metcon_movement::table
            .inner_join(metcon::table)
            .filter(metcon_movement::columns::id.eq_any(ids))
            .select(metcon::columns::user_id.is_not_distinct_from(user_id))
            .get_results(db)
            .map(|eqs: Vec<bool>| eqs.into_iter().all(|eq| eq))
    }
}

impl CheckOptionalUserId for MetconMovementDb {
    fn check_optional_user_id(
        id: Self::Id,
        user_id: UserId,
        db: &mut PgConnection,
    ) -> QueryResult<bool> {
        metcon_movement::table
            .inner_join(metcon::table)
            .filter(metcon_movement::columns::id.eq(id))
            .select(
                metcon::columns::user_id
                    .is_not_distinct_from(user_id)
                    .or(metcon::columns::user_id.is_null()),
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
        metcon_movement::table
            .inner_join(metcon::table)
            .filter(metcon_movement::columns::id.eq_any(ids))
            .select(
                metcon::columns::user_id
                    .is_not_distinct_from(user_id)
                    .or(metcon::columns::user_id.is_null()),
            )
            .get_results(db)
            .map(|eqs: Vec<bool>| eqs.into_iter().all(|eq| eq))
    }
}

impl VerifyIdForUserOrAP for UnverifiedId<MetconMovementId> {
    type Id = MetconMovementId;

    fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Self::Id, StatusCode> {
        if MetconMovementDb::check_optional_user_id(self.0, *auth, db)
            .map_err(|_| StatusCode::FORBIDDEN)?
        {
            Ok(self.0)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

impl VerifyForUserOrAPWithDb for Unverified<MetconMovement> {
    type Type = MetconMovement;

    fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Self::Type, StatusCode> {
        let metcon_movement = self.0;
        if MetconMovementDb::check_user_id(metcon_movement.id, *auth, db)
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(metcon_movement)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

impl VerifyMultipleForUserOrAPWithDb for Unverified<Vec<MetconMovement>> {
    type Type = MetconMovement;

    fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Vec<Self::Type>, StatusCode> {
        let metcon_movements = self.0;
        let metcon_movement_ids: Vec<_> = metcon_movements
            .iter()
            .map(|metcon_movement| metcon_movement.id)
            .collect();
        if MetconMovementDb::check_user_ids(&metcon_movement_ids, *auth, db)
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(metcon_movements)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

impl VerifyForUserOrAPCreate for Unverified<MetconMovement> {
    type Type = MetconMovement;

    fn verify_user_ap_create(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Self::Type, StatusCode> {
        let metcon_movement = self.0;
        if MetconDb::check_user_id(metcon_movement.metcon_id, *auth, db)
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(metcon_movement)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

impl VerifyMultipleForUserOrAPCreate for Unverified<Vec<MetconMovement>> {
    type Type = MetconMovement;

    fn verify_user_ap_create(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Vec<Self::Type>, StatusCode> {
        let metcon_movements = self.0;
        let mut metcon_ids: Vec<_> = metcon_movements
            .iter()
            .map(|metcon_movement| metcon_movement.metcon_id)
            .collect();
        metcon_ids.sort_unstable();
        metcon_ids.dedup();
        if MetconDb::check_user_ids(&metcon_ids, *auth, db)
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(metcon_movements)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
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
    CheckUserId,
    VerifyForUserOrAPWithDb,
    VerifyForUserOrAPWithoutDb,
)]
pub struct MetconSessionDb;
