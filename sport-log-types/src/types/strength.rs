use chrono::{DateTime, Utc};
#[cfg(feature = "full")]
use rocket::http::Status;
use serde::{Deserialize, Serialize};

#[cfg(feature = "full")]
use sport_log_types_derive::{
    CheckUserId, Create, CreateMultiple, FromI64, FromSql, GetById, GetByIds, GetByUser,
    GetByUserSync, ToSql, Update, VerifyForUserOrAPWithDb, VerifyForUserOrAPWithoutDb,
    VerifyIdForUserOrAP,
};

#[cfg(feature = "full")]
use crate::{
    schema::{strength_session, strength_set},
    AuthUserOrAP, CheckUserId, Unverified, VerifyForUserOrAPWithDb,
    VerifyMultipleForUserOrAPWithDb,
};
use crate::{Movement, MovementId, MovementUnit, UserId};

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
        VerifyIdForUserOrAP
    )
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::BigInt")]
pub struct StrengthSessionId(pub i64);

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
        GetByUser,
        GetByUserSync,
        Update,
        CheckUserId,
        VerifyForUserOrAPWithDb,
        VerifyForUserOrAPWithoutDb
    )
)]
#[cfg_attr(feature = "full", table_name = "strength_session")]
pub struct StrengthSession {
    pub id: StrengthSessionId,
    pub user_id: UserId,
    pub datetime: DateTime<Utc>,
    pub movement_id: MovementId,
    pub movement_unit: MovementUnit,
    #[cfg_attr(features = "full", changeset_options(treat_none_as_null = "true"))]
    pub interval: Option<i32>,
    #[cfg_attr(features = "full", changeset_options(treat_none_as_null = "true"))]
    pub comments: Option<String>,
    #[serde(skip)]
    #[serde(default = "Utc::now")]
    pub last_change: DateTime<Utc>,
    pub deleted: bool,
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
        VerifyIdForUserOrAP
    )
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::BigInt")]
pub struct StrengthSetId(pub i64);

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
    #[serde(skip)]
    #[serde(default = "Utc::now")]
    pub last_change: DateTime<Utc>,
    pub deleted: bool,
}

#[cfg(feature = "full")]
impl VerifyForUserOrAPWithDb for Unverified<StrengthSet> {
    type Entity = StrengthSet;

    fn verify_user_ap(
        self,
        auth: &AuthUserOrAP,
        conn: &PgConnection,
    ) -> Result<Self::Entity, Status> {
        let strength_set = self.0.into_inner();
        if StrengthSession::check_user_id(strength_set.strength_session_id, **auth, conn)
            .map_err(|_| Status::InternalServerError)?
            && StrengthSet::check_user_id(strength_set.id, **auth, conn)
                .map_err(|_| Status::InternalServerError)?
        {
            Ok(strength_set)
        } else {
            Err(Status::Forbidden)
        }
    }
}

#[cfg(feature = "full")]
impl VerifyMultipleForUserOrAPWithDb for Unverified<Vec<StrengthSet>> {
    type Entity = StrengthSet;

    fn verify_user_ap(
        self,
        auth: &AuthUserOrAP,
        conn: &PgConnection,
    ) -> Result<Vec<Self::Entity>, Status> {
        let strength_sets = self.0.into_inner();
        let strength_set_ids: Vec<_> = strength_sets
            .iter()
            .map(|strength_set| strength_set.id)
            .collect();
        let strength_session_ids: Vec<_> = strength_sets
            .iter()
            .map(|strength_set| strength_set.strength_session_id)
            .collect();
        if StrengthSession::check_user_ids(&strength_session_ids, **auth, conn)
            .map_err(|_| Status::InternalServerError)?
            && StrengthSet::check_user_ids(&strength_set_ids, **auth, conn)
                .map_err(|_| Status::InternalServerError)?
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
