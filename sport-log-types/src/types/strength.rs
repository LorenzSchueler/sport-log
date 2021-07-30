use chrono::NaiveDateTime;
#[cfg(feature = "full")]
use rocket::http::Status;
use serde::{Deserialize, Serialize};

#[cfg(feature = "full")]
use sport_log_types_derive::{
    Create, CreateMultiple, Delete, DeleteMultiple, FromI32, FromSql, GetAll, GetById, GetByIds,
    GetByUser, ToSql, Update, VerifyForUserWithDb, VerifyForUserWithoutDb, VerifyIdForUser,
};

#[cfg(feature = "full")]
use crate::{
    schema::{strength_session, strength_set},
    AuthenticatedUser, GetById, GetByIds, Unverified, UnverifiedId, UnverifiedIds,
    VerifyForUserWithDb, VerifyIdForUser, VerifyMultipleForUserWithDb, VerifyMultipleIdForUser,
};
use crate::{Movement, MovementId, MovementUnit, UserId};

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
pub struct StrengthSessionId(pub i32);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(
        Associations,
        Identifiable,
        Queryable,
        AsChangeset,
        Create,
        CreateMultiple,
        GetById,
        GetByIds,
        GetByUser,
        GetAll,
        Update,
        Delete,
        DeleteMultiple,
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
    #[cfg_attr(features = "full", changeset_options(treat_none_as_null = "true"))]
    pub interval: Option<i32>,
    #[cfg_attr(features = "full", changeset_options(treat_none_as_null = "true"))]
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

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq)]
#[cfg_attr(
    feature = "full",
    derive(Hash, FromSqlRow, AsExpression, FromI32, ToSql, FromSql)
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::Integer")]
pub struct StrengthSetId(pub i32);

#[cfg(feature = "full")]
impl VerifyIdForUser for UnverifiedId<StrengthSetId> {
    type Id = StrengthSetId;

    fn verify(self, auth: &AuthenticatedUser, conn: &PgConnection) -> Result<Self::Id, Status> {
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

#[cfg(feature = "full")]
impl VerifyMultipleIdForUser for UnverifiedIds<StrengthSetId> {
    type Id = StrengthSetId;

    fn verify(
        self,
        auth: &AuthenticatedUser,
        conn: &PgConnection,
    ) -> Result<Vec<Self::Id>, Status> {
        let strength_sets =
            StrengthSet::get_by_ids(&self.0, conn).map_err(|_| Status::InternalServerError)?;
        let strength_session_ids: Vec<_> = strength_sets
            .iter()
            .map(|strength_set| strength_set.strength_session_id)
            .collect();
        if StrengthSession::get_by_ids(strength_session_ids.as_slice(), conn)
            .map_err(|_| Status::InternalServerError)?
            .iter()
            .all(|strength_session| strength_session.user_id == **auth)
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
    derive(
        Associations,
        Identifiable,
        Queryable,
        AsChangeset,
        Create,
        CreateMultiple,
        GetById,
        GetByIds,
        GetAll,
        Update,
        Delete,
        DeleteMultiple,
    )
)]
#[cfg_attr(feature = "full", table_name = "strength_set")]
#[cfg_attr(feature = "full", belongs_to(StrengthSession))]
pub struct StrengthSet {
    pub id: StrengthSetId,
    pub strength_session_id: StrengthSessionId,
    pub set_number: i32,
    pub count: i32,
    #[cfg_attr(features = "full", changeset_options(treat_none_as_null = "true"))]
    pub weight: Option<f32>,
}

#[cfg(feature = "full")]
impl VerifyForUserWithDb for Unverified<StrengthSet> {
    type Entity = StrengthSet;

    fn verify(self, auth: &AuthenticatedUser, conn: &PgConnection) -> Result<Self::Entity, Status> {
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
    pub set_number: i32,
    pub count: i32,
    pub weight: Option<f32>,
}

#[cfg(feature = "full")]
impl VerifyForUserWithDb for Unverified<NewStrengthSet> {
    type Entity = NewStrengthSet;

    fn verify(self, auth: &AuthenticatedUser, conn: &PgConnection) -> Result<Self::Entity, Status> {
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

#[cfg(feature = "full")]
impl VerifyMultipleForUserWithDb for Unverified<Vec<NewStrengthSet>> {
    type Entity = NewStrengthSet;

    fn verify(
        self,
        auth: &AuthenticatedUser,
        conn: &PgConnection,
    ) -> Result<Vec<Self::Entity>, Status> {
        let strength_sets = self.0.into_inner();
        let strength_session_ids: Vec<_> = strength_sets
            .iter()
            .map(|strength_set| strength_set.strength_session_id)
            .collect();
        if StrengthSession::get_by_ids(strength_session_ids.as_slice(), conn)
            .map_err(|_| Status::InternalServerError)?
            .iter()
            .all(|strength_session| strength_session.user_id == **auth)
        {
            Ok(strength_sets)
        } else {
            Err(Status::Forbidden)
        }
    }
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct StrengthSessionDescription {
    pub strength_session: StrengthSession,
    pub strength_sets: Vec<StrengthSet>,
    pub movement: Movement,
}
