use super::*;
use repo::account;

#[get("/")]
pub fn get_accounts(connection: Db) -> Result<Json<Vec<Account>>, Status> {
    account::get_accounts(&connection)
        .map(Json)
        .map_err(|_| Status::InternalServerError)
}

#[post("/", format = "application/json", data = "<new_account>")]
pub fn create_account(
    new_account: Json<NewAccount>,
    connection: Db,
) -> Result<Json<Account>, Status> {
    account::create_account(new_account.into_inner(), &connection)
        .map(Json)
        .map_err(|_| Status::InternalServerError)
}

#[get("/<id>")]
pub fn get_account(id: i32, connection: Db) -> Result<Json<Account>, Status> {
    account::get_account(id, &connection)
        .map(Json)
        .map_err(|_| Status::InternalServerError)
}

#[put("/<id>", format = "application/json", data = "<account>")]
pub fn update_account(
    id: i32,
    account: Json<Account>,
    connection: Db,
) -> Result<Json<Account>, Status> {
    account::update_account(id, account.into_inner(), &connection)
        .map(Json)
        .map_err(|_| Status::InternalServerError)
}

#[delete("/<id>")]
pub fn delete_account(id: i32, connection: Db) -> Result<Status, Status> {
    account::delete_account(id, &connection)
        .map(|_| Status::NoContent)
        .map_err(|_| Status::InternalServerError)
}
