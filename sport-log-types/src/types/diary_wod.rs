use chrono::{DateTime, NaiveDate, Utc};
use serde::{Deserialize, Serialize};

#[cfg(feature = "full")]
use sport_log_types_derive::{
    CheckUserId, Create, CreateMultiple, FromI64, FromSql, GetById, GetByIds, GetByUser,
    GetByUserSync, ToSql, Update, VerifyForUserOrAPWithDb, VerifyForUserOrAPWithoutDb,
    VerifyIdForUserOrAP, VerifyUnchecked,
};

use crate::UserId;
#[cfg(feature = "full")]
use crate::{
    schema::{diary, wod},
    User,
};

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
pub struct DiaryId(pub i64);

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
        VerifyForUserOrAPWithoutDb,
        VerifyUnchecked
    )
)]
#[cfg_attr(feature = "full", table_name = "diary")]
#[cfg_attr(feature = "full", belongs_to(User))]
pub struct Diary {
    pub id: DiaryId,
    pub user_id: UserId,
    pub date: NaiveDate,
    #[cfg_attr(features = "full", changeset_options(treat_none_as_null = "true"))]
    pub bodyweight: Option<f32>,
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
pub struct WodId(pub i64);

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
        VerifyForUserOrAPWithoutDb,
        VerifyUnchecked
    )
)]
#[cfg_attr(feature = "full", table_name = "wod")]
#[cfg_attr(feature = "full", belongs_to(User))]
pub struct Wod {
    pub id: WodId,
    pub user_id: UserId,
    pub date: NaiveDate,
    #[cfg_attr(features = "full", changeset_options(treat_none_as_null = "true"))]
    pub description: Option<String>,
    #[serde(skip)]
    #[serde(default = "Utc::now")]
    pub last_change: DateTime<Utc>,
    pub deleted: bool,
}
