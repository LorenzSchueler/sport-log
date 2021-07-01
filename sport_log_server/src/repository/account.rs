use diesel::prelude::*;

use crate::{
    model::{Account, AccountId, NewAccount},
    schema::account,
};

pub fn create_account(account: NewAccount, conn: &PgConnection) -> QueryResult<Account> {
    diesel::insert_into(account::table)
        .values(account)
        .get_result(conn)
}

pub fn get_accounts(conn: &PgConnection) -> QueryResult<Vec<Account>> {
    account::table.load(conn)
}

pub fn get_account(account_id: AccountId, conn: &PgConnection) -> QueryResult<Account> {
    account::table.find(account_id).get_result(conn)
}

pub fn update_account(
    account_id: AccountId,
    account: Account,
    conn: &PgConnection,
) -> QueryResult<Account> {
    diesel::update(account::table.find(account_id))
        .set(&account)
        .get_result(conn)
}

pub fn delete_account(account_id: AccountId, connection: &PgConnection) -> QueryResult<usize> {
    diesel::delete(account::table.find(account_id)).execute(connection)
}
