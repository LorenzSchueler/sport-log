//use diesel::prelude::*;

//use crate::{
//model::{Account, AccountId, NewAccount},
//schema::account,
//};

//impl Account {
//pub fn create(account: NewAccount, conn: &PgConnection) -> QueryResult<Account> {
//diesel::insert_into(account::table)
//.values(account)
//.get_result(conn)
//}

//pub fn get_all(conn: &PgConnection) -> QueryResult<Vec<Account>> {
//account::table.load(conn)
//}

//pub fn get_by_id(account_id: AccountId, conn: &PgConnection) -> QueryResult<Account> {
//account::table.find(account_id).get_result(conn)
//}

//pub fn update(
//account_id: AccountId,
//account: Account,
//conn: &PgConnection,
//) -> QueryResult<Account> {
//diesel::update(account::table.find(account_id))
//.set(&account)
//.get_result(conn)
//}

//pub fn delete(account_id: AccountId, connection: &PgConnection) -> QueryResult<usize> {
//diesel::delete(account::table.find(account_id)).execute(connection)
//}
//}
