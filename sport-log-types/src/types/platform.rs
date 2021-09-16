use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

#[cfg(feature = "server")]
use sport_log_types_derive::{
    CheckUserId, Create, CreateMultiple, FromSql, GetAll, GetById, GetByIds, GetBySync, GetByUser,
    GetByUserSync, ToSql, Update, VerifyForAdminWithoutDb, VerifyForUserWithDb,
    VerifyForUserWithoutDb, VerifyIdForAdmin, VerifyIdForUser, VerifyIdUnchecked, VerifyUnchecked,
};
use sport_log_types_derive::{FromI64, ToI64};

use crate::{from_str, to_str, UserId};
#[cfg(feature = "server")]
use crate::{
    schema::{platform, platform_credential},
    User,
};

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq, FromI64, ToI64)]
#[cfg_attr(
    feature = "server",
    derive(
        Hash,
        FromSqlRow,
        AsExpression,
        ToSql,
        FromSql,
        VerifyIdForAdmin,
        VerifyIdUnchecked
    )
)]
#[cfg_attr(feature = "server", sql_type = "diesel::sql_types::BigInt")]
pub struct PlatformId(pub i64);

/// A represantation for an external resource for which [ActionProvider](crate::ActionProvider) can provide [Actions](crate::Action).
///
/// `credential` is true if the external resource is only useable with credentials which the [User](crate::User) has to supply as [PlatformCredential].
///
/// If `credential` is false the resource can be accessed without credentials. (This is f.ex. the case if the data if fetched from public websites or only data from **Sport Log** is used.)
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
        CreateMultiple,
        GetAll,
        GetBySync,
        Update,
        VerifyForAdminWithoutDb,
        VerifyUnchecked
    )
)]
#[cfg_attr(feature = "server", table_name = "platform")]
pub struct Platform {
    #[serde(serialize_with = "to_str")]
    #[serde(deserialize_with = "from_str")]
    pub id: PlatformId,
    pub name: String,
    pub credential: bool,
    #[serde(skip)]
    #[serde(default = "Utc::now")]
    pub last_change: DateTime<Utc>,
    pub deleted: bool,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq, FromI64, ToI64)]
#[cfg_attr(
    feature = "server",
    derive(Hash, FromSqlRow, AsExpression, ToSql, FromSql, VerifyIdForUser)
)]
#[cfg_attr(feature = "server", sql_type = "diesel::sql_types::BigInt")]
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
        CreateMultiple,
        GetById,
        GetByIds,
        GetByUser,
        GetByUserSync,
        Update,
        CheckUserId,
        VerifyForUserWithDb,
        VerifyForUserWithoutDb
    )
)]
#[cfg_attr(feature = "server", table_name = "platform_credential")]
#[cfg_attr(feature = "server", belongs_to(User))]
#[cfg_attr(feature = "server", belongs_to(Platform))]
pub struct PlatformCredential {
    #[serde(serialize_with = "to_str")]
    #[serde(deserialize_with = "from_str")]
    pub id: PlatformCredentialId,
    #[serde(serialize_with = "to_str")]
    #[serde(deserialize_with = "from_str")]
    pub user_id: UserId,
    #[serde(serialize_with = "to_str")]
    #[serde(deserialize_with = "from_str")]
    pub platform_id: PlatformId,
    pub username: String,
    pub password: String,
    #[serde(skip)]
    #[serde(default = "Utc::now")]
    pub last_change: DateTime<Utc>,
    pub deleted: bool,
}
