use serde::{Deserialize, Serialize};

use sport_log_server_derive::{
    Create, Delete, GetAll, GetById, InnerIntFromParam, InnerIntFromSql, InnerIntToSql, Update,
    VerifyForAdminWithoutDb, VerifyForUserWithDb, VerifyForUserWithoutDb, VerifyIdForAdmin,
    VerifyIdForUser, VerifyIdForUserUnchecked,
};

#[cfg(feature = "full")]
use crate::schema::{platform, platform_credentials};
use crate::types::UserId;

#[cfg_attr(
    feature = "full",
    derive(
        FromSqlRow,
        AsExpression,
        Serialize,
        Deserialize,
        Debug,
        Clone,
        Copy,
        PartialEq,
        Eq,
        InnerIntToSql,
        InnerIntFromSql,
    )
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::Integer")]
pub struct PlatformId(pub i32);

#[cfg_attr(
    feature = "full",
    derive(InnerIntFromParam, VerifyIdForAdmin, VerifyIdForUserUnchecked)
)]
pub struct UnverifiedPlatformId(i32);

#[cfg_attr(
    feature = "full",
    derive(
        Queryable,
        AsChangeset,
        Serialize,
        Deserialize,
        Debug,
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

#[cfg_attr(
    feature = "full",
    derive(Insertable, Serialize, Deserialize, VerifyForAdminWithoutDb)
)]
#[cfg_attr(feature = "full", table_name = "platform")]
pub struct NewPlatform {
    pub name: String,
}

#[cfg_attr(
    feature = "full",
    derive(
        FromSqlRow,
        AsExpression,
        Serialize,
        Deserialize,
        Debug,
        Clone,
        Copy,
        PartialEq,
        Eq,
        InnerIntToSql,
        InnerIntFromSql,
    )
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::Integer")]
pub struct PlatformCredentialsId(pub i32);

#[cfg_attr(feature = "full", derive(InnerIntFromParam, VerifyIdForUser))]
pub struct UnverifiedPlatformCredentialsId(i32);

#[cfg_attr(
    feature = "full",
    derive(
        Queryable,
        AsChangeset,
        Serialize,
        Deserialize,
        Debug,
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

#[cfg_attr(
    feature = "full",
    derive(Insertable, Serialize, Deserialize, VerifyForUserWithoutDb)
)]
#[cfg_attr(feature = "full", table_name = "platform_credentials")]
pub struct NewPlatformCredentials {
    pub user_id: UserId,
    pub platform_id: PlatformId,
    pub username: String,
    pub password: String,
}
