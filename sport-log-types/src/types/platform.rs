use serde::{Deserialize, Serialize};

#[cfg(feature = "full")]
use sport_log_server_derive::{
    Create, Delete, GetAll, GetById, InnerIntFromParam, InnerIntFromSql, InnerIntToSql, Update,
    VerifyForAdminWithoutDb, VerifyForUserWithDb, VerifyForUserWithoutDb, VerifyIdForAdmin,
    VerifyIdForUser, VerifyIdForUserUnchecked,
};

#[cfg(feature = "full")]
use crate::schema::{platform, platform_credentials};
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
pub struct PlatformId(pub i32);

#[cfg(feature = "full")]
#[derive(InnerIntFromParam, VerifyIdForAdmin, VerifyIdForUserUnchecked)]
pub struct UnverifiedPlatformId(i32);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(
        Queryable,
        AsChangeset,
        Create,
        GetAll,
        Update,
        Delete,
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
pub struct PlatformCredentialsId(pub i32);

#[cfg(feature = "full")]
#[derive(InnerIntFromParam, VerifyIdForUser)]
pub struct UnverifiedPlatformCredentialsId(i32);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(
        Queryable,
        AsChangeset,
        Create,
        GetById,
        Update,
        Delete,
        VerifyForUserWithDb,
    )
)]
#[cfg_attr(feature = "full", table_name = "platform_credentials")]
pub struct PlatformCredentials {
    pub id: PlatformCredentialsId,
    pub user_id: UserId,
    pub platform_id: PlatformId,
    pub username: String,
    pub password: String,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "full", derive(Insertable, VerifyForUserWithoutDb))]
#[cfg_attr(feature = "full", table_name = "platform_credentials")]
pub struct NewPlatformCredentials {
    pub user_id: UserId,
    pub platform_id: PlatformId,
    pub username: String,
    pub password: String,
}
