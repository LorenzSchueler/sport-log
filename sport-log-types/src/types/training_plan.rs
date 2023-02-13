use chrono::NaiveDate;
#[cfg(feature = "db")]
use diesel::sql_types::BigInt;
use serde::{Deserialize, Serialize};
use sport_log_types_derive::IdString;
#[cfg(feature = "db")]
use sport_log_types_derive::{IdFromSql, IdToSql};

#[cfg(feature = "db")]
use crate::{schema::training_plan, User};
use crate::{types::IdString, UserId, Weekday};

#[derive(Serialize, Deserialize, Debug, Clone, Copy, PartialEq, Eq, IdString)]
#[serde(try_from = "IdString", into = "IdString")]
#[cfg_attr(
    feature = "db",
    derive(Hash, FromSqlRow, AsExpression, IdToSql, IdFromSql),
    diesel(sql_type = BigInt)
)]
pub struct TrainingPlanId(pub i64);

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
    diesel(table_name = training_plan, belongs_to(User))
)]
pub struct TrainingPlan {
    pub id: TrainingPlanId,
    pub user_id: UserId,
    pub name: String,
    #[cfg_attr(features = "db", changeset_options(treat_none_as_null = "true"))]
    pub description: Option<String>,
    #[cfg_attr(features = "db", changeset_options(treat_none_as_null = "true"))]
    pub date: Option<NaiveDate>,
    #[cfg_attr(features = "db", changeset_options(treat_none_as_null = "true"))]
    pub weekday: Option<Weekday>,
    pub deleted: bool,
}
