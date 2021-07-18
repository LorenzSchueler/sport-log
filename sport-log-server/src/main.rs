use std::fs;

#[macro_use]
extern crate diesel;
#[macro_use]
extern crate rocket;

use diesel::pg::PgConnection;
use dotenv::dotenv;
use lazy_static::lazy_static;
use rocket_sync_db_pools::database;
use serde::Deserialize;

mod auth;
mod handler;
mod types;
mod repository;
mod schema;

#[derive(Deserialize)]
pub struct Config {
    pub admin_username: String,
    pub admin_password: String,
}

impl Config {
    pub fn get() -> Self {
        toml::from_str(&fs::read_to_string("config.toml").unwrap()).unwrap()
    }
}

lazy_static! {
    static ref CONFIG: Config = Config::get();
}

const BASE: &str = "/v1";

#[database("sport_diary")]
pub struct Db(PgConnection);

#[launch]
fn rocket() -> _ {
    dotenv().ok();

    use handler::*;
    rocket::build().attach(Db::fairing()).mount(
        BASE,
        routes![
            user::create_user,
            user::get_user,
            user::update_user,
            user::delete_user,
            platform::create_platform,
            platform::get_platforms,
            platform::get_platforms_u,
            platform::update_platform,
            platform::delete_platform,
            platform::create_platform_credentials,
            platform::get_own_platform_credentials,
            platform::get_own_platform_credentials_by_platform,
            platform::update_platform_credentials,
            platform::delete_platform_credentials,
            action::create_action_provider,
            action::get_action_providers,
            action::delete_action_provider,
            action::create_action,
            action::get_action,
            action::get_actions_by_action_provider,
            action::get_actions,
            action::delete_action,
            action::create_action_rule,
            action::get_action_rule,
            action::get_action_rules_by_user,
            action::get_action_rules_by_user_and_action_provider,
            action::update_action_rule,
            action::delete_action_rule,
            action::create_action_event,
            action::get_action_event,
            action::get_action_events_by_user,
            action::get_action_events_by_action_provider,
            action::get_action_events_by_user_and_action_provider,
            action::update_action_event,
            action::delete_action_event,
            action::delete_action_event_ap,
            action::get_executable_action_events_by_action_provider,
            action::get_executable_action_events_by_action_provider_and_timerange,
            diary_wod::create_wod,
            diary_wod::create_wod_ap,
            diary_wod::get_wods_by_user,
            diary_wod::update_wod,
            diary_wod::delete_wod,
        ],
    )
}
