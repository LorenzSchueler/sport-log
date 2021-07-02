use super::*;
use crate::model::{Account, AccountId, NewAccount};

#[post("/account", format = "application/json", data = "<account>")]
pub fn create_account(account: Json<NewAccount>, conn: Db) -> Result<Json<Account>, Status> {
    to_json(Account::create(account.into_inner(), &conn))
}

#[get("/account")]
pub fn get_accounts(conn: Db) -> Result<Json<Vec<Account>>, Status> {
    to_json(Account::get_all(&conn))
}

#[get("/account/<account_id>")]
pub fn get_account(account_id: AccountId, conn: Db) -> Result<Json<Account>, Status> {
    to_json(Account::get_by_id(account_id, &conn))
}

#[put(
    "/account/<account_id>",
    format = "application/json",
    data = "<account>"
)]
pub fn update_account(
    account_id: AccountId,
    account: Json<Account>,
    conn: Db,
) -> Result<Json<Account>, Status> {
    to_json(Account::update(account_id, account.into_inner(), &conn))
}

#[delete("/account/<account_id>")]
pub fn delete_account(account_id: AccountId, conn: Db) -> Result<Status, Status> {
    Account::delete(account_id, &conn)
        .map(|_| Status::NoContent)
        .map_err(|_| Status::InternalServerError)
}
