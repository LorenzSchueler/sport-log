#[cfg(feature = "server")]
use axum::http::StatusCode;
use chrono::{DateTime, Utc};
#[cfg(feature = "server")]
use diesel::sql_types::BigInt;
use serde::{Deserialize, Serialize};
use sport_log_types_derive::IdString;
#[cfg(feature = "server")]
use sport_log_types_derive::{
    Create, GetById, GetByIds, GetByUser, GetByUserSync, HardDelete, IdFromSql, IdToSql, Update,
    VerifyForUserOrAPWithDb, VerifyForUserOrAPWithoutDb, VerifyIdForUserOrAP,
};

#[cfg(feature = "server")]
use crate::{
    schema::{strength_blueprint, strength_blueprint_set, strength_session, strength_set},
    AuthUserOrAP, CheckUserId, TrainingPlan, Unverified, User, VerifyForUserOrAPCreate,
    VerifyForUserOrAPWithDb, VerifyMultipleForUserOrAPCreate, VerifyMultipleForUserOrAPWithDb,
};
use crate::{types::IdString, Movement, MovementId, TrainingPlanId, UserId};

#[derive(Serialize, Deserialize, Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, IdString)]
#[serde(try_from = "IdString", into = "IdString")]
#[cfg_attr(
    feature = "server",
    derive(Hash, FromSqlRow, AsExpression, IdToSql, IdFromSql, VerifyIdForUserOrAP),
    diesel(sql_type = BigInt)
)]
pub struct StrengthBlueprintId(pub i64);

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
        GetByUser,
        GetByUserSync,
        Update,
        HardDelete,
        VerifyForUserOrAPWithDb,
        VerifyForUserOrAPWithoutDb
    ),
    diesel(table_name = strength_blueprint,belongs_to(User), belongs_to(TrainingPlan), belongs_to(Movement))
)]
pub struct StrengthBlueprint {
    pub id: StrengthBlueprintId,
    pub user_id: UserId,
    pub training_plan_id: TrainingPlanId,
    pub name: String,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub description: Option<String>,
    pub movement_id: MovementId,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub interval: Option<i32>,
    pub deleted: bool,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, PartialEq, Eq, IdString)]
#[serde(try_from = "IdString", into = "IdString")]
#[cfg_attr(
    feature = "server",
    derive(Hash, FromSqlRow, AsExpression, IdToSql, IdFromSql, VerifyIdForUserOrAP),
    diesel(sql_type = BigInt)
)]
pub struct StrengthBlueprintSetId(pub i64);

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
    diesel(table_name = strength_blueprint_set, belongs_to(StrengthBlueprint))
)]
pub struct StrengthBlueprintSet {
    pub id: StrengthBlueprintSetId,
    pub strength_blueprint_id: StrengthBlueprintId,
    pub set_number: i32,
    pub count: i32,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub weight: Option<f32>,
    pub deleted: bool,
}

#[cfg(feature = "server")]
impl VerifyForUserOrAPWithDb for Unverified<StrengthBlueprintSet> {
    type Entity = StrengthBlueprintSet;

    fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Self::Entity, StatusCode> {
        let strength_blueprint_set = self.0;
        if StrengthBlueprintSet::check_user_id(strength_blueprint_set.id, *auth, db)
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(strength_blueprint_set)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

#[cfg(feature = "server")]
impl VerifyMultipleForUserOrAPWithDb for Unverified<Vec<StrengthBlueprintSet>> {
    type Entity = StrengthBlueprintSet;

    fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Vec<Self::Entity>, StatusCode> {
        let strength_blueprint_sets = self.0;
        let strength_blueprint_set_ids: Vec<_> = strength_blueprint_sets
            .iter()
            .map(|strength_set| strength_set.id)
            .collect();
        if StrengthBlueprintSet::check_user_ids(&strength_blueprint_set_ids, *auth, db)
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(strength_blueprint_sets)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

#[cfg(feature = "server")]
impl VerifyForUserOrAPCreate for Unverified<StrengthBlueprintSet> {
    type Entity = StrengthBlueprintSet;

    fn verify_user_ap_create(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Self::Entity, StatusCode> {
        let strength_blueprint_set = self.0;
        if StrengthBlueprint::check_user_id(strength_blueprint_set.strength_blueprint_id, *auth, db)
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(strength_blueprint_set)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

#[cfg(feature = "server")]
impl VerifyMultipleForUserOrAPCreate for Unverified<Vec<StrengthBlueprintSet>> {
    type Entity = StrengthBlueprintSet;

    fn verify_user_ap_create(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Vec<Self::Entity>, StatusCode> {
        let strength_blueprint_sets = self.0;
        let mut strength_blueprint_ids: Vec<_> = strength_blueprint_sets
            .iter()
            .map(|strength_set| strength_set.strength_blueprint_id)
            .collect();
        strength_blueprint_ids.sort_unstable();
        strength_blueprint_ids.dedup();
        if StrengthBlueprint::check_user_ids(&strength_blueprint_ids, *auth, db)
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(strength_blueprint_sets)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, IdString)]
#[serde(try_from = "IdString", into = "IdString")]
#[cfg_attr(
    feature = "server",
    derive(Hash, FromSqlRow, AsExpression, IdToSql, IdFromSql, VerifyIdForUserOrAP),
    diesel(sql_type = BigInt)
)]
pub struct StrengthSessionId(pub i64);

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
        GetByUser,
        GetByUserSync,
        Update,
        HardDelete,
        VerifyForUserOrAPWithDb,
        VerifyForUserOrAPWithoutDb
    ),
    diesel(table_name = strength_session,belongs_to(User), belongs_to(StrengthBlueprint), belongs_to(Movement))
)]
pub struct StrengthSession {
    pub id: StrengthSessionId,
    pub user_id: UserId,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub strength_blueprint_id: Option<StrengthBlueprintId>,
    pub datetime: DateTime<Utc>,
    pub movement_id: MovementId,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub interval: Option<i32>,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub comments: Option<String>,
    pub deleted: bool,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, PartialEq, Eq, IdString)]
#[serde(try_from = "IdString", into = "IdString")]
#[cfg_attr(
    feature = "server",
    derive(Hash, FromSqlRow, AsExpression, IdToSql, IdFromSql, VerifyIdForUserOrAP),
    diesel(sql_type = BigInt)
)]
pub struct StrengthSetId(pub i64);

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
    diesel(table_name = strength_set, belongs_to(StrengthSession))
)]
pub struct StrengthSet {
    pub id: StrengthSetId,
    pub strength_session_id: StrengthSessionId,
    pub set_number: i32,
    pub count: i32,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub weight: Option<f32>,
    pub deleted: bool,
}

#[cfg(feature = "server")]
impl VerifyForUserOrAPWithDb for Unverified<StrengthSet> {
    type Entity = StrengthSet;

    fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Self::Entity, StatusCode> {
        let strength_set = self.0;
        if StrengthSet::check_user_id(strength_set.id, *auth, db)
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(strength_set)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

#[cfg(feature = "server")]
impl VerifyMultipleForUserOrAPWithDb for Unverified<Vec<StrengthSet>> {
    type Entity = StrengthSet;

    fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Vec<Self::Entity>, StatusCode> {
        let strength_sets = self.0;
        let strength_set_ids: Vec<_> = strength_sets
            .iter()
            .map(|strength_set| strength_set.id)
            .collect();
        if StrengthSet::check_user_ids(&strength_set_ids, *auth, db)
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(strength_sets)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

#[cfg(feature = "server")]
impl VerifyForUserOrAPCreate for Unverified<StrengthSet> {
    type Entity = StrengthSet;

    fn verify_user_ap_create(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Self::Entity, StatusCode> {
        let strength_set = self.0;
        if StrengthSession::check_user_id(strength_set.strength_session_id, *auth, db)
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(strength_set)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

#[cfg(feature = "server")]
impl VerifyMultipleForUserOrAPCreate for Unverified<Vec<StrengthSet>> {
    type Entity = StrengthSet;

    fn verify_user_ap_create(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Vec<Self::Entity>, StatusCode> {
        let strength_sets = self.0;
        let mut strength_session_ids: Vec<StrengthSessionId> = strength_sets
            .iter()
            .map(|strength_set| strength_set.strength_session_id)
            .collect();
        strength_session_ids.sort_unstable();
        strength_session_ids.dedup();
        if StrengthSession::check_user_ids(&strength_session_ids, *auth, db)
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(strength_sets)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct StrengthSessionDescription {
    pub strength_session: StrengthSession,
    pub strength_sets: Vec<StrengthSet>,
    pub movement: Movement,
}
