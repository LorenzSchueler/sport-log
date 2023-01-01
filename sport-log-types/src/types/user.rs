#[cfg(feature = "server")]
use axum::http::StatusCode;
use chrono::{DateTime, Utc};
#[cfg(feature = "server")]
use diesel::sql_types::BigInt;
use serde::{Deserialize, Serialize};
#[cfg(feature = "server")]
use sport_log_types_derive::{
    GetById, GetByIds, IdFromSql, IdToSql, VerifyForAdminWithoutDb, VerifyUnchecked,
};

#[cfg(feature = "server")]
use crate::{schema::user, AuthUser, CheckUserId, Unverified, VerifyForUserWithDb};

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq, PartialOrd, Ord)]
#[serde(transparent)]
#[cfg_attr(
    feature = "server",
    derive(Hash, FromSqlRow, AsExpression, IdToSql, IdFromSql),
    diesel(sql_type = BigInt)
)]
pub struct UserId(pub i64);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "server",
    derive(
        Insertable,
        Identifiable,
        Queryable,
        AsChangeset,
        GetById,
        GetByIds,
        VerifyUnchecked,
        VerifyForAdminWithoutDb,
    ),
    diesel(table_name = user)
)]
pub struct User {
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

    fn verify_user(
        self,
        auth: AuthUser,
        db: &mut PgConnection,
    ) -> Result<Self::Entity, StatusCode> {
        let user = self.0;
        if user.id == *auth
            && User::check_user_id(user.id, *auth, db)
                .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(user)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}
