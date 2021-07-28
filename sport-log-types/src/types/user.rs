#[cfg(feature = "full")]
use rocket::http::Status;
use serde::{Deserialize, Serialize};

#[cfg(feature = "full")]
use sport_log_types_derive::{Delete, FromI32, FromSql, GetAll, GetById, ToSql};

#[cfg(feature = "full")]
use crate::{
    schema::user,
    types::{AuthenticatedUser, GetById, Unverified, VerifyForUserWithDb},
};

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq)]
#[cfg_attr(
    feature = "full",
    derive(Hash, FromSqlRow, AsExpression, FromI32, ToSql, FromSql)
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::Integer")]
pub struct UserId(pub i32);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(
        Associations,
        Identifiable,
        Queryable,
        AsChangeset,
        GetById,
        GetAll,
        Delete,
    )
)]
#[cfg_attr(feature = "full", table_name = "user")]
pub struct User {
    pub id: UserId,
    pub username: String,
    pub password: String,
    pub email: String,
}

#[cfg(feature = "full")]
impl VerifyForUserWithDb<User> for Unverified<User> {
    fn verify(self, auth: &AuthenticatedUser, conn: &PgConnection) -> Result<User, Status> {
        let entity = self.0.into_inner();
        if entity.id == **auth
            && User::get_by_id(entity.id, conn)
                .map_err(|_| Status::InternalServerError)?
                .id
                == **auth
        {
            Ok(entity)
        } else {
            Err(Status::Forbidden)
        }
    }
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "full", derive(Insertable))]
#[cfg_attr(feature = "full", table_name = "user")]
pub struct NewUser {
    pub username: String,
    pub password: String,
    pub email: String,
}

#[cfg(feature = "full")]
impl Unverified<NewUser> {
    pub fn verify_unchecked(self) -> Result<NewUser, Status> {
        Ok(self.0.into_inner())
    }
}
