use chrono::{DateTime, Utc};
#[cfg(feature = "db")]
use diesel::sql_types::BigInt;
use serde::{Deserialize, Serialize};
use sport_log_types_derive::IdString;
#[cfg(feature = "db")]
use sport_log_types_derive::{IdFromSql, IdToSql};

#[cfg(feature = "db")]
use crate::{
    schema::{strength_blueprint, strength_blueprint_set, strength_session, strength_set},
    TrainingPlan, User,
};
use crate::{types::IdString, Movement, MovementId, TrainingPlanId, UserId};

#[derive(Serialize, Deserialize, Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, IdString)]
#[serde(try_from = "IdString", into = "IdString")]
#[cfg_attr(
    feature = "db",
    derive(Hash, FromSqlRow, AsExpression, IdToSql, IdFromSql),
    diesel(sql_type = BigInt)
)]
pub struct StrengthBlueprintId(pub i64);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "db",
    derive(
        Insertable,
        Associations,
        Identifiable,
        Queryable,
        Selectable,
        AsChangeset,
    ),
    diesel(table_name = strength_blueprint, belongs_to(User), belongs_to(TrainingPlan), belongs_to(Movement))
)]
pub struct StrengthBlueprint {
    pub id: StrengthBlueprintId,
    pub user_id: UserId,
    pub training_plan_id: TrainingPlanId,
    pub name: String,
    #[cfg_attr(features = "db", changeset_options(treat_none_as_null = "true"))]
    pub description: Option<String>,
    pub movement_id: MovementId,
    #[cfg_attr(features = "db", changeset_options(treat_none_as_null = "true"))]
    pub interval: Option<i32>,
    pub deleted: bool,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, PartialEq, Eq, IdString)]
#[serde(try_from = "IdString", into = "IdString")]
#[cfg_attr(
    feature = "db",
    derive(Hash, FromSqlRow, AsExpression, IdToSql, IdFromSql),
    diesel(sql_type = BigInt)
)]
pub struct StrengthBlueprintSetId(pub i64);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "db",
    derive(
        Insertable,
        Associations,
        Identifiable,
        Queryable,
        Selectable,
        AsChangeset,
    ),
    diesel(table_name = strength_blueprint_set, belongs_to(StrengthBlueprint))
)]
pub struct StrengthBlueprintSet {
    pub id: StrengthBlueprintSetId,
    pub strength_blueprint_id: StrengthBlueprintId,
    pub set_number: i32,
    pub count: i32,
    #[cfg_attr(features = "db", changeset_options(treat_none_as_null = "true"))]
    pub weight: Option<f32>,
    pub deleted: bool,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, IdString)]
#[serde(try_from = "IdString", into = "IdString")]
#[cfg_attr(
    feature = "db",
    derive(Hash, FromSqlRow, AsExpression, IdToSql, IdFromSql),
    diesel(sql_type = BigInt)
)]
pub struct StrengthSessionId(pub i64);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "db",
    derive(
        Insertable,
        Associations,
        Identifiable,
        Queryable,
        Selectable,
        AsChangeset,
    ),
    diesel(table_name = strength_session,belongs_to(User), belongs_to(StrengthBlueprint), belongs_to(Movement))
)]
pub struct StrengthSession {
    pub id: StrengthSessionId,
    pub user_id: UserId,
    #[cfg_attr(features = "db", changeset_options(treat_none_as_null = "true"))]
    pub strength_blueprint_id: Option<StrengthBlueprintId>,
    pub datetime: DateTime<Utc>,
    pub movement_id: MovementId,
    #[cfg_attr(features = "db", changeset_options(treat_none_as_null = "true"))]
    pub interval: Option<i32>,
    #[cfg_attr(features = "db", changeset_options(treat_none_as_null = "true"))]
    pub comments: Option<String>,
    pub deleted: bool,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, PartialEq, Eq, IdString)]
#[serde(try_from = "IdString", into = "IdString")]
#[cfg_attr(
    feature = "db",
    derive(Hash, FromSqlRow, AsExpression, IdToSql, IdFromSql),
    diesel(sql_type = BigInt)
)]
pub struct StrengthSetId(pub i64);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "db",
    derive(
        Insertable,
        Associations,
        Identifiable,
        Queryable,
        Selectable,
        AsChangeset,
    ),
    diesel(table_name = strength_set, belongs_to(StrengthSession))
)]
pub struct StrengthSet {
    pub id: StrengthSetId,
    pub strength_session_id: StrengthSessionId,
    pub set_number: i32,
    pub count: i32,
    #[cfg_attr(features = "db", changeset_options(treat_none_as_null = "true"))]
    pub weight: Option<f32>,
    pub deleted: bool,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct StrengthSessionDescription {
    pub strength_session: StrengthSession,
    pub strength_sets: Vec<StrengthSet>,
    pub movement: Movement,
}
