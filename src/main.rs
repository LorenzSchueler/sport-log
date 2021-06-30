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

const BASE: &str = "/v1";

#[database("sport_diary")]
pub struct Db(PgConnection);

//#[launch]
pub fn main() {
    dotenv().ok();

    use handler::*;
    rocket::ignite()
        .attach(Db::fairing())
        .mount(
            BASE,
            routes![
                account::create_account,
                account::get_accounts,
                account::get_account,
                account::update_account,
                account::delete_account,
                platform_credentials::create_platform_credentials,
                platform_credentials::get_own_platform_credentials,
                platform_credentials::get_own_platform_credentials_by_platform,
                platform_credentials::update_platform_credentials,
                platform_credentials::delete_platform_credentials,
                action::create_action,
                action::get_action,
                action::get_actions_by_platform,
                action::delete_action,
                action::create_action_rule,
                action::get_action_rule,
                action::get_action_rules_by_account,
                action::get_action_rules_by_platform,
                action::get_action_rules_by_account_and_platform,
                action::update_action_rule,
                action::delete_action_rule
            ],
        )
        .launch();
}
