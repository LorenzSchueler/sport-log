#![feature(decl_macro, proc_macro_hygiene)]
#[macro_use]
extern crate diesel;
#[macro_use]
extern crate rocket;

use diesel::pg::PgConnection;
use dotenv::dotenv;
use rocket_contrib::databases::database;

mod auth;
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
                platform::create_platform,
                platform::get_platforms,
                platform::update_platform,
                platform::delete_platform,
                platform::create_platform_credentials,
                platform::get_own_platform_credentials,
                platform::get_own_platform_credentials_by_platform,
                platform::update_platform_credentials,
                platform::delete_platform_credentials,
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
                action::delete_action_rule,
                action::create_action_event,
                action::get_action_event,
                action::get_action_events_by_account,
                action::get_action_events_by_platform,
                action::get_action_events_by_platform_name,
                action::get_action_events_by_account_and_platform,
                action::update_action_event,
                action::delete_action_event,
                action::get_executable_action_events_by_platform_name,
                action::get_executable_action_events_by_platform_name_and_timerange
            ],
        )
        .launch();
}
// http://username:password@host
