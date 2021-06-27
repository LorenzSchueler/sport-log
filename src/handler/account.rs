use super::*;
use repo::account;

#[post("/", format = "application/json", data = "<new_account>")]
pub fn create_account(new_account: Json<NewAccount>, conn: Db) -> Result<Json<Account>, Status> {
    to_json(account::create_account(new_account.into_inner(), &conn))
}

#[get("/")]
pub fn get_accounts(conn: Db) -> Result<Json<Vec<Account>>, Status> {
    to_json(account::get_accounts(&conn))
}

#[get("/<id>")]
pub fn get_account(id: i32, conn: Db) -> Result<Json<Account>, Status> {
    to_json(account::get_account(id, &conn))
}

#[put("/<id>", format = "application/json", data = "<account>")]
pub fn update_account(id: i32, account: Json<Account>, conn: Db) -> Result<Json<Account>, Status> {
    to_json(account::update_account(id, account.into_inner(), &conn))
}

#[delete("/<id>")]
pub fn delete_account(id: i32, conn: Db) -> Result<Status, Status> {
    account::delete_account(id, &conn)
        .map(|_| Status::NoContent)
        .map_err(|_| Status::InternalServerError)
}
