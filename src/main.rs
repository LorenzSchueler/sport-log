#![feature(decl_macro, proc_macro_hygiene)]
#[macro_use]
extern crate diesel;
#[macro_use]
extern crate rocket;
#[macro_use]
extern crate serde_derive;

use diesel::pg::PgConnection;
use dotenv::dotenv;
use rocket_contrib::databases::database;

mod handler;
mod model;
mod repository;
mod schema;

#[database("sport_diary")]
pub struct Db(PgConnection);

//#[launch]
pub fn main() {
    dotenv().ok();

    use handler::*;
    rocket::ignite()
        .attach(Db::fairing())
        .mount(
            "/v1/account",
            routes![
                account::get_accounts,
                account::create_account,
                account::get_account,
                account::update_account,
                account::delete_account
            ],
        )
        .launch();
}
