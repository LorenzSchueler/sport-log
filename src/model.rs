use crate::schema::*;

#[derive(Queryable, AsChangeset, Serialize, Deserialize, Debug)]
#[table_name = "account"]
pub struct Account {
    pub id: i32,
    pub username: String,
    pub password: String,
    pub email: String,
}

#[derive(Insertable, Serialize, Deserialize)]
#[table_name = "account"]
pub struct NewAccount {
    pub username: String,
    pub password: String,
    pub email: String,
}
