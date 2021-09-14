//! Central server for **Sport Log**.
//!
//! **Sport Log Server** is a multi-user server backend which stores user data and provides synchonization.
//!
//! # Usage
//!
//! **Sport Log Server** should be started at system startup, perferably as a systemd service.
//! It listens on port 8000 for HTTP request.
//! It is highly recommended to use an HTTP server linke apache or nginx and configure it as a reverse proxy.
//! Make sure only connections via HTTPS are allowed since otherwise you data will be send in clear text.
//!
//! # Config
//!
//! The config file must be called `sport-log-server-config.toml`, supports configuration of different profiles and must at least contain all fields of [Config](sport_log_types::Config).
//! Additionally it can also be used to configure the webserver itself. Please refer to [rocket::config].

use std::env;

#[macro_use]
extern crate rocket;

use figment::{
    providers::{Format, Toml},
    Figment,
};
use rocket::{
    fairing::{AdHoc, Fairing, Info, Kind},
    http::{Header, Method, Status},
    Request, Response,
};

use sport_log_types::{Config, Db};

mod handler;
#[cfg(test)]
mod tests;

use handler::JsonError;

const BASE: &str = "/v1";

#[catch(default)]
fn default_catcher(status: Status, _request: &Request) -> JsonError {
    JsonError {
        status,
        message: None,
    }
}

// TODO only send preflight if route exists
#[catch(404)]
fn catcher_404(status: Status, request: &Request) -> Result<Status, JsonError> {
    if request.method() == Method::Options {
        Ok(Status::NoContent)
    } else {
        Err(JsonError {
            status,
            message: None,
        })
    }
}

pub struct CORS;

#[rocket::async_trait]
impl Fairing for CORS {
    fn info(&self) -> Info {
        Info {
            name: "CORS headers",
            kind: Kind::Response,
        }
    }

    async fn on_response<'r>(&self, _request: &'r Request<'_>, response: &mut Response<'r>) {
        response.set_header(Header::new("Access-Control-Allow-Origin", "*"));
        response.set_header(Header::new(
            "Access-Control-Allow-Methods",
            "POST, GET, PUT, DELETE, OPTIONS",
        ));
        response.set_header(Header::new("Access-Control-Allow-Headers", "*"));
        response.set_header(Header::new("Access-Control-Allow-Credentials", "true"));
        response.set_header(Header::new("Access-Control-Max-Age", "864000"));
    }
}

#[launch]
fn rocket() -> _ {
    let figment = Figment::from(rocket::Config::default())
        .merge(Toml::file("sport-log-server-config.toml").nested());
    if cfg!(test) {
        env::set_var("RUST_LOG", "error");
    } else if figment.profile() == "debug" {
        env::set_var("RUST_LOG", "info,sport_log_server=debug");
    } else {
        env::set_var("RUST_LOG", "warn");
    }
    tracing_subscriber::fmt::try_init().unwrap_or(());

    use handler::*;
    rocket::custom(figment)
        .attach(AdHoc::config::<Config>())
        .attach(Db::fairing())
        .attach(CORS)
        .register("/", catchers![default_catcher, catcher_404])
        .mount(
            BASE,
            routes![
                user::adm_create_user,
                platform::adm_create_platform,
                platform::adm_get_platforms,
                platform::adm_update_platform,
                action::adm_create_action_provider,
                action::adm_get_action_providers,
                action::adm_get_creatable_action_rules, // for scheduler
                action::adm_get_deletable_action_events, // for scheduler
                action::adm_create_action_events,       // for scheduler
                action::adm_update_action_event,        // for scheduler
                action::adm_delete_action_events,
                platform::ap_create_platform,
                platform::ap_get_platforms,
                action::ap_create_action_provider,
                action::ap_get_action_provider,
                action::ap_create_action,
                action::ap_create_actions,
                action::ap_get_action,
                action::ap_get_actions,
                action::ap_get_executable_action_events,
                action::ap_get_ordered_executable_action_events_by_timespan,
                action::ap_delete_action_events,
                user::create_user,
                user::get_user,
                user::update_user,
                user::delete_user,
                platform::get_platforms,
                platform::create_platform_credential,
                platform::create_platform_credentials,
                platform::get_platform_credentials,
                platform::get_platform_credentials_by_platform,
                platform::update_platform_credential,
                platform::update_platform_credentials,
                action::get_action_providers,
                action::get_actions,
                action::create_action_rule,
                action::create_action_rules,
                action::get_action_rule,
                action::get_action_rules,
                action::get_action_rules_by_action_provider,
                action::update_action_rule,
                action::update_action_rules,
                action::create_action_event,
                action::create_action_events,
                action::get_action_event,
                action::get_action_events,
                action::get_action_events_by_action_provider,
                action::update_action_event,
                action::update_action_events,
                diary_wod::create_wod,
                diary_wod::create_wods,
                diary_wod::get_wods,
                diary_wod::get_ordered_wods_by_timespan,
                diary_wod::update_wod,
                diary_wod::update_wods,
                diary_wod::create_diary,
                diary_wod::create_diaries,
                diary_wod::get_diary,
                diary_wod::get_ordered_diarys_by_timespan,
                diary_wod::get_diarys,
                diary_wod::update_diary,
                diary_wod::update_diaries,
                movement::create_movement,
                movement::create_movements,
                movement::get_movement,
                movement::get_movements,
                movement::update_movement,
                movement::update_movements,
                movement::get_eorms,
                strength::create_strength_session,
                strength::create_strength_sessions,
                strength::get_strength_session,
                strength::get_strength_sessions,
                strength::update_strength_session,
                strength::update_strength_sessions,
                strength::create_strength_set,
                strength::create_strength_sets,
                strength::get_strength_set,
                strength::get_strength_sets_by_strength_session,
                strength::update_strength_set,
                strength::update_strength_sets,
                strength::get_strength_session_description,
                strength::get_strength_session_descriptions,
                strength::get_ordered_strength_session_descriptions_by_timespan,
                metcon::create_metcon_session,
                metcon::create_metcon_sessions,
                metcon::get_metcon_session,
                metcon::get_metcon_sessions,
                metcon::update_metcon_session,
                metcon::update_metcon_sessions,
                metcon::create_metcons,
                metcon::create_metcon,
                metcon::get_metcon,
                metcon::get_metcons,
                metcon::update_metcon,
                metcon::update_metcons,
                metcon::create_metcon_movements,
                metcon::create_metcon_movement,
                metcon::get_metcon_movement,
                metcon::get_metcon_movements_by_metcon,
                metcon::update_metcon_movement,
                metcon::update_metcon_movements,
                metcon::get_metcon_session_description,
                metcon::get_metcon_session_descriptions,
                metcon::get_ordered_metcon_session_descriptions_by_timespan,
                cardio::create_route,
                cardio::create_routes,
                cardio::get_route,
                cardio::get_routes,
                cardio::update_route,
                cardio::update_routes,
                cardio::create_cardio_session,
                cardio::create_cardio_sessions,
                cardio::get_cardio_session,
                cardio::get_cardio_sessions,
                cardio::update_cardio_session,
                cardio::update_cardio_sessions,
                cardio::get_cardio_session_description,
                cardio::get_cardio_session_descriptions,
                cardio::get_ordered_cardio_session_descriptions_by_timespan,
                activity::get_ordered_activities_by_timespan,
                activity::get_activities,
                account::get_account_data,
                account::sync,
            ],
        )
}
