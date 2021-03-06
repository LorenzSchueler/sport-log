use chrono::{DateTime, Utc};
#[cfg(feature = "server")]
use rocket::http::Status;
use serde::{Deserialize, Serialize};

use sport_log_types_derive::{FromI64, ToI64};
#[cfg(feature = "server")]
use sport_log_types_derive::{FromSql, GetById, GetByIds, ToSql, VerifyUnchecked};

use crate::{from_str, to_str};
#[cfg(feature = "server")]
use crate::{schema::user, AuthUser, CheckUserId, Unverified, VerifyForUserWithDb};

#[derive(
    Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq, PartialOrd, Ord, FromI64, ToI64,
)]
#[cfg_attr(
    feature = "server",
    derive(Hash, FromSqlRow, AsExpression, ToSql, FromSql)
)]
#[cfg_attr(feature = "server", sql_type = "diesel::sql_types::BigInt")]
pub struct UserId(pub i64);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "server",
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
#[cfg_attr(feature = "server", table_name = "user")]
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

#[cfg(feature = "server")]
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
