use chrono::NaiveDate;
#[cfg(feature = "server")]
use diesel::sql_types::BigInt;
use serde::{Deserialize, Serialize};
use sport_log_types_derive::IdString;
#[cfg(feature = "server")]
use sport_log_types_derive::{
    CheckUserId, Create, GetById, GetByIds, GetByUser, GetByUserSync, HardDelete, IdFromSql,
    IdToSql, Update, VerifyForUserOrAPWithDb, VerifyForUserOrAPWithoutDb, VerifyIdForUserOrAP,
    VerifyUnchecked,
};

#[cfg(feature = "server")]
use crate::{
    schema::{diary, wod},
    User,
};
use crate::{types::IdString, UserId};

#[derive(Serialize, Deserialize, Debug, Clone, Copy, PartialEq, Eq, IdString)]
#[serde(try_from = "IdString", into = "IdString")]
#[cfg_attr(
    feature = "server",
    derive(Hash, FromSqlRow, AsExpression, IdToSql, IdFromSql, VerifyIdForUserOrAP),
    diesel(sql_type = BigInt)
)]
pub struct DiaryId(pub i64);

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
        VerifyForUserOrAPWithoutDb,
        VerifyUnchecked
    ),
    diesel(table_name = diary,belongs_to(User))
)]
pub struct Diary {
    pub id: DiaryId,
    pub user_id: UserId,
    pub date: NaiveDate,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub bodyweight: Option<f32>,
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
pub struct WodId(pub i64);

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
        VerifyForUserOrAPWithoutDb,
        VerifyUnchecked
    ),
    diesel(table_name = wod,belongs_to(User))
)]
pub struct Wod {
    pub id: WodId,
    pub user_id: UserId,
    pub date: NaiveDate,
    #[cfg_attr(features = "server", changeset_options(treat_none_as_null = "true"))]
    pub description: Option<String>,
    pub deleted: bool,
}
