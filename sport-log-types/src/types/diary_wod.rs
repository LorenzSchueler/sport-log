use chrono::NaiveDate;
use serde::{Deserialize, Serialize};

#[cfg(feature = "full")]
use sport_log_types_derive::{
    Create, CreateMultiple, Delete, FromI32, FromSql, GetAll, GetById, GetByUser, ToSql, Update,
    VerifyForActionProviderUnchecked, VerifyForUserWithDb, VerifyForUserWithoutDb, VerifyIdForUser,
};

use crate::types::UserId;
#[cfg(feature = "full")]
use crate::{
    schema::{diary, wod},
    types::User,
};

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq)]
#[cfg_attr(
    feature = "full",
    derive(
        Hash,
        FromSqlRow,
        AsExpression,
        FromI32,
        ToSql,
        FromSql,
        VerifyIdForUser
    )
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::Integer")]
pub struct DiaryId(pub i32);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(
        Associations,
        Identifiable,
        Queryable,
        AsChangeset,
        Create,
        CreateMultiple,
        GetById,
        GetByUser,
        GetAll,
        Update,
        Delete,
        VerifyForUserWithDb
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
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "full", derive(Insertable, VerifyForUserWithoutDb))]
#[cfg_attr(feature = "full", table_name = "diary")]
pub struct NewDiary {
    pub user_id: UserId,
    pub date: NaiveDate,
    pub bodyweight: Option<f32>,
    pub comments: Option<String>,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq)]
#[cfg_attr(
    feature = "full",
    derive(
        Hash,
        FromSqlRow,
        AsExpression,
        FromI32,
        ToSql,
        FromSql,
        VerifyIdForUser
    )
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::Integer")]
pub struct WodId(pub i32);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(
        Associations,
        Identifiable,
        Queryable,
        AsChangeset,
        Create,
        CreateMultiple,
        GetById,
        GetByUser,
        GetAll,
        Update,
        Delete,
        VerifyForUserWithDb,
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
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(Insertable, VerifyForUserWithoutDb, VerifyForActionProviderUnchecked,)
)]
#[cfg_attr(feature = "full", table_name = "wod")]
pub struct NewWod {
    pub user_id: UserId,
    pub date: NaiveDate,
    pub description: Option<String>,
}
