use const_format::concatcp;

pub const VERSION: &str = "/version";

pub const VERSION_0_4: &str = "0.4";
pub const MIN_VERSION: &str = VERSION_0_4;
pub const MAX_VERSION: &str = VERSION_0_4;

pub fn route_max_version(address: &str, route: &str, query: Option<&[(&str, &str)]>) -> String {
    if let (Some(query), Some(false)) = (query, query.map(<[_]>::is_empty)) {
        let mut query_string: String = query
            .iter()
            .flat_map(|(key, value)| [key, "=", value, "&"])
            .collect();
        query_string.pop();

        format!("{address}/v{MAX_VERSION}{route}?{query_string}")
    } else {
        format!("{address}/v{MAX_VERSION}{route}")
    }
}

// user URIs

pub const APP_INFO: &str = "/app/info";
pub const APP_DOWNLOAD: &str = "/app/download";

pub const ACCOUNT_DATA: &str = "/account_data";

pub const USER: &str = "/user";

pub const PLATFORM: &str = "/platform";
pub const PLATFORM_CREDENTIAL: &str = "/platform_credential";
pub const ACTION_PROVIDER: &str = "/action_provider";
pub const ACTION: &str = "/action";
pub const ACTION_RULE: &str = "/action_rule";
pub const ACTION_EVENT: &str = "/action_event";

pub const STRENGTH_SESSION: &str = "/strength_session";
pub const STRENGTH_SET: &str = "/strength_set";
pub const EORM: &str = "/eorm";

pub const METCON_SESSION: &str = "/metcon_session";
pub const METCON: &str = "/metcon";
pub const METCON_MOVEMENT: &str = "/metcon_movement";

pub const CARDIO_SESSION: &str = "/cardio_session";
pub const ROUTE: &str = "/route";

pub const DIARY: &str = "/diary";
pub const WOD: &str = "/wod";

pub const MOVEMENT: &str = "/movement";

// admin URIs

const ADM: &str = "/adm";

pub const ADM_USER: &str = concatcp!(ADM, USER);

pub const ADM_PLATFORM: &str = concatcp!(ADM, PLATFORM);
pub const ADM_ACTION_PROVIDER: &str = concatcp!(ADM, ACTION_PROVIDER);
pub const ADM_ACTION_EVENT: &str = concatcp!(ADM, ACTION_EVENT);
pub const ADM_CREATABLE_ACTION_RULE: &str = concatcp!(ADM, "/creatable_action_rule");
pub const ADM_DELETABLE_ACTION_EVENT: &str = concatcp!(ADM, "/deletable_action_event");

// ap URIs

const AP: &str = "/ap";

pub const AP_PLATFORM: &str = concatcp!(AP, PLATFORM);
pub const AP_ACTION_PROVIDER: &str = concatcp!(AP, ACTION_PROVIDER);
pub const AP_ACTION: &str = concatcp!(AP, ACTION);
pub const AP_ACTION_EVENT: &str = concatcp!(AP, ACTION_EVENT);
pub const AP_EXECUTABLE_ACTION_EVENT: &str = concatcp!(AP, "/executable_action_event");
