use serde::{Deserialize, Serialize};

use sport_log_server_derive::{
    Create, Delete, GetAll, GetById, InnerIntFromParam, InnerIntFromSql, InnerIntToSql, Update,
    VerifyForAdminWithoutDb, VerifyForUserWithDb, VerifyForUserWithoutDb, VerifyIdForAdmin,
    VerifyIdForUser, VerifyIdForUserUnchecked,
};

use crate::{
    schema::{platform, platform_credentials},
    types::UserId,
};

#[derive(
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
)]
#[sql_type = "diesel::sql_types::Integer"]
pub struct PlatformId(pub i32);

#[derive(InnerIntFromParam, VerifyIdForAdmin, VerifyIdForUserUnchecked)]
pub struct UnverifiedPlatformId(i32);

#[derive(
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
)]
#[table_name = "platform"]
pub struct Platform {
    pub id: PlatformId,
    pub name: String,
}

#[derive(Insertable, Serialize, Deserialize, VerifyForAdminWithoutDb)]
#[table_name = "platform"]
pub struct NewPlatform {
    pub name: String,
}

#[derive(
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
)]
#[sql_type = "diesel::sql_types::Integer"]
pub struct PlatformCredentialsId(pub i32);

#[derive(InnerIntFromParam, VerifyIdForUser)]
pub struct UnverifiedPlatformCredentialsId(i32);

#[derive(
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
)]
#[table_name = "platform_credentials"]
pub struct PlatformCredentials {
    pub id: PlatformCredentialsId,
    pub user_id: UserId,
    pub platform_id: PlatformId,
    pub username: String,
    pub password: String,
}

#[derive(Insertable, Serialize, Deserialize, VerifyForUserWithoutDb)]
#[table_name = "platform_credentials"]
pub struct NewPlatformCredentials {
    pub user_id: UserId,
    pub platform_id: PlatformId,
    pub username: String,
    pub password: String,
}
