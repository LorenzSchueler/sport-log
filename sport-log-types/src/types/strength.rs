use chrono::{DateTime, Utc};
use derive_deftly::Deftly;
#[cfg(feature = "db")]
use diesel::{deserialize::FromSqlRow, expression::AsExpression, prelude::*, sql_types::BigInt};
use serde::{Deserialize, Serialize};

#[cfg(feature = "db")]
use crate::{
    schema::{eorm, strength_session, strength_set},
    Movement, User,
};
use crate::{types::IdString, MovementId, UserId};

#[derive(Serialize, Deserialize, Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Deftly)]
#[derive_deftly(IdString)]
#[serde(try_from = "IdString", into = "IdString")]
#[cfg_attr(
    feature = "db",
    derive(Hash, FromSqlRow, AsExpression),
    derive_deftly(IdToSql, IdFromSql),
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
    diesel(table_name = strength_session,belongs_to(User),belongs_to(Movement))
)]
pub struct StrengthSession {
    pub id: StrengthSessionId,
    pub user_id: UserId,
    pub datetime: DateTime<Utc>,
    pub movement_id: MovementId,
    #[cfg_attr(feature = "db", diesel(treat_none_as_null = true))]
    pub interval: Option<i32>,
    #[cfg_attr(feature = "db", diesel(treat_none_as_null = true))]
    pub comments: Option<String>,
    pub deleted: bool,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, PartialEq, Eq, Deftly)]
#[derive_deftly(IdString)]
#[serde(try_from = "IdString", into = "IdString")]
#[cfg_attr(
    feature = "db",
    derive(Hash, FromSqlRow, AsExpression),
    derive_deftly(IdToSql, IdFromSql),
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
    pub user_id: UserId,
    pub strength_session_id: StrengthSessionId,
    pub set_number: i32,
    pub count: i32,
    #[cfg_attr(feature = "db", diesel(treat_none_as_null = true))]
    pub weight: Option<f32>,
    pub deleted: bool,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, PartialEq, Eq, Deftly)]
#[derive_deftly(IdString)]
#[serde(try_from = "IdString", into = "IdString")]
#[cfg_attr(
    feature = "db",
    derive(Hash, FromSqlRow, AsExpression),
    derive_deftly(IdToSql, IdFromSql),
    diesel(sql_type = BigInt)
)]
pub struct EormId(pub i64);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "db",
    derive(Insertable, Identifiable, Queryable, Selectable),
    diesel(table_name = eorm)
)]
pub struct Eorm {
    pub id: EormId,
    pub reps: i32,
    pub percentage: f32,
}
