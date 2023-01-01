use chrono::{DateTime, Utc};
#[cfg(feature = "server")]
use diesel::sql_types::BigInt;
use serde::{Deserialize, Serialize};
#[cfg(feature = "server")]
use sport_log_types_derive::{
    CheckUserId, Create, GetAll, GetById, GetByIds, GetBySync, GetByUser, GetByUserSync,
    HardDelete, IdFromSql, IdToSql, Update, VerifyForAdminWithoutDb, VerifyForUserWithDb,
    VerifyForUserWithoutDb, VerifyIdForAdmin, VerifyIdForUser, VerifyIdUnchecked, VerifyUnchecked,
};

use crate::UserId;
#[cfg(feature = "server")]
use crate::{
    schema::{platform, platform_credential},
    User,
};

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq, PartialOrd, Ord)]
#[serde(transparent)]
#[cfg_attr(
    feature = "server",
    derive(
        Hash,
        FromSqlRow,
        AsExpression,
        IdToSql,
        IdFromSql,
        VerifyIdForAdmin,
        VerifyIdUnchecked
    ),
    diesel(sql_type = BigInt)
)]
pub struct PlatformId(pub i64);

/// A representation for an external resource for which [ActionProvider](crate::ActionProvider) can provide [Actions](crate::Action).
///
/// `credential` is true if the external resource is only useable with credentials which the [User](crate::User) has to supply as [PlatformCredential].
///
/// If `credential` is false the resource can be accessed without credentials. (This is f.ex. the case if the data if fetched from public websites or only data from **Sport Log** is used.)
#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "server",
    derive(
        Insertable,
        Identifiable,
        Queryable,
        AsChangeset,
        Create,
        GetAll,
        GetById,
        GetBySync,
        Update,
        HardDelete,
        VerifyForAdminWithoutDb,
        VerifyUnchecked
    ),
    diesel(table_name = platform)
)]
pub struct Platform {
    pub id: PlatformId,
    pub name: String,
    pub credential: bool,
    #[serde(skip)]
    #[serde(default = "Utc::now")]
    pub last_change: DateTime<Utc>,
    pub deleted: bool,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq, PartialOrd, Ord)]
#[serde(transparent)]
#[cfg_attr(
    feature = "server",
    derive(Hash, FromSqlRow, AsExpression, IdToSql, IdFromSql, VerifyIdForUser),
    diesel(sql_type = BigInt)
)]
pub struct PlatformCredentialId(pub i64);

/// Credentials of a [User](crate::User) for a [Platform].
///
/// [PlatformCredential] are needed for [Platforms](Platform) where `credential` is true.
#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "server",
    derive(
        Insertable,
        Associations,
        Identifiable,
        Queryable,
        AsChangeset,
        Create,
        GetById,
        GetByIds,
        GetByUser,
        GetByUserSync,
        Update,
        HardDelete,
        CheckUserId,
        VerifyForUserWithDb,
        VerifyForUserWithoutDb
    ),
    diesel(table_name = platform_credential, belongs_to(User), belongs_to(Platform))
)]
pub struct PlatformCredential {
    pub id: PlatformCredentialId,
    pub user_id: UserId,
    pub platform_id: PlatformId,
    pub username: String,
    pub password: String,
    #[serde(skip)]
    #[serde(default = "Utc::now")]
    pub last_change: DateTime<Utc>,
    pub deleted: bool,
}
