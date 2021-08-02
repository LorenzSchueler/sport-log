use std::io::Cursor;

#[macro_use]
extern crate rocket;

use rocket::{
    http::{ContentType, Status},
    response::Responder,
    Request, Response,
};
use serde::{Deserialize, Serialize};

use sport_log_types::{Db, CONFIG};

mod handler;

const BASE: &str = "/v1";

struct JsonError {
    status: Status,
}

#[derive(Serialize, Deserialize, Debug)]
struct ErrorMessage {
    pub status: u16,
}

impl<'r, 'o: 'r> Responder<'r, 'o> for JsonError {
    fn respond_to(self, _request: &'r Request<'_>) -> Result<Response<'o>, Status> {
        let json = serde_json::to_string(&ErrorMessage {
            status: self.status.code,
        })
        .unwrap();
        Ok(Response::build()
            .status(self.status)
            .header(ContentType::JSON)
            .sized_body(json.len(), Cursor::new(json))
            .finalize())
    }
}

#[catch(default)]
fn default_catcher<'r>(status: Status, _request: &'r Request) -> JsonError {
    JsonError { status }
}

#[launch]
fn rocket() -> _ {
    dotenv::dotenv().ok();

    lazy_static::initialize(&CONFIG);

    use handler::*;
    rocket::build()
        .register("/", catchers![default_catcher])
        .attach(Db::fairing())
        .mount(
            BASE,
            routes![
                user::adm_create_user,
                user::create_user,
                user::get_user,
                user::update_user,
                user::delete_user,
                platform::adm_create_platform,
                platform::adm_get_platforms,
                platform::get_platforms,
                platform::adm_update_platform,
                platform::adm_delete_platform,
                platform::create_platform_credential,
                platform::create_platform_credentials,
                platform::get_platform_credentials,
                platform::get_platform_credentials_by_platform,
                platform::update_platform_credential,
                platform::delete_platform_credential,
                platform::delete_platform_credentials,
                action::adm_create_action_provider,
                action::adm_get_action_providers,
                action::adm_delete_action_provider,
                action::ap_create_action,
                action::ap_get_action,
                action::ap_get_actions,
                action::get_actions,
                action::ap_delete_action,
                action::create_action_rule,
                action::create_action_rules,
                action::get_action_rule,
                action::get_action_rules,
                action::get_action_rules_by_action_provider,
                action::update_action_rule,
                action::delete_action_rule,
                action::delete_action_rules,
                action::create_action_event,
                action::create_action_events,
                action::get_action_event,
                action::get_action_events,
                action::ap_get_action_events,
                action::get_action_events_by_action_provider,
                action::update_action_event,
                action::delete_action_event,
                action::delete_action_events,
                action::ap_get_executable_action_events,
                action::ap_get_ordered_executable_action_events_by_timespan,
                diary_wod::create_wod,
                diary_wod::create_wods,
                diary_wod::get_wods,
                diary_wod::get_ordered_wods_by_timespan,
                diary_wod::update_wod,
                diary_wod::delete_wod,
                diary_wod::delete_wods,
                diary_wod::create_diary,
                diary_wod::create_diaries,
                diary_wod::get_diary,
                diary_wod::get_ordered_diarys_by_timespan,
                diary_wod::get_diarys,
                diary_wod::update_diary,
                diary_wod::delete_diary,
                diary_wod::delete_diaries,
                movement::create_movement,
                movement::create_movements,
                movement::get_movement,
                movement::get_movements,
                movement::update_movement,
                movement::delete_movement,
                movement::delete_movements,
                movement::get_eorms,
                strength::create_strength_session,
                strength::create_strength_sessions,
                strength::get_strength_session,
                strength::get_strength_sessions,
                strength::update_strength_session,
                strength::delete_strength_session,
                strength::delete_strength_sessions,
                strength::create_strength_set,
                strength::create_strength_sets,
                strength::get_strength_set,
                strength::get_strength_sets_by_strength_session,
                strength::update_strength_set,
                strength::delete_strength_set,
                strength::delete_strength_sets,
                strength::get_strength_session_description,
                strength::get_strength_session_descriptions,
                strength::get_ordered_strength_session_descriptions_by_timespan,
                metcon::create_metcon_session,
                metcon::create_metcon_sessions,
                metcon::get_metcon_session,
                metcon::get_metcon_sessions,
                metcon::update_metcon_session,
                metcon::delete_metcon_session,
                metcon::delete_metcon_sessions,
                metcon::create_metcons,
                metcon::create_metcon,
                metcon::get_metcon,
                metcon::get_metcons,
                metcon::update_metcon,
                metcon::delete_metcon,
                metcon::delete_metcons,
                metcon::create_metcon_movements,
                metcon::create_metcon_movement,
                metcon::get_metcon_movement,
                metcon::get_metcon_movements_by_metcon,
                metcon::update_metcon_movement,
                metcon::delete_metcon_movement,
                metcon::delete_metcon_movements,
                metcon::get_metcon_session_description,
                metcon::get_metcon_session_descriptions,
                metcon::get_ordered_metcon_session_descriptions_by_timespan,
                cardio::create_route,
                cardio::create_routes,
                cardio::get_route,
                cardio::get_routes,
                cardio::update_route,
                cardio::delete_route,
                cardio::delete_routes,
                cardio::create_cardio_session,
                cardio::create_cardio_sessions,
                cardio::get_cardio_session,
                cardio::get_cardio_sessions,
                cardio::update_cardio_session,
                cardio::delete_cardio_session,
                cardio::delete_cardio_sessions,
                cardio::get_cardio_session_description,
                cardio::get_cardio_session_descriptions,
                cardio::get_ordered_cardio_session_descriptions_by_timespan,
                activity::get_ordered_activities_by_timespan,
                activity::get_activities,
                account::get_account_data,
            ],
        )
}
