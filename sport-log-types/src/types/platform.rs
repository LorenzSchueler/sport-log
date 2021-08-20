use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

#[cfg(feature = "full")]
use sport_log_types_derive::{
    CheckUserId, Create, CreateMultiple, FromSql, GetAll, GetById, GetByIds, GetBySync, GetByUser,
    GetByUserSync, ToSql, Update, VerifyForAdminWithoutDb, VerifyForUserWithDb,
    VerifyForUserWithoutDb, VerifyIdForAdmin, VerifyIdForUser, VerifyIdUnchecked, VerifyUnchecked,
};
use sport_log_types_derive::{FromI64, ToI64};

use crate::{from_str, to_str, UserId};
#[cfg(feature = "full")]
use crate::{
    schema::{platform, platform_credential},
    User,
};

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq, FromI64, ToI64)]
#[cfg_attr(
    feature = "full",
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
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::BigInt")]
pub struct PlatformId(pub i64);

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
        GetAll,
        GetBySync,
        Update,
        VerifyForAdminWithoutDb,
        VerifyUnchecked
    )
)]
#[cfg_attr(feature = "full", table_name = "platform")]
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
    feature = "full",
    derive(Hash, FromSqlRow, AsExpression, ToSql, FromSql, VerifyIdForUser)
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::BigInt")]
pub struct PlatformCredentialId(pub i64);

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
        VerifyForUserWithDb,
        VerifyForUserWithoutDb
    )
)]
#[cfg_attr(feature = "full", table_name = "platform_credential")]
#[cfg_attr(feature = "full", belongs_to(User))]
#[cfg_attr(feature = "full", belongs_to(Platform))]
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
