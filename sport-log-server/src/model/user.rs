use serde::{Deserialize, Serialize};

use sport_log_server_derive::{
    Create, Delete, GetAll, GetById, InnerIntFromSql, InnerIntToSql, Update,
};

use crate::schema::user;

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
pub struct UserId(pub i32);

#[derive(
    Queryable, AsChangeset, Serialize, Deserialize, Debug, Create, GetById, GetAll, Update, Delete,
)]
#[table_name = "user"]
pub struct User {
    pub id: UserId,
    pub username: String,
    pub password: String,
    pub email: String,
}

impl crate::verification::Unverified<User> {
    pub fn verify(
        self,
        auth: &crate::auth::AuthenticatedUser,
        conn: &diesel::pg::PgConnection,
    ) -> Result<User, rocket::http::Status> {
        let entity = self.0.into_inner();
        if entity.id == **auth
            && User::get_by_id(entity.id, conn)
                .map_err(|_| rocket::http::Status::InternalServerError)?
                .id
                == **auth
        {
            Ok(entity)
        } else {
            Err(rocket::http::Status::Forbidden)
        }
    }
}

#[derive(Insertable, Serialize, Deserialize)]
#[table_name = "user"]
pub struct NewUser {
    pub username: String,
    pub password: String,
    pub email: String,
}

impl crate::verification::Unverified<NewUser> {
    pub fn verify(self) -> Result<NewUser, rocket::http::Status> {
        Ok(self.0.into_inner())
    }
}
