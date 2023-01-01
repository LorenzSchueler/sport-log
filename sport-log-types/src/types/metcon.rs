#[cfg(feature = "server")]
use axum::http::StatusCode;
use chrono::{DateTime, Utc};
#[cfg(feature = "server")]
use diesel::{sql_types::BigInt, PgConnection};
#[cfg(feature = "server")]
use diesel_derive_enum::DbEnum;
use serde::{Deserialize, Serialize};
#[cfg(feature = "server")]
use sport_log_types_derive::{
    CheckUserId, Create, GetById, GetByIds, GetByUser, GetByUserSync, HardDelete, IdFromSql,
    IdToSql, Update, VerifyForUserOrAPWithDb, VerifyForUserOrAPWithoutDb, VerifyIdForUserOrAP,
};

#[cfg(feature = "server")]
use crate::{
    schema::{metcon, metcon_item, metcon_movement, metcon_session},
    AuthUserOrAP, CheckOptionalUserId, CheckUserId, TrainingPlan, Unverified, UnverifiedId,
    UnverifiedIds, User, VerifyForUserOrAPCreate, VerifyForUserOrAPWithDb,
    VerifyForUserOrAPWithoutDb, VerifyIdForUserOrAP, VerifyIdsForUserOrAP,
    VerifyMultipleForUserOrAPCreate, VerifyMultipleForUserOrAPWithDb,
    VerifyMultipleForUserOrAPWithoutDb,
};
use crate::{Movement, MovementId, TrainingPlanId, UserId};

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq)]
#[cfg_attr(feature = "server", derive(DbEnum))]
pub enum MetconType {
    Amrap,
    Emom,
    ForTime,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq)]
#[cfg_attr(feature = "server", derive(DbEnum))]
pub enum DistanceUnit {
    Meter,
    Km,
    Yard,
    Foot,
    Mile,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq, PartialOrd, Ord)]
#[serde(transparent)]
#[cfg_attr(
    feature = "server",
    derive(Hash, FromSqlRow, AsExpression, IdToSql, IdFromSql),
    diesel(sql_type = BigInt)
)]
pub struct MetconId(pub i64);

#[cfg(feature = "server")]
impl VerifyIdForUserOrAP for UnverifiedId<MetconId> {
    type Id = MetconId;

    fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Self::Id, StatusCode> {
        if Metcon::check_optional_user_id(self.0, *auth, db).map_err(|_| StatusCode::FORBIDDEN)? {
            Ok(self.0)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

#[cfg(feature = "server")]
impl VerifyIdsForUserOrAP for UnverifiedIds<MetconId> {
    type Id = MetconId;

    fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Vec<Self::Id>, StatusCode> {
        if Metcon::check_optional_user_ids(&self.0, *auth, db).map_err(|_| StatusCode::FORBIDDEN)? {
            Ok(self.0)
        } else {
            Err(StatusCode::FORBIDDEN)
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
        CheckUserId,
    ),
    diesel(table_name = metcon,belongs_to(User))
)]
pub struct Metcon {
    pub id: MetconId,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub user_id: Option<UserId>,
    pub name: String,
    pub metcon_type: MetconType,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub rounds: Option<i32>,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub timecap: Option<i32>,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub description: Option<String>,
    pub deleted: bool,
}

#[cfg(feature = "server")]
impl VerifyForUserOrAPWithDb for Unverified<Metcon> {
    type Entity = Metcon;

    fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Self::Entity, StatusCode> {
        let metcon = self.0;
        if metcon.user_id == Some(*auth)
            && Metcon::check_user_id(metcon.id, *auth, db)
                .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(metcon)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

#[cfg(feature = "server")]
impl VerifyMultipleForUserOrAPWithDb for Unverified<Vec<Metcon>> {
    type Entity = Metcon;

    fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Vec<Self::Entity>, StatusCode> {
        let metcons = self.0;
        let metcon_ids: Vec<_> = metcons.iter().map(|metcon| metcon.id).collect();
        if metcons.iter().all(|metcon| metcon.user_id == Some(*auth))
            && Metcon::check_user_ids(&metcon_ids, *auth, db)
                .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(metcons)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

#[cfg(feature = "server")]
impl VerifyForUserOrAPWithoutDb for Unverified<Metcon> {
    type Entity = Metcon;

    fn verify_user_ap_without_db(self, auth: AuthUserOrAP) -> Result<Self::Entity, StatusCode> {
        let metcon = self.0;
        if metcon.user_id == Some(*auth) {
            Ok(metcon)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

#[cfg(feature = "server")]
impl VerifyMultipleForUserOrAPWithoutDb for Unverified<Vec<Metcon>> {
    type Entity = Metcon;

    fn verify_user_ap_without_db(
        self,
        auth: AuthUserOrAP,
    ) -> Result<Vec<Self::Entity>, StatusCode> {
        let metcons = self.0;
        if metcons.iter().all(|metcon| metcon.user_id == Some(*auth)) {
            Ok(metcons)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq, PartialOrd, Ord)]
#[serde(transparent)]
#[cfg_attr(
    feature = "server",
    derive(Hash, FromSqlRow, AsExpression, IdToSql, IdFromSql),
    diesel(sql_type = BigInt)
)]
pub struct MetconMovementId(pub i64);

#[cfg(feature = "server")]
impl VerifyIdForUserOrAP for UnverifiedId<MetconMovementId> {
    type Id = MetconMovementId;

    fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Self::Id, StatusCode> {
        if MetconMovement::check_optional_user_id(self.0, *auth, db)
            .map_err(|_| StatusCode::FORBIDDEN)?
        {
            Ok(self.0)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

#[cfg(feature = "server")]
impl VerifyIdsForUserOrAP for UnverifiedIds<MetconMovementId> {
    type Id = MetconMovementId;

    fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Vec<Self::Id>, StatusCode> {
        if MetconMovement::check_optional_user_ids(&self.0, *auth, db)
            .map_err(|_| StatusCode::FORBIDDEN)?
        {
            Ok(self.0)
        } else {
            Err(StatusCode::FORBIDDEN)
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
        Selectable,
        AsChangeset,
        Create,
        GetById,
        GetByIds,
        Update,
        HardDelete,
    ),
    diesel(table_name = metcon_movement, belongs_to(Movement), belongs_to(Metcon))
)]
pub struct MetconMovement {
    pub id: MetconMovementId,
    pub metcon_id: MetconId,
    pub movement_id: MovementId,
    pub distance_unit: Option<DistanceUnit>,
    pub movement_number: i32,
    pub count: i32,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub male_weight: Option<f32>,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub female_weight: Option<f32>,
    pub deleted: bool,
}

#[cfg(feature = "server")]
impl VerifyForUserOrAPWithDb for Unverified<MetconMovement> {
    type Entity = MetconMovement;

    fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Self::Entity, StatusCode> {
        let metcon_movement = self.0;
        if MetconMovement::check_user_id(metcon_movement.id, *auth, db)
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(metcon_movement)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

#[cfg(feature = "server")]
impl VerifyMultipleForUserOrAPWithDb for Unverified<Vec<MetconMovement>> {
    type Entity = MetconMovement;

    fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Vec<Self::Entity>, StatusCode> {
        let metcon_movements = self.0;
        let metcon_movement_ids: Vec<_> = metcon_movements
            .iter()
            .map(|metcon_movement| metcon_movement.id)
            .collect();
        if MetconMovement::check_user_ids(&metcon_movement_ids, *auth, db)
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(metcon_movements)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

#[cfg(feature = "server")]
impl VerifyForUserOrAPCreate for Unverified<MetconMovement> {
    type Entity = MetconMovement;

    fn verify_user_ap_create(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Self::Entity, StatusCode> {
        let metcon_movement = self.0;
        if Metcon::check_user_id(metcon_movement.metcon_id, *auth, db)
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(metcon_movement)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

#[cfg(feature = "server")]
impl VerifyMultipleForUserOrAPCreate for Unverified<Vec<MetconMovement>> {
    type Entity = MetconMovement;

    fn verify_user_ap_create(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Vec<Self::Entity>, StatusCode> {
        let metcon_movements = self.0;
        let mut metcon_ids: Vec<_> = metcon_movements
            .iter()
            .map(|metcon_movement| metcon_movement.metcon_id)
            .collect();
        metcon_ids.sort_unstable();
        metcon_ids.dedup();
        if Metcon::check_user_ids(&metcon_ids, *auth, db)
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(metcon_movements)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq, PartialOrd, Ord)]
#[serde(transparent)]
#[cfg_attr(
    feature = "server",
    derive(Hash, FromSqlRow, AsExpression, IdToSql, IdFromSql, VerifyIdForUserOrAP),
    diesel(sql_type = BigInt)
)]
pub struct MetconSessionId(pub i64);

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
        CheckUserId,
        VerifyForUserOrAPWithDb,
        VerifyForUserOrAPWithoutDb
    ),
    diesel(table_name = metcon_session, belongs_to(User), belongs_to(Metcon))
)]
pub struct MetconSession {
    pub id: MetconSessionId,
    pub user_id: UserId,
    pub metcon_id: MetconId,
    pub datetime: DateTime<Utc>,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub time: Option<i32>,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub rounds: Option<i32>,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub reps: Option<i32>,
    pub rx: bool,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub comments: Option<String>,
    pub deleted: bool,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq, PartialOrd, Ord)]
#[serde(transparent)]
#[cfg_attr(
    feature = "server",
    derive(Hash, FromSqlRow, AsExpression, IdToSql, IdFromSql, VerifyIdForUserOrAP),
    diesel(sql_type = BigInt)
)]
pub struct MetconItemId(pub i64);

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
    diesel(table_name = metcon_item, belongs_to(TrainingPlan), belongs_to(Metcon))
)]
pub struct MetconItem {
    pub id: MetconItemId,
    pub training_plan_id: TrainingPlanId,
    pub metcon_id: MetconId,
    pub deleted: bool,
}

#[cfg(feature = "server")]
impl VerifyForUserOrAPWithDb for Unverified<MetconItem> {
    type Entity = MetconItem;

    fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Self::Entity, StatusCode> {
        let metcon_item = self.0;
        if MetconItem::check_user_id(metcon_item.id, *auth, db)
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(metcon_item)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

#[cfg(feature = "server")]
impl VerifyMultipleForUserOrAPWithDb for Unverified<Vec<MetconItem>> {
    type Entity = MetconItem;

    fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Vec<Self::Entity>, StatusCode> {
        let metcon_items = self.0;
        let metcon_item_ids: Vec<_> = metcon_items
            .iter()
            .map(|metcon_item| metcon_item.id)
            .collect();
        if MetconItem::check_user_ids(&metcon_item_ids, *auth, db)
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(metcon_items)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

#[cfg(feature = "server")]
impl VerifyForUserOrAPCreate for Unverified<MetconItem> {
    type Entity = MetconItem;

    fn verify_user_ap_create(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Self::Entity, StatusCode> {
        let metcon_item = self.0;
        if Metcon::check_optional_user_id(metcon_item.metcon_id, *auth, db)
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(metcon_item)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

#[cfg(feature = "server")]
impl VerifyMultipleForUserOrAPCreate for Unverified<Vec<MetconItem>> {
    type Entity = MetconItem;

    fn verify_user_ap_create(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Vec<Self::Entity>, StatusCode> {
        let metcon_items = self.0;
        let mut metcon_ids: Vec<_> = metcon_items
            .iter()
            .map(|metcon_item| metcon_item.metcon_id)
            .collect();
        metcon_ids.sort_unstable();
        metcon_ids.dedup();
        if Metcon::check_optional_user_ids(&metcon_ids, *auth, db)
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(metcon_items)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct MetconSessionDescription {
    pub metcon_session: MetconSession,
    pub metcon: Metcon,
    pub movements: Vec<(MetconMovement, Movement)>,
}
