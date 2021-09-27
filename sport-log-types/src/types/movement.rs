use chrono::{DateTime, Utc};
#[cfg(feature = "server")]
use diesel_derive_enum::DbEnum;
#[cfg(feature = "server")]
use rocket::http::Status;
use serde::{Deserialize, Serialize};

#[cfg(feature = "server")]
use sport_log_types_derive::{
    CheckUserId, Create, CreateMultiple, FromSql, GetAll, GetById, GetByIds, HardDelete, ToSql,
    Update, VerifyForAdminWithoutDb, VerifyIdForAdmin, VerifyIdUnchecked,
};
use sport_log_types_derive::{FromI64, ToI64};

use crate::{from_str, from_str_optional, to_str, to_str_optional, UserId};
#[cfg(feature = "server")]
use crate::{
    schema::{eorm, movement, movement_muscle, muscle_group},
    AuthUserOrAP, CheckOptionalUserId, CheckUserId, GetById, Unverified, UnverifiedId,
    UnverifiedIds, User, VerifyForUserOrAPCreate, VerifyForUserOrAPWithDb,
    VerifyForUserOrAPWithoutDb, VerifyIdForUserOrAP, VerifyIdsForUserOrAP,
    VerifyMultipleForUserOrAPCreate, VerifyMultipleForUserOrAPWithDb,
    VerifyMultipleForUserOrAPWithoutDb,
};

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq)]
#[cfg_attr(feature = "server", derive(DbEnum))]
pub enum MovementUnit {
    Reps,
    Cal,
    Meter,
    Km,
    Yard,
    Foot,
    Mile,
    Msec,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq, FromI64, ToI64)]
#[cfg_attr(
    feature = "server",
    derive(
        Hash,
        FromSqlRow,
        AsExpression,
        ToSql,
        FromSql,
        VerifyIdForAdmin,
        VerifyIdUnchecked
    )
)]
#[cfg_attr(feature = "server", sql_type = "diesel::sql_types::BigInt")]
pub struct MovementId(pub i64);

#[cfg(feature = "server")]
impl VerifyIdForUserOrAP for UnverifiedId<MovementId> {
    type Id = MovementId;

    fn verify_user_ap(self, auth: &AuthUserOrAP, conn: &PgConnection) -> Result<Self::Id, Status> {
        if Movement::check_optional_user_id(self.0, **auth, conn).map_err(|_| Status::Forbidden)? {
            Ok(self.0)
        } else {
            Err(Status::Forbidden)
        }
    }
}

#[cfg(feature = "server")]
impl VerifyIdsForUserOrAP for UnverifiedIds<MovementId> {
    type Id = MovementId;

    fn verify_user_ap(
        self,
        auth: &AuthUserOrAP,
        conn: &PgConnection,
    ) -> Result<Vec<Self::Id>, Status> {
        if Movement::check_optional_user_ids(&self.0, **auth, conn)
            .map_err(|_| Status::Forbidden)?
        {
            Ok(self.0)
        } else {
            Err(Status::Forbidden)
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
        AsChangeset,
        Create,
        CreateMultiple,
        GetById,
        GetByIds,
        Update,
        HardDelete,
        CheckUserId,
        VerifyForAdminWithoutDb
    )
)]
#[cfg_attr(feature = "server", table_name = "movement")]
#[cfg_attr(feature = "server", belongs_to(User))]
pub struct Movement {
    #[serde(serialize_with = "to_str")]
    #[serde(deserialize_with = "from_str")]
    pub id: MovementId,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    #[serde(serialize_with = "to_str_optional")]
    #[serde(deserialize_with = "from_str_optional")]
    pub user_id: Option<UserId>,
    pub name: String,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub description: Option<String>,
    pub movement_unit: MovementUnit,
    pub cardio: bool,
    #[serde(skip)]
    #[serde(default = "Utc::now")]
    pub last_change: DateTime<Utc>,
    pub deleted: bool,
}

#[cfg(feature = "server")]
impl VerifyForUserOrAPWithDb for Unverified<Movement> {
    type Entity = Movement;

    fn verify_user_ap(
        self,
        auth: &AuthUserOrAP,
        conn: &PgConnection,
    ) -> Result<Self::Entity, Status> {
        let movement = self.0.into_inner();
        if movement.user_id == Some(**auth)
            && Movement::get_by_id(movement.id, conn)
                .map_err(|_| Status::InternalServerError)?
                .user_id
                == Some(**auth)
        {
            Ok(movement)
        } else {
            Err(Status::Forbidden)
        }
    }
}

#[cfg(feature = "server")]
impl VerifyMultipleForUserOrAPWithDb for Unverified<Vec<Movement>> {
    type Entity = Movement;

    fn verify_user_ap(
        self,
        auth: &AuthUserOrAP,
        conn: &PgConnection,
    ) -> Result<Vec<Self::Entity>, Status> {
        let movements = self.0.into_inner();
        let movement_ids: Vec<_> = movements.iter().map(|movement| movement.id).collect();
        if movements
            .iter()
            .all(|movement| movement.user_id == Some(**auth))
            && Movement::check_user_ids(&movement_ids, **auth, conn)
                .map_err(|_| Status::InternalServerError)?
        {
            Ok(movements)
        } else {
            Err(Status::Forbidden)
        }
    }
}

#[cfg(feature = "server")]
impl VerifyForUserOrAPWithoutDb for Unverified<Movement> {
    type Entity = Movement;

    fn verify_user_ap_without_db(self, auth: &AuthUserOrAP) -> Result<Self::Entity, Status> {
        let movement = self.0.into_inner();
        if movement.user_id == Some(**auth) {
            Ok(movement)
        } else {
            Err(Status::Forbidden)
        }
    }
}

#[cfg(feature = "server")]
impl VerifyMultipleForUserOrAPWithoutDb for Unverified<Vec<Movement>> {
    type Entity = Movement;

    fn verify_user_ap_without_db(self, auth: &AuthUserOrAP) -> Result<Vec<Self::Entity>, Status> {
        let movements = self.0.into_inner();
        if movements
            .iter()
            .all(|movement| movement.user_id == Some(**auth))
        {
            Ok(movements)
        } else {
            Err(Status::Forbidden)
        }
    }
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq, FromI64, ToI64)]
#[cfg_attr(
    feature = "server",
    derive(Hash, FromSqlRow, AsExpression, ToSql, FromSql, VerifyIdForAdmin)
)]
#[cfg_attr(feature = "server", sql_type = "diesel::sql_types::BigInt")]
pub struct MuscleGroupId(pub i64);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "server",
    derive(
        Insertable,
        Associations,
        Identifiable,
        Queryable,
        GetById,
        GetByIds,
        GetAll
    )
)]
#[cfg_attr(feature = "server", table_name = "muscle_group")]
pub struct MuscleGroup {
    #[serde(serialize_with = "to_str")]
    #[serde(deserialize_with = "from_str")]
    pub id: MuscleGroupId,
    pub name: String,
    pub description: Option<String>,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq, FromI64, ToI64)]
#[cfg_attr(
    feature = "server",
    derive(Hash, FromSqlRow, AsExpression, ToSql, FromSql)
)]
#[cfg_attr(feature = "server", sql_type = "diesel::sql_types::BigInt")]
pub struct MovementMuscleId(pub i64);

#[cfg(feature = "server")]
impl VerifyIdForUserOrAP for UnverifiedId<MovementMuscleId> {
    type Id = MovementMuscleId;

    fn verify_user_ap(self, auth: &AuthUserOrAP, conn: &PgConnection) -> Result<Self::Id, Status> {
        if MovementMuscle::check_optional_user_id(self.0, **auth, conn)
            .map_err(|_| Status::Forbidden)?
        {
            Ok(self.0)
        } else {
            Err(Status::Forbidden)
        }
    }
}

#[cfg(feature = "server")]
impl VerifyIdsForUserOrAP for UnverifiedIds<MovementMuscleId> {
    type Id = MovementMuscleId;

    fn verify_user_ap(
        self,
        auth: &AuthUserOrAP,
        conn: &PgConnection,
    ) -> Result<Vec<Self::Id>, Status> {
        if MovementMuscle::check_optional_user_ids(&self.0, **auth, conn)
            .map_err(|_| Status::Forbidden)?
        {
            Ok(self.0)
        } else {
            Err(Status::Forbidden)
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
        AsChangeset,
        Create,
        CreateMultiple,
        GetById,
        GetByIds,
        Update,
        HardDelete,
    )
)]
#[cfg_attr(feature = "server", table_name = "movement_muscle")]
#[cfg_attr(feature = "server", belongs_to(Movement))]
#[cfg_attr(feature = "server", belongs_to(MuscleGroup))]
pub struct MovementMuscle {
    #[serde(serialize_with = "to_str")]
    #[serde(deserialize_with = "from_str")]
    pub id: MovementMuscleId,
    #[serde(serialize_with = "to_str")]
    #[serde(deserialize_with = "from_str")]
    pub movement_id: MovementId,
    #[serde(serialize_with = "to_str")]
    #[serde(deserialize_with = "from_str")]
    pub muscle_group_id: MuscleGroupId,
    #[serde(skip)]
    #[serde(default = "Utc::now")]
    pub last_change: DateTime<Utc>,
    pub deleted: bool,
}

#[cfg(feature = "server")]
impl VerifyForUserOrAPWithDb for Unverified<MovementMuscle> {
    type Entity = MovementMuscle;

    fn verify_user_ap(
        self,
        auth: &AuthUserOrAP,
        conn: &PgConnection,
    ) -> Result<Self::Entity, Status> {
        let movement_muscle = self.0.into_inner();
        if MovementMuscle::check_user_id(movement_muscle.id, **auth, conn)
            .map_err(|_| Status::InternalServerError)?
            && Movement::check_user_id(movement_muscle.movement_id, **auth, conn)
                .map_err(|_| Status::InternalServerError)?
        {
            Ok(movement_muscle)
        } else {
            Err(Status::Forbidden)
        }
    }
}

#[cfg(feature = "server")]
impl VerifyMultipleForUserOrAPWithDb for Unverified<Vec<MovementMuscle>> {
    type Entity = MovementMuscle;

    fn verify_user_ap(
        self,
        auth: &AuthUserOrAP,
        conn: &PgConnection,
    ) -> Result<Vec<Self::Entity>, Status> {
        let movement_muscle = self.0.into_inner();
        let movement_muscle_ids: Vec<_> = movement_muscle
            .iter()
            .map(|metcon_movement| metcon_movement.id)
            .collect();
        let movement_ids: Vec<_> = movement_muscle
            .iter()
            .map(|metcon_movement| metcon_movement.movement_id)
            .collect();
        if MovementMuscle::check_user_ids(&movement_muscle_ids, **auth, conn)
            .map_err(|_| Status::InternalServerError)?
            && Movement::check_user_ids(&movement_ids, **auth, conn)
                .map_err(|_| Status::InternalServerError)?
        {
            Ok(movement_muscle)
        } else {
            Err(Status::Forbidden)
        }
    }
}

#[cfg(feature = "server")]
impl VerifyForUserOrAPCreate for Unverified<MovementMuscle> {
    type Entity = MovementMuscle;

    fn verify_user_ap_create(
        self,
        auth: &AuthUserOrAP,
        conn: &PgConnection,
    ) -> Result<Self::Entity, Status> {
        let movement_muscle = self.0.into_inner();
        if Movement::check_user_id(movement_muscle.movement_id, **auth, conn)
            .map_err(|_| Status::InternalServerError)?
        {
            Ok(movement_muscle)
        } else {
            Err(Status::Forbidden)
        }
    }
}

#[cfg(feature = "server")]
impl VerifyMultipleForUserOrAPCreate for Unverified<Vec<MovementMuscle>> {
    type Entity = MovementMuscle;

    fn verify_user_ap_create(
        self,
        auth: &AuthUserOrAP,
        conn: &PgConnection,
    ) -> Result<Vec<Self::Entity>, Status> {
        let movement_muscle = self.0.into_inner();
        let movement_ids: Vec<_> = movement_muscle
            .iter()
            .map(|metcon_movement| metcon_movement.movement_id)
            .collect();
        if Movement::check_user_ids(&movement_ids, **auth, conn)
            .map_err(|_| Status::InternalServerError)?
        {
            Ok(movement_muscle)
        } else {
            Err(Status::Forbidden)
        }
    }
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq, FromI64, ToI64)]
#[cfg_attr(
    feature = "server",
    derive(Hash, FromSqlRow, AsExpression, ToSql, FromSql, VerifyIdForAdmin)
)]
#[cfg_attr(feature = "server", sql_type = "diesel::sql_types::BigInt")]
pub struct EormId(pub i64);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "server",
    derive(
        Insertable,
        Associations,
        Identifiable,
        Queryable,
        GetById,
        GetByIds,
        GetAll
    )
)]
#[cfg_attr(feature = "server", table_name = "eorm")]
pub struct Eorm {
    #[serde(serialize_with = "to_str")]
    #[serde(deserialize_with = "from_str")]
    pub id: EormId,
    pub reps: i32,
    pub percentage: f32,
}
