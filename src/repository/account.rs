use super::*;
use crate::schema::account::{columns, table as account};

pub fn create_account(new_account: NewAccount, conn: &PgConnection) -> QueryResult<Account> {
    diesel::insert_into(account)
        .values(new_account)
        .get_result(conn)
}

pub fn get_accounts(conn: &PgConnection) -> QueryResult<Vec<Account>> {
    account.load(conn)
}

pub fn get_account(account_id: i32, conn: &PgConnection) -> QueryResult<Account> {
    account.find(account_id).get_result(conn)
}

pub fn update_account(
    account_id: i32,
    new_account: Account,
    conn: &PgConnection,
) -> QueryResult<Account> {
    diesel::update(account.find(account_id))
        .set(&new_account)
        .get_result(conn)
}

pub fn delete_account(account_id: i32, connection: &PgConnection) -> QueryResult<usize> {
    diesel::delete(account.find(account_id)).execute(connection)
}
