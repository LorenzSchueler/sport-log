use axum::http::StatusCode;
use chrono::{DateTime, Utc};
use diesel::{prelude::*, QueryResult};
use diesel_async::{AsyncPgConnection, RunQueryDsl};
use sport_log_types::{
    schema::{strength_blueprint, strength_blueprint_set, strength_session, strength_set},
    StrengthBlueprintSet, StrengthSessionId, StrengthSet, UserId,
};
use sport_log_types_derive::*;

use crate::{auth::*, db::*};

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
pub struct StrengthBlueprintDb;

#[derive(Db, ModifiableDb, VerifyIdForUserOrAP, Create, GetById, GetByIds, Update, HardDelete)]
pub struct StrengthBlueprintSetDb;

#[async_trait]
impl GetByUser for StrengthBlueprintSetDb {
    async fn get_by_user(
        user_id: UserId,
        db: &mut AsyncPgConnection,
    ) -> QueryResult<Vec<<Self as Db>::Type>> {
        strength_blueprint_set::table
            .filter(
                strength_blueprint_set::columns::strength_blueprint_id.eq_any(
                    strength_blueprint::table
                        .filter(strength_blueprint::columns::user_id.eq(user_id))
                        .select(strength_blueprint::columns::id),
                ),
            )
            .select(StrengthBlueprintSet::as_select())
            .get_results(db)
            .await
    }
}

#[async_trait]
impl GetByUserSync for StrengthBlueprintSetDb {
    async fn get_by_user_and_last_sync(
        user_id: UserId,
        last_sync: DateTime<Utc>,
        db: &mut AsyncPgConnection,
    ) -> QueryResult<Vec<Self::Type>>
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
            .select(StrengthBlueprintSet::as_select())
            .get_results(db)
            .await
    }
}

#[async_trait]
impl CheckUserId for StrengthBlueprintSetDb {
    async fn check_user_id(
        id: Self::Id,
        user_id: UserId,
        db: &mut AsyncPgConnection,
    ) -> QueryResult<bool> {
        strength_blueprint_set::table
            .inner_join(strength_blueprint::table)
            .filter(strength_blueprint_set::columns::id.eq(id))
            .select(strength_blueprint::columns::user_id.eq(user_id))
            .get_result(db)
            .await
            .optional()
            .map(|eq| eq.unwrap_or(false))
    }

    async fn check_user_ids(
        ids: &[Self::Id],
        user_id: UserId,
        db: &mut AsyncPgConnection,
    ) -> QueryResult<bool> {
        strength_blueprint_set::table
            .inner_join(strength_blueprint::table)
            .filter(strength_blueprint_set::columns::id.eq_any(ids))
            .select(strength_blueprint::columns::user_id.eq(user_id))
            .get_results(db)
            .await
            .map(|eqs: Vec<bool>| eqs.into_iter().all(|eq| eq))
    }
}

#[async_trait]
impl VerifyForUserOrAPWithDb for Unverified<StrengthBlueprintSet> {
    type Type = StrengthBlueprintSet;

    async fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut AsyncPgConnection,
    ) -> Result<Self::Type, StatusCode> {
        let strength_blueprint_set = self.0;
        if StrengthBlueprintSetDb::check_user_id(strength_blueprint_set.id, *auth, db)
            .await
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(strength_blueprint_set)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

#[async_trait]
impl VerifyMultipleForUserOrAPWithDb for Unverified<Vec<StrengthBlueprintSet>> {
    type Type = StrengthBlueprintSet;

    async fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut AsyncPgConnection,
    ) -> Result<Vec<Self::Type>, StatusCode> {
        let strength_blueprint_sets = self.0;
        let strength_blueprint_set_ids: Vec<_> = strength_blueprint_sets
            .iter()
            .map(|strength_set| strength_set.id)
            .collect();
        if StrengthBlueprintSetDb::check_user_ids(&strength_blueprint_set_ids, *auth, db)
            .await
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(strength_blueprint_sets)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

#[async_trait]
impl VerifyForUserOrAPCreate for Unverified<StrengthBlueprintSet> {
    type Type = StrengthBlueprintSet;

    async fn verify_user_ap_create(
        self,
        auth: AuthUserOrAP,
        db: &mut AsyncPgConnection,
    ) -> Result<Self::Type, StatusCode> {
        let strength_blueprint_set = self.0;
        if StrengthBlueprintDb::check_user_id(
            strength_blueprint_set.strength_blueprint_id,
            *auth,
            db,
        )
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(strength_blueprint_set)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

#[async_trait]
impl VerifyMultipleForUserOrAPCreate for Unverified<Vec<StrengthBlueprintSet>> {
    type Type = StrengthBlueprintSet;

    async fn verify_user_ap_create(
        self,
        auth: AuthUserOrAP,
        db: &mut AsyncPgConnection,
    ) -> Result<Vec<Self::Type>, StatusCode> {
        let strength_blueprint_sets = self.0;
        let mut strength_blueprint_ids: Vec<_> = strength_blueprint_sets
            .iter()
            .map(|strength_set| strength_set.strength_blueprint_id)
            .collect();
        strength_blueprint_ids.sort_unstable();
        strength_blueprint_ids.dedup();
        if StrengthBlueprintDb::check_user_ids(&strength_blueprint_ids, *auth, db)
            .await
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(strength_blueprint_sets)
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
pub struct StrengthSessionDb;

#[derive(Db, ModifiableDb, VerifyIdForUserOrAP, Create, GetById, GetByIds, Update, HardDelete)]
pub struct StrengthSetDb;

#[async_trait]
impl GetByUser for StrengthSetDb {
    async fn get_by_user(
        user_id: UserId,
        db: &mut AsyncPgConnection,
    ) -> QueryResult<Vec<<Self as Db>::Type>> {
        strength_set::table
            .filter(
                strength_set::columns::strength_session_id.eq_any(
                    strength_session::table
                        .filter(strength_session::columns::user_id.eq(user_id))
                        .select(strength_session::columns::id),
                ),
            )
            .select(StrengthSet::as_select())
            .get_results(db)
            .await
    }
}

#[async_trait]
impl GetByUserSync for StrengthSetDb {
    async fn get_by_user_and_last_sync(
        user_id: UserId,
        last_sync: DateTime<Utc>,
        db: &mut AsyncPgConnection,
    ) -> QueryResult<Vec<<Self as Db>::Type>>
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
            .select(StrengthSet::as_select())
            .get_results(db)
            .await
    }
}

#[async_trait]
impl CheckUserId for StrengthSetDb {
    async fn check_user_id(
        id: Self::Id,
        user_id: UserId,
        db: &mut AsyncPgConnection,
    ) -> QueryResult<bool> {
        strength_set::table
            .inner_join(strength_session::table)
            .filter(strength_set::columns::id.eq(id))
            .select(strength_session::columns::user_id.eq(user_id))
            .get_result(db)
            .await
            .optional()
            .map(|eq| eq.unwrap_or(false))
    }

    async fn check_user_ids(
        ids: &[Self::Id],
        user_id: UserId,
        db: &mut AsyncPgConnection,
    ) -> QueryResult<bool> {
        strength_set::table
            .inner_join(strength_session::table)
            .filter(strength_set::columns::id.eq_any(ids))
            .select(strength_session::columns::user_id.eq(user_id))
            .get_results(db)
            .await
            .map(|eqs: Vec<bool>| eqs.into_iter().all(|eq| eq))
    }
}

#[async_trait]
impl VerifyForUserOrAPWithDb for Unverified<StrengthSet> {
    type Type = StrengthSet;

    async fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut AsyncPgConnection,
    ) -> Result<Self::Type, StatusCode> {
        let strength_set = self.0;
        if StrengthSetDb::check_user_id(strength_set.id, *auth, db)
            .await
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(strength_set)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

#[async_trait]
impl VerifyMultipleForUserOrAPWithDb for Unverified<Vec<StrengthSet>> {
    type Type = StrengthSet;

    async fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut AsyncPgConnection,
    ) -> Result<Vec<Self::Type>, StatusCode> {
        let strength_sets = self.0;
        let strength_set_ids: Vec<_> = strength_sets
            .iter()
            .map(|strength_set| strength_set.id)
            .collect();
        if StrengthSetDb::check_user_ids(&strength_set_ids, *auth, db)
            .await
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(strength_sets)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

#[async_trait]
impl VerifyForUserOrAPCreate for Unverified<StrengthSet> {
    type Type = StrengthSet;

    async fn verify_user_ap_create(
        self,
        auth: AuthUserOrAP,
        db: &mut AsyncPgConnection,
    ) -> Result<Self::Type, StatusCode> {
        let strength_set = self.0;
        if StrengthSessionDb::check_user_id(strength_set.strength_session_id, *auth, db)
            .await
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(strength_set)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

#[async_trait]
impl VerifyMultipleForUserOrAPCreate for Unverified<Vec<StrengthSet>> {
    type Type = StrengthSet;

    async fn verify_user_ap_create(
        self,
        auth: AuthUserOrAP,
        db: &mut AsyncPgConnection,
    ) -> Result<Vec<Self::Type>, StatusCode> {
        let strength_sets = self.0;
        let mut strength_session_ids: Vec<StrengthSessionId> = strength_sets
            .iter()
            .map(|strength_set| strength_set.strength_session_id)
            .collect();
        strength_session_ids.sort_unstable();
        strength_session_ids.dedup();
        if StrengthSessionDb::check_user_ids(&strength_session_ids, *auth, db)
            .await
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(strength_sets)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

#[derive(Db, VerifyIdForAdmin, GetById, GetByIds, GetAll)]
pub struct EormDb;
