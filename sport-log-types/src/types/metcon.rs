use chrono::NaiveDateTime;
#[cfg(feature = "full")]
use diesel_derive_enum::DbEnum;
#[cfg(feature = "full")]
use rocket::http::Status;
use serde::{Deserialize, Serialize};

#[cfg(feature = "full")]
use sport_log_types_derive::{
    Create, Delete, FromI32, FromSql, GetAll, GetById, GetByUser, ToSql, Update,
    VerifyForUserWithDb, VerifyForUserWithoutDb, VerifyIdForUser,
};

use crate::types::{Movement, MovementId, MovementUnit, UserId};
#[cfg(feature = "full")]
use crate::{
    schema::{metcon, metcon_movement, metcon_session},
    types::{AuthenticatedUser, GetById, Unverified, UnverifiedId, User},
};

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq)]
#[cfg_attr(feature = "full", derive(DbEnum))]
pub enum MetconType {
    Amrap,
    Emom,
    ForTime,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq)]
#[cfg_attr(
    feature = "full",
    derive(Hash, FromSqlRow, AsExpression, FromI32, ToSql, FromSql)
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::Integer")]
pub struct MetconId(pub i32);

#[cfg(feature = "full")]
impl UnverifiedId<MetconId> {
    pub fn verify(self, auth: &AuthenticatedUser, conn: &PgConnection) -> Result<MetconId, Status> {
        let metcon =
            Metcon::get_by_id(self.0, conn).map_err(|_| rocket::http::Status::Forbidden)?;
        if metcon.user_id == Some(**auth) {
            Ok(self.0)
        } else {
            Err(rocket::http::Status::Forbidden)
        }
    }

    pub fn verify_if_owned(
        self,
        auth: &AuthenticatedUser,
        conn: &PgConnection,
    ) -> Result<MetconId, Status> {
        let metcon =
            Metcon::get_by_id(self.0, conn).map_err(|_| rocket::http::Status::Forbidden)?;
        if metcon.user_id.is_none() || metcon.user_id == Some(**auth) {
            Ok(self.0)
        } else {
            Err(rocket::http::Status::Forbidden)
        }
    }
}

/// [Metcon] acts like a template for a [MetconSession].
///
/// Metcons can be predefined (`user_id` is [None]) or can be user-defined (`user_id` contains the id of the user).
///
/// If `metcon_type` is [MetconType::Amrap] `rounds` should be `None` and `timecap` should be set.
///
/// If `metcon_type` is [MetconType::Emom] rounds and timecap should be set (rounds determines how many rounds should be performed and `timecap`/`rounds` determines how long each round takes).
///
/// If `metcon_type` is [MetconType::ForTime] `rounds` should be set and `timecap` can be None or have a value.
#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(
        Associations,
        Identifiable,
        Queryable,
        AsChangeset,
        Create,
        GetById,
        GetAll,
        Update,
        Delete,
    )
)]
#[cfg_attr(feature = "full", table_name = "metcon")]
#[cfg_attr(feature = "full", belongs_to(User))]
pub struct Metcon {
    pub id: MetconId,
    #[cfg_attr(features = "full", changeset_options(treat_none_as_null = "true"))]
    pub user_id: Option<UserId>,
    #[cfg_attr(features = "full", changeset_options(treat_none_as_null = "true"))]
    pub name: Option<String>,
    pub metcon_type: MetconType,
    #[cfg_attr(features = "full", changeset_options(treat_none_as_null = "true"))]
    pub rounds: Option<i32>,
    #[cfg_attr(features = "full", changeset_options(treat_none_as_null = "true"))]
    pub timecap: Option<i32>,
    #[cfg_attr(features = "full", changeset_options(treat_none_as_null = "true"))]
    pub description: Option<String>,
}

#[cfg(feature = "full")]
impl Unverified<Metcon> {
    pub fn verify(self, auth: &AuthenticatedUser, conn: &PgConnection) -> Result<Metcon, Status> {
        let metcon = self.0.into_inner();
        if metcon.user_id == Some(**auth)
            && Metcon::get_by_id(metcon.id, conn)
                .map_err(|_| Status::InternalServerError)?
                .user_id
                == Some(**auth)
        {
            Ok(metcon)
        } else {
            Err(Status::Forbidden)
        }
    }
}

/// Please refer to [Metcon].
#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "full", derive(Insertable))]
#[cfg_attr(feature = "full", table_name = "metcon")]
pub struct NewMetcon {
    pub user_id: Option<UserId>,
    pub name: Option<String>,
    pub metcon_type: MetconType,
    pub rounds: Option<i32>,
    pub timecap: Option<i32>,
    pub description: Option<String>,
}

#[cfg(feature = "full")]
impl Unverified<NewMetcon> {
    pub fn verify(self, auth: &AuthenticatedUser) -> Result<NewMetcon, Status> {
        let metcon = self.0.into_inner();
        if metcon.user_id == Some(**auth) {
            Ok(metcon)
        } else {
            Err(Status::Forbidden)
        }
    }
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq)]
#[cfg_attr(
    feature = "full",
    derive(Hash, FromSqlRow, AsExpression, FromI32, ToSql, FromSql)
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::Integer")]
pub struct MetconMovementId(pub i32);

#[cfg(feature = "full")]
impl UnverifiedId<MetconMovementId> {
    pub fn verify(
        self,
        auth: &AuthenticatedUser,
        conn: &PgConnection,
    ) -> Result<MetconMovementId, Status> {
        let metcon_movement =
            MetconMovement::get_by_id(self.0, conn).map_err(|_| rocket::http::Status::Forbidden)?;
        let metcon = Metcon::get_by_id(metcon_movement.metcon_id, conn)
            .map_err(|_| rocket::http::Status::Forbidden)?;
        if metcon.user_id == Some(**auth) {
            Ok(self.0)
        } else {
            Err(rocket::http::Status::Forbidden)
        }
    }

    pub fn verify_if_owned(
        self,
        auth: &AuthenticatedUser,
        conn: &PgConnection,
    ) -> Result<MetconMovementId, Status> {
        let metcon_movement =
            MetconMovement::get_by_id(self.0, conn).map_err(|_| rocket::http::Status::Forbidden)?;
        let metcon = Metcon::get_by_id(metcon_movement.metcon_id, conn)
            .map_err(|_| rocket::http::Status::Forbidden)?;
        if metcon.user_id.is_none() || metcon.user_id == Some(**auth) {
            Ok(self.0)
        } else {
            Err(rocket::http::Status::Forbidden)
        }
    }
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(
        Associations,
        Identifiable,
        Queryable,
        AsChangeset,
        Create,
        GetById,
        GetAll,
        Update,
        Delete,
    )
)]
#[cfg_attr(feature = "full", table_name = "metcon_movement")]
#[cfg_attr(feature = "full", belongs_to(Movement))]
#[cfg_attr(feature = "full", belongs_to(Metcon))]
pub struct MetconMovement {
    pub id: MetconMovementId,
    pub movement_id: MovementId,
    pub metcon_id: MetconId,
    pub count: i32,
    pub movement_unit: MovementUnit,
    #[cfg_attr(features = "full", changeset_options(treat_none_as_null = "true"))]
    pub weight: Option<f32>,
}

#[cfg(feature = "full")]
impl Unverified<MetconMovement> {
    pub fn verify(
        self,
        auth: &AuthenticatedUser,
        conn: &PgConnection,
    ) -> Result<MetconMovement, Status> {
        let metcon_movement = self.0.into_inner();
        let metcon = Metcon::get_by_id(metcon_movement.metcon_id, conn)
            .map_err(|_| rocket::http::Status::Forbidden)?;
        if metcon.user_id == Some(**auth) {
            Ok(metcon_movement)
        } else {
            Err(rocket::http::Status::Forbidden)
        }
    }
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "full", derive(Insertable))]
#[cfg_attr(feature = "full", table_name = "metcon_movement")]
pub struct NewMetconMovement {
    pub movement_id: MovementId,
    pub metcon_id: MetconId,
    pub count: i32,
    pub movement_unit: MovementUnit,
    pub weight: Option<f32>,
}

#[cfg(feature = "full")]
impl Unverified<NewMetconMovement> {
    pub fn verify(
        self,
        auth: &AuthenticatedUser,
        conn: &PgConnection,
    ) -> Result<NewMetconMovement, Status> {
        let metcon_movement = self.0.into_inner();
        let metcon = Metcon::get_by_id(metcon_movement.metcon_id, conn)
            .map_err(|_| rocket::http::Status::Forbidden)?;
        if metcon.user_id == Some(**auth) {
            Ok(metcon_movement)
        } else {
            Err(rocket::http::Status::Forbidden)
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
        FromI32,
        ToSql,
        FromSql,
        VerifyIdForUser
    )
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::Integer")]
pub struct MetconSessionId(pub i32);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(
        Associations,
        Identifiable,
        Queryable,
        AsChangeset,
        Create,
        GetById,
        GetByUser,
        GetAll,
        Update,
        Delete,
        VerifyForUserWithDb
    )
)]
#[cfg_attr(feature = "full", table_name = "metcon_session")]
#[cfg_attr(feature = "full", belongs_to(User))]
#[cfg_attr(feature = "full", belongs_to(Metcon))]
pub struct MetconSession {
    pub id: MetconSessionId,
    pub user_id: UserId,
    pub metcon_id: MetconId,
    pub datetime: NaiveDateTime,
    #[cfg_attr(features = "full", changeset_options(treat_none_as_null = "true"))]
    pub time: Option<i32>,
    #[cfg_attr(features = "full", changeset_options(treat_none_as_null = "true"))]
    pub rounds: Option<i32>,
    #[cfg_attr(features = "full", changeset_options(treat_none_as_null = "true"))]
    pub reps: Option<i32>,
    pub rx: bool,
    #[cfg_attr(features = "full", changeset_options(treat_none_as_null = "true"))]
    pub comments: Option<String>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "full", derive(Insertable, VerifyForUserWithoutDb))]
#[cfg_attr(feature = "full", table_name = "metcon_session")]
pub struct NewMetconSession {
    pub user_id: UserId,
    pub metcon_id: MetconId,
    pub datetime: NaiveDateTime,
    pub time: Option<i32>,
    pub rounds: Option<i32>,
    pub reps: Option<i32>,
    pub rx: bool,
    pub comments: Option<String>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct MetconSessionDescription {
    pub metcon_session: MetconSession,
    pub metcon: Metcon,
    pub movements: Vec<(MetconMovement, Movement)>,
}
