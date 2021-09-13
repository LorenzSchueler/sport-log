use chrono::{Duration, NaiveDate, Utc};
use rand::Rng;
use rocket::{
    http::{
        hyper::header::{
            ACCESS_CONTROL_ALLOW_CREDENTIALS, ACCESS_CONTROL_ALLOW_HEADERS,
            ACCESS_CONTROL_ALLOW_METHODS, ACCESS_CONTROL_ALLOW_ORIGIN, ACCESS_CONTROL_MAX_AGE,
            AUTHORIZATION,
        },
        Header, Status,
    },
    local::blocking::{Client, LocalResponse},
    Build, Rocket,
};

use sport_log_types::{
    ActionEvent, ActionEventId, ActionId, ActionProvider, ActionProviderId, Config, Diary, DiaryId,
    Platform, PlatformId, User, UserId, ADMIN_USERNAME,
};

use crate::rocket;

const ADMIN_PASSWORD: &str = "admin-passwd";

fn basic_auth<'h>(username: &str, password: &str) -> Header<'h> {
    Header::new(
        AUTHORIZATION.as_str(),
        format!(
            "Basic {}",
            base64::encode(format!("{}:{}", username, password))
        ),
    )
}

fn basic_auth_as<'h>(username: &str, id: i64, password: &str) -> Header<'h> {
    Header::new(
        AUTHORIZATION.as_str(),
        format!(
            "Basic {}",
            base64::encode(format!("{}$id${}:{}", username, id, password))
        ),
    )
}

fn rocket_with_config() -> (Rocket<Build>, Config) {
    let rocket = rocket();
    let figment = rocket.figment();
    let config: Config = figment.extract().expect("unable to extract Config");

    (rocket, config)
}

fn assert_status_json(response: &LocalResponse, status: Status) {
    assert_eq!(status, response.status());
    assert_eq!(
        "application/json",
        response.headers().get_one("Content-Type").unwrap(),
    );
}

fn assert_ok_json(response: &LocalResponse) {
    assert_status_json(response, Status::Ok);
}

fn assert_unauthorized_json(response: &LocalResponse) {
    assert_status_json(response, Status::Unauthorized);
}

fn assert_forbidden_json(response: &LocalResponse) {
    assert_status_json(response, Status::Forbidden);
}

#[test]
fn cors_preflight() {
    let client = Client::untracked(rocket()).expect("valid rocket instance");
    let response = client.options("/").dispatch();
    assert_eq!(response.status(), Status::NoContent);
    assert_eq!(
        response
            .headers()
            .get_one(ACCESS_CONTROL_ALLOW_ORIGIN.as_str())
            .unwrap(),
        "*"
    );
    assert_eq!(
        response
            .headers()
            .get_one(ACCESS_CONTROL_ALLOW_METHODS.as_str())
            .unwrap(),
        "POST, GET, PUT, DELETE, OPTIONS"
    );
    assert_eq!(
        response
            .headers()
            .get_one(ACCESS_CONTROL_ALLOW_HEADERS.as_str())
            .unwrap(),
        "*"
    );
    assert_eq!(
        response
            .headers()
            .get_one(ACCESS_CONTROL_ALLOW_CREDENTIALS.as_str())
            .unwrap(),
        "true"
    );
    assert_eq!(
        response
            .headers()
            .get_one(ACCESS_CONTROL_MAX_AGE.as_str())
            .unwrap(),
        "864000"
    );
}

fn auth(route: &str, username: &str, password: &str) {
    let client = Client::untracked(rocket()).expect("valid rocket instance");
    let mut request = client.get(route);
    request.add_header(basic_auth(username, password));
    let response = request.dispatch();
    assert_ok_json(&response);
}

fn auth_wrong_credentials(route: &str, username: &str) {
    let client = Client::untracked(rocket()).expect("valid rocket instance");

    let mut request = client.get(route);
    request.add_header(basic_auth(username, "wrong password"));
    let response = request.dispatch();
    assert_unauthorized_json(&response);

    request = client.get(route);
    request.add_header(basic_auth("wrong username", "wrong password"));
    let response = request.dispatch();
    assert_unauthorized_json(&response);
}

fn auth_without_credentials(route: &str) {
    let client = Client::untracked(rocket()).expect("valid rocket instance");
    let response = client.get(route).dispatch();
    assert_unauthorized_json(&response);
}

fn auth_as(route: &str, username: &str, id: i64, password: &str) {
    let client = Client::untracked(rocket()).expect("valid rocket instance");
    let mut request = client.get(route);
    request.add_header(basic_auth_as(username, id, password));
    let response = request.dispatch();
    assert_ok_json(&response);
}

fn auth_as_wrong_credentials(route: &str, username: &str, id: i64) {
    let client = Client::untracked(rocket()).expect("valid rocket instance");

    let mut request = client.get(route);
    request.add_header(basic_auth_as(username, id, "wrong password"));
    let response = request.dispatch();
    assert_unauthorized_json(&response);

    request = client.get(route);
    request.add_header(basic_auth_as("wrong username", 1, "wrong password"));
    let response = request.dispatch();
    assert_unauthorized_json(&response);
}

fn auth_as_without_credentials(route: &str, id: i64) {
    let client = Client::untracked(rocket()).expect("valid rocket instance");
    let mut request = client.get(route);
    request.add_header(basic_auth_as("", id, "wrong password"));
    let response = request.dispatch();
    assert_unauthorized_json(&response);
}

#[test]
fn admin_auth() {
    auth("/v1/adm/platform", ADMIN_USERNAME, ADMIN_PASSWORD)
}

#[test]
fn admin_auth_wrong_credentials() {
    auth_wrong_credentials("/v1/adm/platform", ADMIN_USERNAME);
}

#[test]
fn admin_auth_without_credentials() {
    auth_without_credentials("/v1/adm/platform");
}

#[test]
fn ap_auth() {
    auth(
        "/v1/ap/action_provider",
        "wodify-login",
        "wodify-login-passwd",
    );
}

#[test]
fn ap_auth_wrong_credentials() {
    auth_wrong_credentials("/v1/ap/action_provider", "wodify-login");
}

#[test]
fn ap_auth_without_credentials() {
    auth_without_credentials("/v1/ap/action_provider");
}

#[test]
fn admin_as_ap_auth() {
    auth_as("/v1/ap/action_provider", ADMIN_USERNAME, 1, ADMIN_PASSWORD);
}

#[test]
fn admin_as_ap_auth_wrong_credentials() {
    auth_as_wrong_credentials("/v1/ap/action_provider", ADMIN_USERNAME, 1);
}

#[test]
fn admin_as_ap_auth_without_credentials() {
    auth_as_without_credentials("/v1/ap/action_provider", 1);
}

#[test]
fn user_auth() {
    auth("/v1/user", "user1", "user1-passwd");
}

#[test]
fn user_auth_wrong_credentials() {
    auth_wrong_credentials("/v1/user", "user1");
}

#[test]
fn user_auth_without_credentials() {
    auth_without_credentials("/v1/user");
}

#[test]
fn admin_as_user_auth() {
    auth_as("/v1/user", ADMIN_USERNAME, 1, ADMIN_PASSWORD);
}

#[test]
fn admin_as_user_auth_wrong_credentials() {
    auth_as_wrong_credentials("/v1/user", ADMIN_USERNAME, 1);
}

#[test]
fn admin_as_user_auth_without_credentials() {
    auth_as_without_credentials("/v1/user", 1);
}

#[test]
fn user_ap_auth() {
    auth("/v1/diary", "user1", "user1-passwd");
}

#[test]
fn user_ap_auth_wrong_credentials() {
    auth_wrong_credentials("/v1/diary", "user1");
}

#[test]
fn user_ap_auth_without_credentials() {
    auth_without_credentials("/v1/diary");
}

fn create_action_event(username: &str, password: &str, user_id: i64) {
    let client = Client::untracked(rocket()).expect("valid rocket instance");
    let mut request = client.post("/v1/action_event");
    request.add_header(basic_auth(username, password));
    let action_event = ActionEvent {
        id: ActionEventId(rand::thread_rng().gen()),
        user_id: UserId(user_id),
        action_id: ActionId(1),
        datetime: Utc::now() + Duration::days(1),
        arguments: None,
        enabled: true,
        last_change: Utc::now(),
        deleted: false,
    };
    let request = request.json(&action_event);
    let response = request.dispatch();
    assert_ok_json(&response);
}

#[test]
fn ap_as_user_ap_auth() {
    // create ActionEvent to ensure access permission for user
    create_action_event("user1", "user1-passwd", 1);

    auth_as("/v1/diary", "wodify-login", 1, "wodify-login-passwd");
}

#[test]
fn ap_as_user_ap_auth_wrong_credentials() {
    // create ActionEvent to ensure access permission for user
    create_action_event("user1", "user1-passwd", 1);

    auth_as_wrong_credentials("/v1/diary", "wodify-login", 1);
}

#[test]
fn ap_as_user_ap_auth_without_credentials() {
    // create ActionEvent to ensure access permission for user
    create_action_event("user1", "user1-passwd", 1);

    auth_as_without_credentials("/v1/diary", 1);
}

#[test]
fn admin_as_user_ap_auth() {
    auth_as("/v1/diary", ADMIN_USERNAME, 1, ADMIN_PASSWORD);
}

#[test]
fn admin_as_user_ap_auth_wrong_credentials() {
    auth_as_wrong_credentials("/v1/diary", ADMIN_USERNAME, 1);
}

#[test]
fn admin_as_user_ap_auth_without_credentials() {
    auth_as_without_credentials("/v1/diary", 1);
}

fn create_diary<'c>(
    client: &'c Client,
    username: &str,
    password: &str,
    user_id: i64,
) -> (DiaryId, LocalResponse<'c>) {
    let mut request = client.post("/v1/diary");
    request.add_header(basic_auth(username, password));
    let diary_id = DiaryId(rand::thread_rng().gen());
    let diary = Diary {
        id: diary_id,
        user_id: UserId(user_id),
        date: NaiveDate::from_num_days_from_ce(rand::thread_rng().gen::<i32>() % 1_500_000),
        bodyweight: None,
        comments: None,
        last_change: Utc::now(),
        deleted: false,
    };
    let request = request.json(&diary);
    let response = request.dispatch();

    (diary_id, response)
}

#[test]
fn foreign_create() {
    let client = Client::untracked(rocket()).expect("valid rocket instance");

    // check that create works for same user
    let (_, response) = create_diary(&client, "user1", "user1-passwd", 1);
    assert_ok_json(&response);

    // check that create does not work for other user
    let (_, response) = create_diary(&client, "user2", "user2-passwd", 1);
    assert_forbidden_json(&response);
}

#[test]
fn foreign_get() {
    let client = Client::untracked(rocket()).expect("valid rocket instance");

    let (diary_id, response) = create_diary(&client, "user1", "user1-passwd", 1);
    assert_ok_json(&response);

    // check that get works for same user
    let mut request = client.get(format!("/v1/diary/{}", diary_id.0));
    request.add_header(basic_auth("user1", "user1-passwd"));
    let response = request.dispatch();
    assert_ok_json(&response);

    // check that get does not work for other user
    let mut request = client.get(format!("/v1/diary/{}", diary_id.0));
    request.add_header(basic_auth("user2", "user2-passwd"));
    let response = request.dispatch();
    assert_forbidden_json(&response);
}

#[test]
fn foreign_update() {
    let client = Client::untracked(rocket()).expect("valid rocket instance");

    let (diary_id, response) = create_diary(&client, "user1", "user1-passwd", 1);
    assert_ok_json(&response);

    let diary = Diary {
        id: diary_id,
        user_id: UserId(1),
        date: NaiveDate::from_num_days_from_ce(rand::thread_rng().gen::<i32>() % 1_500_000),
        bodyweight: None,
        comments: None,
        last_change: Utc::now(),
        deleted: false,
    };

    // check that update works for same user
    let mut request = client.put("/v1/diary");
    request.add_header(basic_auth("user1", "user1-passwd"));
    let request = request.json(&diary);
    let response = request.dispatch();
    assert_ok_json(&response);

    // check that update does not work for other user
    let mut request = client.put("/v1/diary");
    request.add_header(basic_auth("user2", "user2-passwd"));
    let request = request.json(&diary);
    let response = request.dispatch();
    assert_forbidden_json(&response);
}

#[test]
fn user_self_registration() {
    let (rocket, config) = rocket_with_config();
    let client = Client::untracked(rocket).expect("valid rocket instance");

    let user = User {
        id: UserId(rand::thread_rng().gen()),
        username: format!("user{}", rand::thread_rng().gen::<u64>()),
        password: "password".to_owned(),
        email: format!("email{}", rand::thread_rng().gen::<u64>()),
        last_change: Utc::now(),
    };

    let request = client.post("/v1/user");
    let request = request.json(&user);
    let response = request.dispatch();

    if config.user_self_registration {
        assert_ok_json(&response);
    } else {
        assert_forbidden_json(&response);
    }
}

#[test]
fn ap_self_registration() {
    let (rocket, config) = rocket_with_config();
    let client = Client::untracked(rocket).expect("valid rocket instance");

    let platform = Platform {
        id: PlatformId(rand::thread_rng().gen()),
        name: format!("platform{}", rand::thread_rng().gen::<u64>()),
        credential: false,
        last_change: Utc::now(),
        deleted: false,
    };

    let request = client.post("/v1/ap/platform");
    let request = request.json(&platform);
    let response = request.dispatch();

    if config.ap_self_registration {
        assert_ok_json(&response);
    } else {
        assert_forbidden_json(&response);
    }

    let request = client.get("/v1/ap/platform");
    let response = request.dispatch();

    if config.ap_self_registration {
        assert_ok_json(&response);
    } else {
        assert_forbidden_json(&response);
    }

    let action_provider = ActionProvider {
        id: ActionProviderId(rand::thread_rng().gen()),
        name: format!("ap{}", rand::thread_rng().gen::<u64>()),
        password: "password".to_owned(),
        platform_id: PlatformId(1),
        description: None,
        last_change: Utc::now(),
        deleted: false,
    };

    let request = client.post("/v1/ap/action_provider");
    let request = request.json(&action_provider);
    let response = request.dispatch();

    if config.ap_self_registration {
        assert_ok_json(&response);
    } else {
        assert_forbidden_json(&response);
    }
}

#[test]
fn update_non_existing() {
    let client = Client::untracked(rocket()).expect("valid rocket instance");

    let diary = Diary {
        id: DiaryId(rand::thread_rng().gen()),
        user_id: UserId(1),
        date: NaiveDate::from_num_days_from_ce(rand::thread_rng().gen::<i32>() % 1_500_000),
        bodyweight: None,
        comments: None,
        last_change: Utc::now(),
        deleted: false,
    };

    let mut request = client.put("/v1/diary");
    request.add_header(basic_auth("user1", "user1-passwd"));
    let request = request.json(&diary);
    let response = request.dispatch();
    assert_forbidden_json(&response);
}

// deleted tests
