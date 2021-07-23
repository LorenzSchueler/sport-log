use chrono::NaiveDateTime;
#[cfg(feature = "full")]
use diesel_derive_enum::DbEnum;
use rocket::http::Status;
use serde::{Deserialize, Serialize};

#[cfg(feature = "full")]
use sport_log_server_derive::{
    Create, Delete, FromI32, FromSql, GetAll, GetById, GetByUser, ToSql, Update,
};

#[cfg(feature = "full")]
use crate::schema::{metcon, metcon_movement, metcon_session};
use crate::types::{MovementId, MovementUnit, UserId};

use super::{AuthenticatedUser, Unverified, UnverifiedId};

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "full", derive(DbEnum))]
pub enum MetconType {
    Amrap,
    Emom,
    ForTime,
    Ladder,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(FromSqlRow, AsExpression, Copy, PartialEq, Eq, FromI32, ToSql, FromSql)
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

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(
        Queryable,
        AsChangeset,
        Create,
        GetById,
        GetByUser,
        GetAll,
        Update,
        Delete,
    )
)]
#[cfg_attr(feature = "full", table_name = "metcon")]
pub struct Metcon {
    pub id: MetconId,
    pub user_id: Option<UserId>,
    pub name: Option<String>,
    pub metcon_type: MetconType,
    pub rounds: Option<i32>,
    pub timecap: Option<i32>,
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

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "full", derive(Insertable))]
#[cfg_attr(feature = "full", table_name = "metcon")]
pub struct NewMetcon {
    pub user_id: Option<UserId>,
    pub name: Option<String>,
    pub metcon_type: MetconType,
    pub rounds: Option<i32>,
    pub timecap: Option<i32>,
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

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(FromSqlRow, AsExpression, Copy, PartialEq, Eq, FromI32, ToSql, FromSql)
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
    derive(Queryable, AsChangeset, Create, GetById, GetAll, Update, Delete,)
)]
#[cfg_attr(feature = "full", table_name = "metcon_movement")]
pub struct MetconMovement {
    pub id: MetconMovementId,
    pub movement_id: MovementId,
    pub metcon_id: MetconId,
    pub count: i32,
    pub unit: MovementUnit,
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
    pub unit: MovementUnit,
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

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(FromSqlRow, AsExpression, Copy, PartialEq, Eq, FromI32, ToSql, FromSql)
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::Integer")]
pub struct MetconSessionId(pub i32);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(
        Queryable,
        AsChangeset,
        Create,
        GetById,
        GetByUser,
        GetAll,
        Update,
        Delete,
    )
)]
#[cfg_attr(feature = "full", table_name = "metcon_session")]
pub struct MetconSession {
    pub id: MetconSessionId,
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
#[cfg_attr(feature = "full", derive(Insertable))]
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
