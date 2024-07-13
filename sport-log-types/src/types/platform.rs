use derive_deftly::Deftly;
#[cfg(feature = "db")]
use diesel::{deserialize::FromSqlRow, expression::AsExpression, prelude::*, sql_types::BigInt};
use serde::{Deserialize, Serialize};

#[cfg(feature = "db")]
use crate::{
    schema::{platform, platform_credential},
    User,
};
use crate::{types::IdString, UserId};

#[derive(Serialize, Deserialize, Debug, Clone, Copy, PartialEq, Eq, Deftly)]
#[derive_deftly(IdString)]
#[serde(try_from = "IdString", into = "IdString")]
#[cfg_attr(
    feature = "db",
    derive(Hash, FromSqlRow, AsExpression),
    derive_deftly(IdToSql, IdFromSql),
    diesel(sql_type = BigInt)
)]
pub struct PlatformId(pub i64);

/// A representation for an external resource for which [`ActionProvider`](crate::ActionProvider)
/// can provide [`Actions`](crate::Action).
///
/// `credential` is true if the external resource is only useable with credentials which the
/// [`User`](crate::User) has to supply as [`PlatformCredential`].
///
/// If `credential` is false the resource can be accessed without credentials. (This is f.ex. the
/// case if the data if fetched from public websites or only data from **Sport Log** is used.)
#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "db",
    derive(
        Insertable,
        Identifiable,
        Queryable,
        Selectable,
        AsChangeset,
    ),
    diesel(table_name = platform)
)]
pub struct Platform {
    pub id: PlatformId,
    pub name: String,
    pub credential: bool,
    pub deleted: bool,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, PartialEq, Eq, Deftly)]
#[derive_deftly(IdString)]
#[serde(try_from = "IdString", into = "IdString")]
#[cfg_attr(
    feature = "db",
    derive(Hash, FromSqlRow, AsExpression),
    derive_deftly(IdToSql, IdFromSql),
    diesel(sql_type = BigInt)
)]
pub struct PlatformCredentialId(pub i64);

/// Credentials of a [`User`](crate::User) for a [`Platform`].
///
/// [`PlatformCredential`] are needed for [`Platforms`](Platform) where `credential` is true.
#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "db",
    derive(
        Insertable,
        Associations,
        Identifiable,
        Queryable,
        Selectable,
        AsChangeset,
    ),
    diesel(table_name = platform_credential, belongs_to(User), belongs_to(Platform))
)]
pub struct PlatformCredential {
    pub id: PlatformCredentialId,
    pub user_id: UserId,
    pub platform_id: PlatformId,
    pub username: String,
    pub password: String,
    pub deleted: bool,
}
