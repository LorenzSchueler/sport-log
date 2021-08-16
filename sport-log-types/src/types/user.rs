use chrono::{DateTime, Utc};
#[cfg(feature = "full")]
use rocket::http::Status;
use serde::{Deserialize, Serialize};

#[cfg(feature = "full")]
use sport_log_types_derive::{FromI64, FromSql, GetById, GetByIds, ToI64, ToSql, VerifyUnchecked};

use crate::{from_str, to_str};
#[cfg(feature = "full")]
use crate::{schema::user, AuthUser, CheckUserId, Unverified, VerifyForUserWithDb};

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq)]
#[cfg_attr(
    feature = "full",
    derive(Hash, FromSqlRow, AsExpression, FromI64, ToI64, ToSql, FromSql)
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::BigInt")]
pub struct UserId(pub i64);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(
        Insertable,
        Associations,
        Identifiable,
        Queryable,
        AsChangeset,
        GetById,
        GetByIds,
        VerifyUnchecked,
    )
)]
#[cfg_attr(feature = "full", table_name = "user")]
pub struct User {
    #[serde(serialize_with = "to_str")]
    #[serde(deserialize_with = "from_str")]
    pub id: UserId,
    pub username: String,
    pub password: String,
    pub email: String,
    #[serde(skip)]
    #[serde(default = "Utc::now")]
    pub last_change: DateTime<Utc>,
}

#[cfg(feature = "full")]
impl VerifyForUserWithDb for Unverified<User> {
    type Entity = User;

    fn verify_user(self, auth: &AuthUser, conn: &PgConnection) -> Result<Self::Entity, Status> {
        let user = self.0.into_inner();
        if user.id == **auth
            && User::check_user_id(user.id, **auth, conn)
                .map_err(|_| Status::InternalServerError)?
        {
            Ok(user)
        } else {
            Err(Status::Forbidden)
        }
    }
}
