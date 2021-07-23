#[cfg(feature = "full")]
use diesel_derive_enum::DbEnum;
#[cfg(feature = "full")]
use rocket::http::Status;
use serde::{Deserialize, Serialize};

#[cfg(feature = "full")]
use sport_log_server_derive::{
    Create, Delete, FromI32, FromSql, GetAll, GetById, ToSql, Update, VerifyForAdminWithoutDb,
    VerifyIdForAdmin, VerifyIdForUserUnchecked,
};

use crate::types::UserId;
#[cfg(feature = "full")]
use crate::{
    schema::{eorm, movement},
    types::{AuthenticatedUser, Unverified, UnverifiedId},
};

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "full", derive(DbEnum))]
pub enum MovementCategory {
    Cardio,
    Strength,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
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

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(
        FromSqlRow,
        AsExpression,
        Copy,
        PartialEq,
        Eq,
        FromI32,
        ToSql,
        FromSql,
        VerifyIdForAdmin,
        VerifyIdForUserUnchecked
    )
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::Integer")]
pub struct MovementId(pub i32);

#[cfg(feature = "full")]
impl UnverifiedId<MovementId> {
    pub fn verify(
        self,
        auth: &AuthenticatedUser,
        conn: &PgConnection,
    ) -> Result<MovementId, Status> {
        let movement =
            Movement::get_by_id(self.0, conn).map_err(|_| rocket::http::Status::Forbidden)?;
        if movement.user_id == Some(**auth) {
            Ok(self.0)
        } else {
            Err(rocket::http::Status::Forbidden)
        }
    }

    pub fn verify_if_owned(
        self,
        auth: &AuthenticatedUser,
        conn: &PgConnection,
    ) -> Result<MovementId, Status> {
        let movement =
            Movement::get_by_id(self.0, conn).map_err(|_| rocket::http::Status::Forbidden)?;
        if movement.user_id.is_none() || movement.user_id == Some(**auth) {
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
        GetAll,
        Update,
        Delete,
        VerifyForAdminWithoutDb
    )
)]
#[cfg_attr(feature = "full", table_name = "movement")]
pub struct Movement {
    pub id: MovementId,
    pub user_id: Option<UserId>,
    pub name: String,
    pub description: Option<String>,
    pub category: MovementCategory,
}

#[cfg(feature = "full")]
impl Movement {
    pub fn get_by_user(user_id: UserId, conn: &PgConnection) -> QueryResult<Vec<Movement>> {
        movement::table
            .filter(
                movement::columns::user_id
                    .eq(user_id)
                    .or(movement::columns::user_id.eq(Option::<UserId>::None)),
            )
            .get_results(conn)
    }
}

#[cfg(feature = "full")]
impl Unverified<Movement> {
    pub fn verify(self, auth: &AuthenticatedUser, conn: &PgConnection) -> Result<Movement, Status> {
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

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "full", derive(Insertable))]
#[cfg_attr(feature = "full", table_name = "movement")]
pub struct NewMovement {
    pub user_id: Option<UserId>,
    pub name: String,
    pub description: Option<String>,
    pub category: MovementCategory,
}

#[cfg(feature = "full")]
impl Unverified<NewMovement> {
    pub fn verify(self, auth: &AuthenticatedUser) -> Result<NewMovement, Status> {
        let movement = self.0.into_inner();
        if movement.user_id == Some(**auth) {
            Ok(movement)
        } else {
            Err(Status::Forbidden)
        }
    }
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(
        FromSqlRow,
        AsExpression,
        Copy,
        PartialEq,
        Eq,
        FromI32,
        ToSql,
        FromSql,
        VerifyIdForAdmin
    )
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::Integer")]
pub struct EormId(pub i32);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(Queryable, AsChangeset, Create, GetById, GetAll, Update, Delete,)
)]
#[cfg_attr(feature = "full", table_name = "eorm")]
pub struct Eorm {
    pub id: EormId,
    pub reps: i32,
    pub percentage: f32,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "full", derive(Insertable))]
#[cfg_attr(feature = "full", table_name = "eorm")]
pub struct NewEorm {
    pub reps: i32,
    pub percentage: f32,
}
