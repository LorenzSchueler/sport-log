use std::io::Write;

use diesel::{
    deserialize,
    pg::Pg,
    serialize::{self, Output},
    sql_types::Integer,
    types::{FromSql, ToSql},
};
use serde::{Deserialize, Serialize};

use sport_log_server_derive::{Create, Delete, GetAll, GetById, Update};

use super::*;
use crate::schema::{platform, platform_credentials};

#[derive(FromSqlRow, AsExpression, Serialize, Deserialize, Debug, Clone, Copy)]
#[sql_type = "diesel::sql_types::Integer"]
pub struct PlatformId(pub i32);

impl ToSql<Integer, Pg> for PlatformId {
    fn to_sql<W: Write>(&self, out: &mut Output<W, Pg>) -> serialize::Result {
        ToSql::<Integer, Pg>::to_sql(&self.0, out)
    }
}

impl FromSql<Integer, Pg> for PlatformId {
    fn from_sql(bytes: Option<&[u8]>) -> deserialize::Result<Self> {
        let id = FromSql::<Integer, Pg>::from_sql(bytes)?;
        Ok(PlatformId(id))
    }
}

#[derive(Queryable, AsChangeset, Serialize, Deserialize, Debug, Create, GetAll, Update, Delete)]
#[table_name = "platform"]
pub struct Platform {
    pub id: PlatformId,
    pub name: String,
}

#[derive(Insertable, Serialize, Deserialize)]
#[table_name = "platform"]
pub struct NewPlatform {
    pub name: String,
}

pub type PlatformCredentialsId = i32;

#[derive(
    Queryable, AsChangeset, Serialize, Deserialize, Debug, Create, GetById, Update, Delete,
)]
#[table_name = "platform_credentials"]
pub struct PlatformCredentials {
    pub id: PlatformCredentialsId,
    pub user_id: UserId,
    pub platform_id: PlatformId,
    pub username: String,
    pub password: String,
}

#[derive(Insertable, Serialize, Deserialize)]
#[table_name = "platform_credentials"]
pub struct NewPlatformCredentials {
    pub user_id: UserId,
    pub platform_id: PlatformId,
    pub username: String,
    pub password: String,
}
