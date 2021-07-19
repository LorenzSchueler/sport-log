use rocket::http::Status;
use serde::{Deserialize, Serialize};

use sport_log_server_derive::{
    Create, Delete, GetAll, GetById, InnerIntFromSql, InnerIntToSql, Update,
};

#[cfg(feature = "full")]
use crate::{
    schema::user,
    types::{AuthenticatedUser, Unverified},
};

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
pub struct UserId(pub i32);

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
        GetAll,
        Update,
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
impl Unverified<User> {
    pub fn verify(self, auth: &AuthenticatedUser, conn: &PgConnection) -> Result<User, Status> {
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

#[cfg_attr(feature = "full", derive(Insertable, Serialize, Deserialize))]
#[cfg_attr(feature = "full", table_name = "user")]
pub struct NewUser {
    pub username: String,
    pub password: String,
    pub email: String,
}

#[cfg(feature = "full")]
impl Unverified<NewUser> {
    pub fn verify(self) -> Result<NewUser, Status> {
        Ok(self.0.into_inner())
    }
}
