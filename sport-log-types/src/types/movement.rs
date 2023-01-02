#[cfg(feature = "server")]
use axum::http::StatusCode;
#[cfg(feature = "server")]
use diesel::sql_types::BigInt;
#[cfg(feature = "server")]
use diesel_derive_enum::DbEnum;
use serde::{Deserialize, Serialize};
use sport_log_types_derive::IdString;
#[cfg(feature = "server")]
use sport_log_types_derive::{
    CheckUserId, Create, GetAll, GetById, GetByIds, HardDelete, IdFromSql, IdToSql, Update,
    VerifyForAdminWithoutDb, VerifyIdForAdmin, VerifyIdUnchecked,
};

#[cfg(feature = "server")]
use crate::{
    schema::{eorm, movement, movement_muscle, muscle_group},
    AuthUserOrAP, CheckOptionalUserId, CheckUserId, GetById, Unverified, UnverifiedId,
    UnverifiedIds, User, VerifyForUserOrAPCreate, VerifyForUserOrAPWithDb,
    VerifyForUserOrAPWithoutDb, VerifyIdForUserOrAP, VerifyIdsForUserOrAP,
    VerifyMultipleForUserOrAPCreate, VerifyMultipleForUserOrAPWithDb,
    VerifyMultipleForUserOrAPWithoutDb,
};
use crate::{types::IdString, UserId};

#[derive(Serialize, Deserialize, Debug, Clone, Copy, PartialEq, Eq)]
#[cfg_attr(feature = "server", derive(DbEnum))]
pub enum MovementDimension {
    Reps,
    Time,
    Energy,
    Distance,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, IdString)]
#[serde(try_from = "IdString", into = "IdString")]
#[cfg_attr(
    feature = "server",
    derive(
        Hash,
        FromSqlRow,
        AsExpression,
        IdToSql,
        IdFromSql,
        VerifyIdForAdmin,
        VerifyIdUnchecked
    ),
    diesel(sql_type = BigInt)
)]
pub struct MovementId(pub i64);

#[cfg(feature = "server")]
impl VerifyIdForUserOrAP for UnverifiedId<MovementId> {
    type Id = MovementId;

    fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Self::Id, StatusCode> {
        if Movement::check_optional_user_id(self.0, *auth, db).map_err(|_| StatusCode::FORBIDDEN)? {
            Ok(self.0)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

#[cfg(feature = "server")]
impl VerifyIdsForUserOrAP for UnverifiedIds<MovementId> {
    type Id = MovementId;

    fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Vec<Self::Id>, StatusCode> {
        if Movement::check_optional_user_ids(&self.0, *auth, db)
            .map_err(|_| StatusCode::FORBIDDEN)?
        {
            Ok(self.0)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

/// [Movement]
///
/// Movements can be predefined (`user_id` is [None]) or can be user-defined (`user_id` contains the id of the user).
///
/// `categories` decides whether the Movement can be used in Cardio or Strength Sessions or both. For Metcons the `categories` does not matter.
#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "server",
    derive(
        Insertable,
        Associations,
        Identifiable,
        Queryable,
        Selectable,
        AsChangeset,
        Create,
        GetById,
        GetByIds,
        Update,
        HardDelete,
        CheckUserId,
        VerifyForAdminWithoutDb
    ),
    diesel(table_name = movement, belongs_to(User))
)]
pub struct Movement {
    pub id: MovementId,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub user_id: Option<UserId>,
    pub name: String,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub description: Option<String>,
    pub movement_dimension: MovementDimension,
    pub cardio: bool,
    pub deleted: bool,
}

#[cfg(feature = "server")]
impl VerifyForUserOrAPWithDb for Unverified<Movement> {
    type Entity = Movement;

    fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Self::Entity, StatusCode> {
        let movement = self.0;
        if movement.user_id == Some(*auth)
            && Movement::get_by_id(movement.id, db)
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

#[cfg(feature = "server")]
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
            && Movement::check_user_ids(&movement_ids, *auth, db)
                .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(movements)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

#[cfg(feature = "server")]
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

#[cfg(feature = "server")]
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

#[derive(Serialize, Deserialize, Debug, Clone, Copy, PartialEq, Eq, IdString)]
#[serde(try_from = "IdString", into = "IdString")]
#[cfg_attr(
    feature = "server",
    derive(Hash, FromSqlRow, AsExpression, IdToSql, IdFromSql, VerifyIdForAdmin),
    diesel(sql_type = BigInt)
)]
pub struct MuscleGroupId(pub i64);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "server",
    derive(Insertable, Identifiable, Queryable, Selectable, GetById, GetByIds, GetAll),
    diesel(table_name = muscle_group)
)]
pub struct MuscleGroup {
    pub id: MuscleGroupId,
    pub name: String,
    pub description: Option<String>,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, PartialEq, Eq, IdString)]
#[serde(try_from = "IdString", into = "IdString")]
#[cfg_attr(
    feature = "server",
    derive(Hash, FromSqlRow, AsExpression, IdToSql, IdFromSql),
    diesel(sql_type = BigInt)
)]
pub struct MovementMuscleId(pub i64);

#[cfg(feature = "server")]
impl VerifyIdForUserOrAP for UnverifiedId<MovementMuscleId> {
    type Id = MovementMuscleId;

    fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Self::Id, StatusCode> {
        if MovementMuscle::check_optional_user_id(self.0, *auth, db)
            .map_err(|_| StatusCode::FORBIDDEN)?
        {
            Ok(self.0)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

#[cfg(feature = "server")]
impl VerifyIdsForUserOrAP for UnverifiedIds<MovementMuscleId> {
    type Id = MovementMuscleId;

    fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Vec<Self::Id>, StatusCode> {
        if MovementMuscle::check_optional_user_ids(&self.0, *auth, db)
            .map_err(|_| StatusCode::FORBIDDEN)?
        {
            Ok(self.0)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "server",
    derive(
        Insertable,
        Associations,
        Identifiable,
        Queryable,
        Selectable,
        AsChangeset,
        Create,
        GetById,
        GetByIds,
        Update,
        HardDelete,
    ),
    diesel(table_name = movement_muscle, belongs_to(Movement), belongs_to(MuscleGroup))
)]
pub struct MovementMuscle {
    pub id: MovementMuscleId,
    pub movement_id: MovementId,
    pub muscle_group_id: MuscleGroupId,
    pub deleted: bool,
}

#[cfg(feature = "server")]
impl VerifyForUserOrAPWithDb for Unverified<MovementMuscle> {
    type Entity = MovementMuscle;

    fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Self::Entity, StatusCode> {
        let movement_muscle = self.0;
        if MovementMuscle::check_user_id(movement_muscle.id, *auth, db)
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(movement_muscle)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

#[cfg(feature = "server")]
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
        if MovementMuscle::check_user_ids(&movement_muscle_ids, *auth, db)
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(movement_muscle)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

#[cfg(feature = "server")]
impl VerifyForUserOrAPCreate for Unverified<MovementMuscle> {
    type Entity = MovementMuscle;

    fn verify_user_ap_create(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Self::Entity, StatusCode> {
        let movement_muscle = self.0;
        if Movement::check_user_id(movement_muscle.movement_id, *auth, db)
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(movement_muscle)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

#[cfg(feature = "server")]
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
        if Movement::check_user_ids(&movement_ids, *auth, db)
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(movement_muscle)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, PartialEq, Eq, IdString)]
#[serde(try_from = "IdString", into = "IdString")]
#[cfg_attr(
    feature = "server",
    derive(Hash, FromSqlRow, AsExpression, IdToSql, IdFromSql, VerifyIdForAdmin),
    diesel(sql_type = BigInt)
)]
pub struct EormId(pub i64);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "server",
    derive(Insertable, Identifiable, Queryable, Selectable, GetById, GetByIds, GetAll),
    diesel(table_name = eorm)
)]
pub struct Eorm {
    pub id: EormId,
    pub reps: i32,
    pub percentage: f32,
}
