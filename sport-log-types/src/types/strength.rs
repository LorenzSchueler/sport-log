use chrono::{DateTime, Utc};
#[cfg(feature = "server")]
use rocket::http::Status;
use serde::{Deserialize, Serialize};

#[cfg(feature = "server")]
use sport_log_types_derive::{
    Create, CreateMultiple, FromSql, GetById, GetByIds, GetByUser, GetByUserSync, HardDelete,
    ToSql, Update, VerifyForUserOrAPWithDb, VerifyForUserOrAPWithoutDb, VerifyIdForUserOrAP,
};
use sport_log_types_derive::{FromI64, ToI64};

use crate::{
    from_str, from_str_optional, to_str, to_str_optional, Movement, MovementId, TrainingPlanId,
    UserId,
};
#[cfg(feature = "server")]
use crate::{
    schema::{strength_blueprint, strength_blueprint_set, strength_session, strength_set},
    AuthUserOrAP, CheckUserId, TrainingPlan, Unverified, User, VerifyForUserOrAPCreate,
    VerifyForUserOrAPWithDb, VerifyMultipleForUserOrAPCreate, VerifyMultipleForUserOrAPWithDb,
};

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq, FromI64, ToI64)]
#[cfg_attr(
    feature = "server",
    derive(Hash, FromSqlRow, AsExpression, ToSql, FromSql, VerifyIdForUserOrAP)
)]
#[cfg_attr(feature = "server", sql_type = "diesel::sql_types::BigInt")]
pub struct StrengthBlueprintId(pub i64);

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
        GetByUser,
        GetByUserSync,
        Update,
        HardDelete,
        VerifyForUserOrAPWithDb,
        VerifyForUserOrAPWithoutDb
    )
)]
#[cfg_attr(feature = "server", table_name = "strength_blueprint")]
#[cfg_attr(feature = "server", belongs_to(User))]
#[cfg_attr(feature = "server", belongs_to(TrainingPlan))]
#[cfg_attr(feature = "server", belongs_to(Movement))]
pub struct StrengthBlueprint {
    #[serde(serialize_with = "to_str")]
    #[serde(deserialize_with = "from_str")]
    pub id: StrengthBlueprintId,
    #[serde(serialize_with = "to_str")]
    #[serde(deserialize_with = "from_str")]
    pub user_id: UserId,
    #[serde(serialize_with = "to_str")]
    #[serde(deserialize_with = "from_str")]
    pub training_plan_id: TrainingPlanId,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub name: Option<String>,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub description: Option<String>,
    #[serde(serialize_with = "to_str")]
    #[serde(deserialize_with = "from_str")]
    pub movement_id: MovementId,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub interval: Option<i32>,
    #[serde(skip)]
    #[serde(default = "Utc::now")]
    pub last_change: DateTime<Utc>,
    pub deleted: bool,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq, FromI64, ToI64)]
#[cfg_attr(
    feature = "server",
    derive(Hash, FromSqlRow, AsExpression, ToSql, FromSql, VerifyIdForUserOrAP)
)]
#[cfg_attr(feature = "server", sql_type = "diesel::sql_types::BigInt")]
pub struct StrengthBlueprintSetId(pub i64);

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
#[cfg_attr(feature = "server", table_name = "strength_blueprint_set")]
#[cfg_attr(feature = "server", belongs_to(StrengthBlueprint))]
pub struct StrengthBlueprintSet {
    #[serde(serialize_with = "to_str")]
    #[serde(deserialize_with = "from_str")]
    pub id: StrengthBlueprintSetId,
    #[serde(serialize_with = "to_str")]
    #[serde(deserialize_with = "from_str")]
    pub strength_blueprint_id: StrengthBlueprintId,
    pub set_number: i32,
    pub count: i32,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub weight: Option<f32>,
    #[serde(skip)]
    #[serde(default = "Utc::now")]
    pub last_change: DateTime<Utc>,
    pub deleted: bool,
}

#[cfg(feature = "server")]
impl VerifyForUserOrAPWithDb for Unverified<StrengthBlueprintSet> {
    type Entity = StrengthBlueprintSet;

    fn verify_user_ap(
        self,
        auth: &AuthUserOrAP,
        conn: &PgConnection,
    ) -> Result<Self::Entity, Status> {
        let strength_blueprint_set = self.0.into_inner();
        if StrengthBlueprintSet::check_user_id(strength_blueprint_set.id, **auth, conn)
            .map_err(|_| Status::InternalServerError)?
        {
            Ok(strength_blueprint_set)
        } else {
            Err(Status::Forbidden)
        }
    }
}

#[cfg(feature = "server")]
impl VerifyMultipleForUserOrAPWithDb for Unverified<Vec<StrengthBlueprintSet>> {
    type Entity = StrengthBlueprintSet;

    fn verify_user_ap(
        self,
        auth: &AuthUserOrAP,
        conn: &PgConnection,
    ) -> Result<Vec<Self::Entity>, Status> {
        let strength_blueprint_sets = self.0.into_inner();
        let strength_blueprint_set_ids: Vec<_> = strength_blueprint_sets
            .iter()
            .map(|strength_set| strength_set.id)
            .collect();
        if StrengthBlueprintSet::check_user_ids(&strength_blueprint_set_ids, **auth, conn)
            .map_err(|_| Status::InternalServerError)?
        {
            Ok(strength_blueprint_sets)
        } else {
            Err(Status::Forbidden)
        }
    }
}

#[cfg(feature = "server")]
impl VerifyForUserOrAPCreate for Unverified<StrengthBlueprintSet> {
    type Entity = StrengthBlueprintSet;

    fn verify_user_ap_create(
        self,
        auth: &AuthUserOrAP,
        conn: &PgConnection,
    ) -> Result<Self::Entity, Status> {
        let strength_blueprint_set = self.0.into_inner();
        if StrengthBlueprint::check_user_id(
            strength_blueprint_set.strength_blueprint_id,
            **auth,
            conn,
        )
        .map_err(|_| Status::InternalServerError)?
        {
            Ok(strength_blueprint_set)
        } else {
            Err(Status::Forbidden)
        }
    }
}

#[cfg(feature = "server")]
impl VerifyMultipleForUserOrAPCreate for Unverified<Vec<StrengthBlueprintSet>> {
    type Entity = StrengthBlueprintSet;

    fn verify_user_ap_create(
        self,
        auth: &AuthUserOrAP,
        conn: &PgConnection,
    ) -> Result<Vec<Self::Entity>, Status> {
        let strength_blueprint_sets = self.0.into_inner();
        let strength_blueprint_ids: Vec<_> = strength_blueprint_sets
            .iter()
            .map(|strength_set| strength_set.strength_blueprint_id)
            .collect();
        if StrengthBlueprint::check_user_ids(&strength_blueprint_ids, **auth, conn)
            .map_err(|_| Status::InternalServerError)?
        {
            Ok(strength_blueprint_sets)
        } else {
            Err(Status::Forbidden)
        }
    }
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq, FromI64, ToI64)]
#[cfg_attr(
    feature = "server",
    derive(Hash, FromSqlRow, AsExpression, ToSql, FromSql, VerifyIdForUserOrAP)
)]
#[cfg_attr(feature = "server", sql_type = "diesel::sql_types::BigInt")]
pub struct StrengthSessionId(pub i64);

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
        GetByUser,
        GetByUserSync,
        Update,
        HardDelete,
        VerifyForUserOrAPWithDb,
        VerifyForUserOrAPWithoutDb
    )
)]
#[cfg_attr(feature = "server", table_name = "strength_session")]
#[cfg_attr(feature = "server", belongs_to(User))]
#[cfg_attr(feature = "server", belongs_to(StrengthBlueprint))]
#[cfg_attr(feature = "server", belongs_to(Movement))]
pub struct StrengthSession {
    #[serde(serialize_with = "to_str")]
    #[serde(deserialize_with = "from_str")]
    pub id: StrengthSessionId,
    #[serde(serialize_with = "to_str")]
    #[serde(deserialize_with = "from_str")]
    pub user_id: UserId,
    #[serde(serialize_with = "to_str_optional")]
    #[serde(deserialize_with = "from_str_optional")]
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub strength_blueprint_id: Option<StrengthBlueprintId>,
    pub datetime: DateTime<Utc>,
    #[serde(serialize_with = "to_str")]
    #[serde(deserialize_with = "from_str")]
    pub movement_id: MovementId,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub interval: Option<i32>,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub comments: Option<String>,
    #[serde(skip)]
    #[serde(default = "Utc::now")]
    pub last_change: DateTime<Utc>,
    pub deleted: bool,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq, FromI64, ToI64)]
#[cfg_attr(
    feature = "server",
    derive(Hash, FromSqlRow, AsExpression, ToSql, FromSql, VerifyIdForUserOrAP)
)]
#[cfg_attr(feature = "server", sql_type = "diesel::sql_types::BigInt")]
pub struct StrengthSetId(pub i64);

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
#[cfg_attr(feature = "server", table_name = "strength_set")]
#[cfg_attr(feature = "server", belongs_to(StrengthSession))]
pub struct StrengthSet {
    #[serde(serialize_with = "to_str")]
    #[serde(deserialize_with = "from_str")]
    pub id: StrengthSetId,
    #[serde(serialize_with = "to_str")]
    #[serde(deserialize_with = "from_str")]
    pub strength_session_id: StrengthSessionId,
    pub set_number: i32,
    pub count: i32,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub weight: Option<f32>,
    #[serde(skip)]
    #[serde(default = "Utc::now")]
    pub last_change: DateTime<Utc>,
    pub deleted: bool,
}

#[cfg(feature = "server")]
impl VerifyForUserOrAPWithDb for Unverified<StrengthSet> {
    type Entity = StrengthSet;

    fn verify_user_ap(
        self,
        auth: &AuthUserOrAP,
        conn: &PgConnection,
    ) -> Result<Self::Entity, Status> {
        let strength_set = self.0.into_inner();
        if StrengthSet::check_user_id(strength_set.id, **auth, conn)
            .map_err(|_| Status::InternalServerError)?
        {
            Ok(strength_set)
        } else {
            Err(Status::Forbidden)
        }
    }
}

#[cfg(feature = "server")]
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
        if StrengthSet::check_user_ids(&strength_set_ids, **auth, conn)
            .map_err(|_| Status::InternalServerError)?
        {
            Ok(strength_sets)
        } else {
            Err(Status::Forbidden)
        }
    }
}

#[cfg(feature = "server")]
impl VerifyForUserOrAPCreate for Unverified<StrengthSet> {
    type Entity = StrengthSet;

    fn verify_user_ap_create(
        self,
        auth: &AuthUserOrAP,
        conn: &PgConnection,
    ) -> Result<Self::Entity, Status> {
        let strength_set = self.0.into_inner();
        if StrengthSession::check_user_id(strength_set.strength_session_id, **auth, conn)
            .map_err(|_| Status::InternalServerError)?
        {
            Ok(strength_set)
        } else {
            Err(Status::Forbidden)
        }
    }
}

#[cfg(feature = "server")]
impl VerifyMultipleForUserOrAPCreate for Unverified<Vec<StrengthSet>> {
    type Entity = StrengthSet;

    fn verify_user_ap_create(
        self,
        auth: &AuthUserOrAP,
        conn: &PgConnection,
    ) -> Result<Vec<Self::Entity>, Status> {
        let strength_sets = self.0.into_inner();
        let strength_session_ids: Vec<_> = strength_sets
            .iter()
            .map(|strength_set| strength_set.strength_session_id)
            .collect();
        if StrengthSession::check_user_ids(&strength_session_ids, **auth, conn)
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
