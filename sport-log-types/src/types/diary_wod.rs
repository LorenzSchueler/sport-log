use chrono::NaiveDate;
use serde::{Deserialize, Serialize};

#[cfg(feature = "full")]
use sport_log_server_derive::{
    Create, Delete, GetAll, GetById, GetByUser, InnerIntFromParam, InnerIntFromSql, InnerIntToSql,
    Update, VerifyForActionProviderUnchecked, VerifyForUserWithDb, VerifyForUserWithoutDb,
    VerifyIdForUser,
};

#[cfg(feature = "full")]
use crate::schema::{diary, wod};
use crate::types::UserId;

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(
        FromSqlRow,
        AsExpression,
        Copy,
        PartialEq,
        Eq,
        InnerIntToSql,
        InnerIntFromSql,
    )
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::Integer")]
pub struct DiaryId(pub i32);

#[cfg(feature = "full")]
#[derive(InnerIntFromParam, VerifyIdForUser)]
pub struct UnverifiedDiaryId(i32);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(
        Queryable,
        AsChangeset,
        Create,
        GetById,
        GetByUser,
        GetAll,
        Update,
        Delete,
        VerifyForUserWithDb
    )
)]
#[cfg_attr(feature = "full", table_name = "diary")]
pub struct Diary {
    pub id: DiaryId,
    pub user_id: UserId,
    pub date: NaiveDate,
    pub bodyweight: Option<f32>,
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

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(
        FromSqlRow,
        AsExpression,
        Copy,
        PartialEq,
        Eq,
        InnerIntToSql,
        InnerIntFromSql,
    )
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::Integer")]
pub struct WodId(pub i32);

#[cfg(feature = "full")]
#[derive(InnerIntFromParam, VerifyIdForUser)]
pub struct UnverifiedWodId(i32);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(
        Queryable,
        AsChangeset,
        Create,
        GetById,
        GetByUser,
        GetAll,
        Update,
        Delete,
        VerifyForUserWithDb,
    )
)]
#[cfg_attr(feature = "full", table_name = "wod")]
pub struct Wod {
    pub id: WodId,
    pub user_id: UserId,
    pub date: NaiveDate,
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
