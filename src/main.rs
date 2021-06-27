#![feature(decl_macro, proc_macro_hygiene)]
#[macro_use]
extern crate diesel;
#[macro_use]
extern crate rocket;

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
                account::create_account,
                account::get_accounts,
                account::get_account,
                account::update_account,
                account::delete_account
            ],
        )
        .mount(
            "/v1/platform_credentials",
            routes![
                platform_credentials::create_platform_credentials,
                platform_credentials::get_own_platform_credentials,
                platform_credentials::get_own_platform_credentials_by_platform,
                platform_credentials::update_platform_credentials,
                platform_credentials::delete_platform_credentials
            ],
        )
        .launch();
}
