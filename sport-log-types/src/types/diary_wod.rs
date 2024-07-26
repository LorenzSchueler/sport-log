use chrono::NaiveDate;
use derive_deftly::Deftly;
#[cfg(feature = "db")]
use diesel::{deserialize::FromSqlRow, expression::AsExpression, prelude::*, sql_types::BigInt};
use serde::{Deserialize, Serialize};

#[cfg(feature = "db")]
use crate::{
    schema::{diary, wod},
    User,
};
use crate::{types::IdString, UserId};

#[derive(Serialize, Deserialize, Debug, Clone, Copy, PartialEq, Eq, Deftly)]
#[derive_deftly(IdString)]
#[serde(try_from = "IdString", into = "IdString")]
#[cfg_attr(
    feature = "db",
    derive(Hash, FromSqlRow, AsExpression),
    derive_deftly(IdToSql, IdFromSql),
    diesel(sql_type = BigInt)
)]
pub struct DiaryId(pub i64);

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
    diesel(table_name = diary, belongs_to(User))
)]
pub struct Diary {
    pub id: DiaryId,
    pub user_id: UserId,
    pub date: NaiveDate,
    #[cfg_attr(feature = "db", diesel(treat_none_as_null = true))]
    pub bodyweight: Option<f32>,
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
pub struct WodId(pub i64);

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
    diesel(table_name = wod, belongs_to(User))
)]
pub struct Wod {
    pub id: WodId,
    pub user_id: UserId,
    pub date: NaiveDate,
    #[cfg_attr(feature = "db", diesel(treat_none_as_null = true))]
    pub description: Option<String>,
    pub deleted: bool,
}
