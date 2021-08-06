use serde::{Deserialize, Serialize};

#[cfg(feature = "full")]
use sport_log_types_derive::{
    Create, CreateMultiple, Delete, DeleteMultiple, FromI32, FromSql, GetAll, GetById, GetByIds,
    GetByUser, ToSql, Update, VerifyForAdminWithoutDb, VerifyForUserWithDb, VerifyForUserWithoutDb,
    VerifyIdForAdmin, VerifyIdForUser, VerifyIdUnchecked,
};

use crate::UserId;
#[cfg(feature = "full")]
use crate::{
    schema::{platform, platform_credential},
    User,
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
        VerifyIdForAdmin,
        VerifyIdUnchecked
    )
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::Integer")]
pub struct PlatformId(pub i32);

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
        GetAll,
        Update,
        Delete,
        DeleteMultiple,
        VerifyForAdminWithoutDb,
    )
)]
#[cfg_attr(feature = "full", table_name = "platform")]
pub struct Platform {
    pub id: PlatformId,
    pub name: String,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "full", derive(Insertable, VerifyForAdminWithoutDb))]
#[cfg_attr(feature = "full", table_name = "platform")]
pub struct NewPlatform {
    pub name: String,
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
pub struct PlatformCredentialId(pub i32);

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
        GetByIds,
        GetByUser,
        Update,
        Delete,
        DeleteMultiple,
        VerifyForUserWithDb,
    )
)]
#[cfg_attr(feature = "full", table_name = "platform_credential")]
#[cfg_attr(feature = "full", belongs_to(User))]
#[cfg_attr(feature = "full", belongs_to(Platform))]
pub struct PlatformCredential {
    pub id: PlatformCredentialId,
    pub user_id: UserId,
    pub platform_id: PlatformId,
    pub username: String,
    pub password: String,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "full", derive(Insertable, VerifyForUserWithoutDb))]
#[cfg_attr(feature = "full", table_name = "platform_credential")]
pub struct NewPlatformCredential {
    pub user_id: UserId,
    pub platform_id: PlatformId,
    pub username: String,
    pub password: String,
}
