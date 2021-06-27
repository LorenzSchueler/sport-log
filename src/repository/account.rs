use super::*;

pub fn create_account(new_account: NewAccount, conn: &PgConnection) -> QueryResult<Account> {
    diesel::insert_into(account)
        .values(&new_account)
        .get_result(conn)
}

pub fn get_accounts(connection: &PgConnection) -> QueryResult<Vec<Account>> {
    account.load(&*connection)
}

pub fn get_account(account_id: i32, connection: &PgConnection) -> QueryResult<Account> {
    account.find(account_id).get_result(connection)
}

pub fn update_account(
    account_id: i32,
    new_account: Account,
    connection: &PgConnection,
) -> QueryResult<Account> {
    diesel::update(account.find(account_id))
        .set(&new_account)
        .get_result(connection)
}

pub fn delete_account(account_id: i32, connection: &PgConnection) -> QueryResult<usize> {
    diesel::delete(account.find(account_id)).execute(connection)
}
