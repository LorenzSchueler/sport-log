use chrono::NaiveDateTime;
use rocket::http::Status;
use serde::{Deserialize, Serialize};

#[cfg(feature = "full")]
use sport_log_server_derive::{
    Create, Delete, FromI32, FromSql, GetAll, GetById, GetByUser, ToSql, Update,
    VerifyForUserWithDb, VerifyForUserWithoutDb, VerifyIdForUser,
};

#[cfg(feature = "full")]
use crate::schema::{strength_session, strength_set};
use crate::types::{MovementId, MovementUnit, UserId};

use super::{AuthenticatedUser, Unverified, UnverifiedId};

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
        VerifyIdForUser
    )
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::Integer")]
pub struct StrengthSessionId(pub i32);

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
        VerifyForUserWithDb
    )
)]
#[cfg_attr(feature = "full", table_name = "strength_session")]
pub struct StrengthSession {
    pub id: StrengthSessionId,
    pub user_id: UserId,
    pub datetime: NaiveDateTime,
    pub movement_id: MovementId,
    pub movement_unit: MovementUnit,
    pub interval: Option<i32>,
    pub comments: Option<String>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "full", derive(Insertable, VerifyForUserWithoutDb))]
#[cfg_attr(feature = "full", table_name = "strength_session")]
pub struct NewStrengthSession {
    pub user_id: UserId,
    pub datetime: NaiveDateTime,
    pub movement_id: MovementId,
    pub movement_unit: MovementUnit,
    pub interval: Option<i32>,
    pub comments: Option<String>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(FromSqlRow, AsExpression, Copy, PartialEq, Eq, FromI32, ToSql, FromSql)
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::Integer")]
pub struct StrengthSetId(pub i32);

#[cfg(feature = "full")]
impl UnverifiedId<StrengthSetId> {
    pub fn verify(
        self,
        auth: &AuthenticatedUser,
        conn: &PgConnection,
    ) -> Result<StrengthSetId, Status> {
        let strength_set =
            StrengthSet::get_by_id(self.0, conn).map_err(|_| Status::InternalServerError)?;
        if StrengthSession::get_by_id(strength_set.strength_session_id, conn)
            .map_err(|_| Status::InternalServerError)?
            .user_id
            == **auth
        {
            Ok(self.0)
        } else {
            Err(Status::Forbidden)
        }
    }
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(Queryable, AsChangeset, Create, GetById, GetAll, Update, Delete,)
)]
#[cfg_attr(feature = "full", table_name = "strength_set")]
pub struct StrengthSet {
    pub id: StrengthSetId,
    pub strength_session_id: StrengthSessionId,
    pub count: i32,
    pub weight: Option<f32>,
}

#[cfg(feature = "full")]
impl Unverified<StrengthSet> {
    pub fn verify(
        self,
        auth: &AuthenticatedUser,
        conn: &PgConnection,
    ) -> Result<StrengthSet, Status> {
        let strength_set = self.0.into_inner();
        if StrengthSession::get_by_id(strength_set.strength_session_id, conn)
            .map_err(|_| Status::InternalServerError)?
            .user_id
            == **auth
        {
            Ok(strength_set)
        } else {
            Err(Status::Forbidden)
        }
    }
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "full", derive(Insertable))]
#[cfg_attr(feature = "full", table_name = "strength_set")]
pub struct NewStrengthSet {
    pub strength_session_id: StrengthSessionId,
    pub count: i32,
    pub weight: Option<f32>,
}

#[cfg(feature = "full")]
impl Unverified<NewStrengthSet> {
    pub fn verify(
        self,
        auth: &AuthenticatedUser,
        conn: &PgConnection,
    ) -> Result<NewStrengthSet, Status> {
        let strength_set = self.0.into_inner();
        if StrengthSession::get_by_id(strength_set.strength_session_id, conn)
            .map_err(|_| Status::InternalServerError)?
            .user_id
            == **auth
        {
            Ok(strength_set)
        } else {
            Err(Status::Forbidden)
        }
    }
}
