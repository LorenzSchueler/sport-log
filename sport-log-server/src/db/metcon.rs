use axum::http::StatusCode;
use chrono::{DateTime, Utc};
use diesel::{prelude::*, PgConnection, QueryResult};
use sport_log_types::{
    schema::{metcon, metcon_item, metcon_movement, training_plan},
    Metcon, MetconId, MetconItem, MetconMovement, MetconMovementId, MetconSession,
    MetconSessionDescription, MetconSessionId, Movement, UserId,
};
use sport_log_types_derive::*;

use crate::{auth::*, db::*};

#[derive(Db, Create, GetById, GetByIds, Update, HardDelete, CheckOptionalUserId)]
pub struct MetconDb;

impl GetByUser for MetconDb {
    fn get_by_user(
        user_id: UserId,
        db: &mut PgConnection,
    ) -> QueryResult<Vec<<Self as Db>::Entity>> {
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
    ) -> QueryResult<Vec<<Self as Db>::Entity>>
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
    type Entity = Metcon;

    fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Self::Entity, StatusCode> {
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
    type Entity = Metcon;

    fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Vec<Self::Entity>, StatusCode> {
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
    type Entity = Metcon;

    fn verify_user_ap_without_db(self, auth: AuthUserOrAP) -> Result<Self::Entity, StatusCode> {
        let metcon = self.0;
        if metcon.user_id == Some(*auth) {
            Ok(metcon)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

impl VerifyMultipleForUserOrAPWithoutDb for Unverified<Vec<Metcon>> {
    type Entity = Metcon;

    fn verify_user_ap_without_db(
        self,
        auth: AuthUserOrAP,
    ) -> Result<Vec<Self::Entity>, StatusCode> {
        let metcons = self.0;
        if metcons.iter().all(|metcon| metcon.user_id == Some(*auth)) {
            Ok(metcons)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

#[derive(Db, Create, GetById, GetByIds, Update, HardDelete)]
pub struct MetconMovementDb;

impl GetByUser for MetconMovementDb {
    fn get_by_user(
        user_id: UserId,
        db: &mut PgConnection,
    ) -> QueryResult<Vec<<Self as Db>::Entity>> {
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
    ) -> QueryResult<Vec<<Self as Db>::Entity>>
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
    type Entity = MetconMovement;

    fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Self::Entity, StatusCode> {
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
    type Entity = MetconMovement;

    fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Vec<Self::Entity>, StatusCode> {
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
    type Entity = MetconMovement;

    fn verify_user_ap_create(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Self::Entity, StatusCode> {
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
    type Entity = MetconMovement;

    fn verify_user_ap_create(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Vec<Self::Entity>, StatusCode> {
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

#[derive(Db, VerifyIdForUserOrAP, Create, GetById, GetByIds, Update, HardDelete)]
pub struct MetconItemDb;

impl GetByUser for MetconItemDb {
    fn get_by_user(
        user_id: UserId,
        db: &mut PgConnection,
    ) -> QueryResult<Vec<<Self as Db>::Entity>> {
        metcon_item::table
            .filter(
                metcon_item::columns::training_plan_id.eq_any(
                    training_plan::table
                        .filter(training_plan::columns::user_id.eq(user_id))
                        .select(training_plan::columns::id),
                ),
            )
            .select(MetconItem::as_select())
            .get_results(db)
    }
}

impl GetByUserSync for MetconItemDb {
    fn get_by_user_and_last_sync(
        user_id: UserId,
        last_sync: DateTime<Utc>,
        db: &mut PgConnection,
    ) -> QueryResult<Vec<<Self as Db>::Entity>>
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
            .select(MetconItem::as_select())
            .get_results(db)
    }
}

impl CheckUserId for MetconItemDb {
    fn check_user_id(id: Self::Id, user_id: UserId, db: &mut PgConnection) -> QueryResult<bool> {
        metcon_item::table
            .inner_join(training_plan::table)
            .filter(metcon_item::columns::id.eq(id))
            .select(training_plan::columns::user_id.eq(user_id))
            .get_result(db)
            .optional()
            .map(|eq| eq.unwrap_or(false))
    }

    fn check_user_ids(
        ids: &[Self::Id],
        user_id: UserId,
        db: &mut PgConnection,
    ) -> QueryResult<bool> {
        metcon_item::table
            .inner_join(training_plan::table)
            .filter(metcon_item::columns::id.eq_any(ids))
            .select(training_plan::columns::user_id.eq(user_id))
            .get_results(db)
            .map(|eqs: Vec<bool>| eqs.into_iter().all(|eq| eq))
    }
}

impl CheckOptionalUserId for MetconItemDb {
    fn check_optional_user_id(
        id: Self::Id,
        user_id: UserId,
        db: &mut PgConnection,
    ) -> QueryResult<bool> {
        metcon_item::table
            .inner_join(training_plan::table)
            .filter(metcon_item::columns::id.eq(id))
            .select(training_plan::columns::user_id.eq(user_id))
            .get_result(db)
            .optional()
            .map(|eq| eq.unwrap_or(false))
    }

    fn check_optional_user_ids(
        ids: &[Self::Id],
        user_id: UserId,
        db: &mut PgConnection,
    ) -> QueryResult<bool> {
        metcon_item::table
            .inner_join(training_plan::table)
            .filter(metcon_item::columns::id.eq_any(ids))
            .select(training_plan::columns::user_id.eq(user_id))
            .get_results(db)
            .map(|eqs: Vec<bool>| eqs.into_iter().all(|eq| eq))
    }
}

impl VerifyForUserOrAPWithDb for Unverified<MetconItem> {
    type Entity = MetconItem;

    fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Self::Entity, StatusCode> {
        let metcon_item = self.0;
        if MetconItemDb::check_user_id(metcon_item.id, *auth, db)
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(metcon_item)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

impl VerifyMultipleForUserOrAPWithDb for Unverified<Vec<MetconItem>> {
    type Entity = MetconItem;

    fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Vec<Self::Entity>, StatusCode> {
        let metcon_items = self.0;
        let metcon_item_ids: Vec<_> = metcon_items
            .iter()
            .map(|metcon_item| metcon_item.id)
            .collect();
        if MetconItemDb::check_user_ids(&metcon_item_ids, *auth, db)
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(metcon_items)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

impl VerifyForUserOrAPCreate for Unverified<MetconItem> {
    type Entity = MetconItem;

    fn verify_user_ap_create(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Self::Entity, StatusCode> {
        let metcon_item = self.0;
        if MetconDb::check_optional_user_id(metcon_item.metcon_id, *auth, db)
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(metcon_item)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

impl VerifyMultipleForUserOrAPCreate for Unverified<Vec<MetconItem>> {
    type Entity = MetconItem;

    fn verify_user_ap_create(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Vec<Self::Entity>, StatusCode> {
        let metcon_items = self.0;
        let mut metcon_ids: Vec<_> = metcon_items
            .iter()
            .map(|metcon_item| metcon_item.metcon_id)
            .collect();
        metcon_ids.sort_unstable();
        metcon_ids.dedup();
        if MetconDb::check_optional_user_ids(&metcon_ids, *auth, db)
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(metcon_items)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
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
    CheckUserId,
    VerifyForUserOrAPWithDb,
    VerifyForUserOrAPWithoutDb,
)]
pub struct MetconSessionDb;

pub struct MetconSessionDescriptionDb;

impl Db for MetconSessionDescriptionDb {
    type Id = MetconSessionId;
    type Entity = MetconSessionDescription;
}

impl GetById for MetconSessionDescriptionDb {
    fn get_by_id(
        metcon_session_id: Self::Id,
        db: &mut PgConnection,
    ) -> QueryResult<<Self as Db>::Entity> {
        let metcon_session = MetconSessionDb::get_by_id(metcon_session_id, db)?;
        MetconSessionDescriptionDb::from_session(metcon_session, db)
    }
}

impl GetByUser for MetconSessionDescriptionDb {
    fn get_by_user(
        user_id: UserId,
        db: &mut PgConnection,
    ) -> QueryResult<Vec<<Self as Db>::Entity>> {
        let metcon_sessions = MetconSessionDb::get_by_user(user_id, db)?;
        MetconSessionDescriptionDb::from_sessions(metcon_sessions, db)
    }
}

impl MetconSessionDescriptionDb {
    fn from_session(
        metcon_session: MetconSession,
        db: &mut PgConnection,
    ) -> QueryResult<<Self as Db>::Entity> {
        let metcon = MetconDb::get_by_id(metcon_session.metcon_id, db)?;
        let metcon_movements: Vec<MetconMovement> = MetconMovement::belonging_to(&metcon)
            .select(MetconMovement::as_select())
            .get_results(db)?;
        let mut movements = vec![];
        for metcon_movement in &metcon_movements {
            movements.push(MovementDb::get_by_id(metcon_movement.movement_id, db)?);
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
    ) -> QueryResult<Vec<<Self as Db>::Entity>> {
        let mut metcons = vec![];
        for metcon_session in &metcon_sessions {
            metcons.push(MetconDb::get_by_id(metcon_session.metcon_id, db)?);
        }
        let metcon_movements: Vec<Vec<MetconMovement>> = MetconMovement::belonging_to(&metcons)
            .select(MetconMovement::as_select())
            .get_results(db)?
            .grouped_by(&metcons);
        let mut movements = vec![];
        let mut movements_len;
        for metcon_movements in &metcon_movements {
            movements.push(vec![]);
            movements_len = movements.len();
            for metcon_session in metcon_movements {
                movements[movements_len - 1]
                    .push(MovementDb::get_by_id(metcon_session.movement_id, db)?);
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
}
