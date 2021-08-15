use chrono::{DateTime, Utc};
#[cfg(feature = "full")]
use diesel_derive_enum::DbEnum;
#[cfg(feature = "full")]
use rocket::http::Status;
use serde::{Deserialize, Serialize};

#[cfg(feature = "full")]
use sport_log_types_derive::{
    CheckUserId, Create, CreateMultiple, FromI64, FromSql, GetAll, GetById, GetByIds, ToSql,
    Update, VerifyForAdminWithoutDb, VerifyIdForAdmin, VerifyIdUnchecked,
};

#[cfg(feature = "full")]
use crate::{
    schema::{eorm, movement},
    AuthUserOrAP, GetById, Unverified, UnverifiedId, User, VerifyForUserOrAPWithDb,
    VerifyForUserOrAPWithoutDb, VerifyIdForUserOrAP, VerifyMultipleForUserOrAPWithoutDb,
};
use crate::{
    CheckUserId, UnverifiedIds, UserId, VerifyIdsForUserOrAP, VerifyMultipleForUserOrAPWithDb,
};

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq)]
#[cfg_attr(feature = "full", derive(DbEnum))]
pub enum MovementCategory {
    Cardio,
    Strength,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq)]
#[cfg_attr(feature = "full", derive(DbEnum))]
pub enum MovementUnit {
    Reps,
    Cal,
    Meter,
    Km,
    Yard,
    Foot,
    Mile,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq)]
#[cfg_attr(
    feature = "full",
    derive(
        Hash,
        FromSqlRow,
        AsExpression,
        FromI64,
        ToSql,
        FromSql,
        VerifyIdForAdmin,
        VerifyIdUnchecked
    )
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::BigInt")]
pub struct MovementId(pub i64);

impl VerifyIdForUserOrAP for UnverifiedId<MovementId> {
    type Id = MovementId;

    fn verify_user_ap(self, auth: &AuthUserOrAP, conn: &PgConnection) -> Result<Self::Id, Status> {
        if Movement::check_user_id_null(self.0, **auth, conn)
            .map_err(|_| rocket::http::Status::Forbidden)?
        {
            Ok(self.0)
        } else {
            Err(rocket::http::Status::Forbidden)
        }
    }
}

#[cfg(feature = "full")]
impl VerifyIdsForUserOrAP for UnverifiedIds<MovementId> {
    type Id = MovementId;

    fn verify_user_ap(
        self,
        auth: &AuthUserOrAP,
        conn: &PgConnection,
    ) -> Result<Vec<Self::Id>, Status> {
        if Movement::check_user_ids_null(&self.0, **auth, conn)
            .map_err(|_| rocket::http::Status::Forbidden)?
        {
            Ok(self.0)
        } else {
            Err(rocket::http::Status::Forbidden)
        }
    }
}

/// [Movement]
///
/// Movements can be predefined (`user_id` is [None]) or can be user-defined (`user_id` contains the id of the user).
///
/// `category` decides whether the Movement can be used in Cardio or Strength Sessions. For Metcons the category does not matter.
#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
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
        CheckUserId,
        VerifyForAdminWithoutDb
    )
)]
#[cfg_attr(feature = "full", table_name = "movement")]
#[cfg_attr(feature = "full", belongs_to(User))]
pub struct Movement {
    pub id: MovementId,
    #[cfg_attr(features = "full", changeset_options(treat_none_as_null = "true"))]
    pub user_id: Option<UserId>,
    pub name: String,
    #[cfg_attr(features = "full", changeset_options(treat_none_as_null = "true"))]
    pub description: Option<String>,
    pub category: MovementCategory,
    #[serde(skip)]
    #[serde(default = "Utc::now")]
    pub last_change: DateTime<Utc>,
    pub deleted: bool,
}

#[cfg(feature = "full")]
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

#[cfg(feature = "full")]
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

#[cfg(feature = "full")]
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

#[cfg(feature = "full")]
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

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq)]
#[cfg_attr(
    feature = "full",
    derive(
        Hash,
        FromSqlRow,
        AsExpression,
        FromI64,
        ToSql,
        FromSql,
        VerifyIdForAdmin
    )
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::BigInt")]
pub struct EormId(pub i64);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
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
#[cfg_attr(feature = "full", table_name = "eorm")]
pub struct Eorm {
    pub id: EormId,
    pub reps: i32,
    pub percentage: f32,
}
