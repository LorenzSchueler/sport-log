//! test must be run sequentially
//! ```bash
//! cargo test -- --test-threads=1
//! ```

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
    local::asynchronous::{Client, LocalResponse},
    Build, Ignite, Phase, Rocket,
};

use sport_log_types::{
    ActionEvent, ActionEventId, ActionId, ActionProvider, ActionProviderId, Config, Create, Db,
    Diary, DiaryId, Platform, PlatformId, User, UserId, ADMIN_USERNAME,
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

fn get_config<P: Phase>(rocket: &Rocket<P>) -> Config {
    let figment = rocket.figment();
    let config: Config = figment.extract().expect("unable to extract Config");

    config
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

#[tokio::test]
async fn cors_preflight() {
    let client = Client::untracked(rocket())
        .await
        .expect("valid rocket instance");
    let response = client.options("/").dispatch().await;
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

async fn auth<P: Phase>(rocket: Rocket<P>, route: &str, username: &str, password: &str) {
    println!("ok 3.1");
    let client = Client::untracked(rocket)
        .await
        .expect("valid rocket instance");
    println!("ok 3.2");
    let mut request = client.get(route);
    request.add_header(basic_auth(username, password));
    let response = request.dispatch().await;
    assert_ok_json(&response);
}

async fn auth_wrong_credentials(route: &str, username: &str) {
    let client = Client::untracked(rocket())
        .await
        .expect("valid rocket instance");

    let mut request = client.get(route);
    request.add_header(basic_auth(username, "wrong password"));
    let response = request.dispatch().await;
    assert_unauthorized_json(&response);

    request = client.get(route);
    request.add_header(basic_auth("wrong username", "wrong password"));
    let response = request.dispatch().await;
    assert_unauthorized_json(&response);
}

async fn auth_without_credentials(route: &str) {
    let client = Client::untracked(rocket())
        .await
        .expect("valid rocket instance");
    let response = client.get(route).dispatch().await;
    assert_unauthorized_json(&response);
}

async fn auth_as(route: &str, username: &str, id: i64, password: &str) {
    let client = Client::untracked(rocket())
        .await
        .expect("valid rocket instance");
    let mut request = client.get(route);
    request.add_header(basic_auth_as(username, id, password));
    let response = request.dispatch().await;
    assert_ok_json(&response);
}

async fn auth_as_not_allowed(route: &str, username: &str, id: i64, password: &str) {
    let client = Client::untracked(rocket())
        .await
        .expect("valid rocket instance");
    let mut request = client.get(route);
    request.add_header(basic_auth_as(username, id, password));
    let response = request.dispatch().await;
    assert_forbidden_json(&response);
}

async fn auth_as_wrong_credentials(route: &str, username: &str, id: i64) {
    let client = Client::untracked(rocket())
        .await
        .expect("valid rocket instance");

    let mut request = client.get(route);
    request.add_header(basic_auth_as(username, id, "wrong password"));
    let response = request.dispatch().await;
    assert_unauthorized_json(&response);

    request = client.get(route);
    request.add_header(basic_auth_as("wrong username", 1, "wrong password"));
    let response = request.dispatch().await;
    assert_unauthorized_json(&response);
}

async fn auth_as_without_credentials(route: &str, id: i64) {
    let client = Client::untracked(rocket())
        .await
        .expect("valid rocket instance");
    let mut request = client.get(route);
    request.add_header(basic_auth_as("", id, "wrong password"));
    let response = request.dispatch().await;
    assert_unauthorized_json(&response);
}

#[tokio::test]
async fn admin_auth() {
    auth(
        rocket(),
        "/v1.0/adm/platform",
        ADMIN_USERNAME,
        ADMIN_PASSWORD,
    )
    .await
}

#[tokio::test]
async fn admin_auth_wrong_credentials() {
    auth_wrong_credentials("/v1.0/adm/platform", ADMIN_USERNAME).await;
}

#[tokio::test]
async fn admin_auth_without_credentials() {
    auth_without_credentials("/v1.0/adm/platform").await;
}

#[tokio::test]
async fn ap_auth() {
    auth(
        rocket(),
        "/v1.0/ap/action_provider",
        "wodify-login",
        "wodify-login-passwd",
    )
    .await;
}

#[tokio::test]
async fn ap_auth_wrong_credentials() {
    auth_wrong_credentials("/v1.0/ap/action_provider", "wodify-login").await;
}

#[tokio::test]
async fn ap_auth_without_credentials() {
    auth_without_credentials("/v1.0/ap/action_provider").await;
}

#[tokio::test]
async fn admin_as_ap_auth() {
    auth_as(
        "/v1.0/ap/action_provider",
        ADMIN_USERNAME,
        1,
        ADMIN_PASSWORD,
    )
    .await;
}

#[tokio::test]
async fn admin_as_ap_auth_wrong_credentials() {
    auth_as_wrong_credentials("/v1.0/ap/action_provider", ADMIN_USERNAME, 1).await;
}

#[tokio::test]
async fn admin_as_ap_auth_without_credentials() {
    auth_as_without_credentials("/v1.0/ap/action_provider", 1).await;
}

#[tokio::test]
async fn user_auth() {
    let rocket = rocket();
    auth(rocket, "/v1.0/user", "user1", "user1-passwd").await;
}

#[tokio::test]
async fn user_auth_wrong_credentials() {
    auth_wrong_credentials("/v1.0/user", "user1").await;
}

#[tokio::test]
async fn user_auth_without_credentials() {
    auth_without_credentials("/v1.0/user").await;
}

#[tokio::test]
async fn admin_as_user_auth() {
    auth_as("/v1.0/user", ADMIN_USERNAME, 1, ADMIN_PASSWORD).await;
}

#[tokio::test]
async fn admin_as_user_auth_wrong_credentials() {
    auth_as_wrong_credentials("/v1.0/user", ADMIN_USERNAME, 1).await;
}

#[tokio::test]
async fn admin_as_user_auth_without_credentials() {
    auth_as_without_credentials("/v1.0/user", 1).await;
}

#[tokio::test]
async fn user_ap_auth() {
    auth(rocket(), "/v1.0/diary", "user1", "user1-passwd").await;
}

#[tokio::test]
async fn user_ap_auth_wrong_credentials() {
    auth_wrong_credentials("/v1.0/diary", "user1").await;
}

#[tokio::test]
async fn user_ap_auth_without_credentials() {
    auth_without_credentials("/v1.0/diary").await;
}

async fn create_action_event(username: &str, password: &str, action_event: &ActionEvent) {
    let client = Client::untracked(rocket())
        .await
        .expect("valid rocket instance");
    let mut request = client.post("/v1.0/action_event");
    request.add_header(basic_auth(username, password));
    let request = request.json(action_event);
    let response = request.dispatch().await;
    assert_ok_json(&response);
}

#[tokio::test]
async fn ap_as_user_ap_auth() {
    // create ActionEvent to ensure access permission for user
    let action_event = ActionEvent {
        id: ActionEventId(rand::thread_rng().gen()),
        user_id: UserId(1),
        action_id: ActionId(1),
        datetime: Utc::now() + Duration::days(1),
        arguments: None,
        enabled: true,
        last_change: Utc::now(),
        deleted: false,
    };
    create_action_event("user1", "user1-passwd", &action_event).await;

    auth_as("/v1.0/diary", "wodify-login", 1, "wodify-login-passwd").await;
}

#[tokio::test]
async fn ap_as_user_ap_auth_no_event() {
    // delete all action events
    let (username, password) = ("user1", "user1-passwd");
    let client = Client::untracked(rocket())
        .await
        .expect("valid rocket instance");

    let mut request = client.get("/v1.0/action_event");
    request.add_header(basic_auth(username, password));
    let response = request.dispatch().await;
    assert_ok_json(&response);
    let action_events: Vec<ActionEvent> = response.into_json().await.unwrap();
    let action_events: Vec<ActionEvent> = action_events
        .into_iter()
        .map(|mut action_event| {
            action_event.enabled = false;
            action_event.deleted = true;
            action_event
        })
        .collect();

    let mut request = client.put("/v1.0/action_events");
    request.add_header(basic_auth(username, password));
    let request = request.json(&action_events);
    let response = request.dispatch().await;
    assert_ok_json(&response);

    // create disabled ActionEvent
    let action_event = ActionEvent {
        id: ActionEventId(rand::thread_rng().gen()),
        user_id: UserId(1),
        action_id: ActionId(1),
        datetime: Utc::now() + Duration::days(1),
        arguments: None,
        enabled: false,
        last_change: Utc::now(),
        deleted: false,
    };
    create_action_event("user1", "user1-passwd", &action_event).await;

    // create deleted ActionEvent
    let action_event = ActionEvent {
        id: ActionEventId(rand::thread_rng().gen()),
        user_id: UserId(1),
        action_id: ActionId(1),
        datetime: Utc::now() + Duration::days(1),
        arguments: None,
        enabled: true,
        last_change: Utc::now(),
        deleted: true,
    };
    create_action_event("user1", "user1-passwd", &action_event).await;

    //  check that ap has no access
    println!("{:?}", "okook");
    auth_as_not_allowed("/v1.0/diary", "wodify-login", 1, "wodify-login-passwd").await;
}

#[tokio::test]
async fn ap_as_user_ap_auth_wrong_credentials() {
    // create ActionEvent to ensure access permission for user
    let action_event = ActionEvent {
        id: ActionEventId(rand::thread_rng().gen()),
        user_id: UserId(1),
        action_id: ActionId(1),
        datetime: Utc::now() + Duration::days(1),
        arguments: None,
        enabled: true,
        last_change: Utc::now(),
        deleted: false,
    };
    create_action_event("user1", "user1-passwd", &action_event).await;

    auth_as_wrong_credentials("/v1.0/diary", "wodify-login", 1).await;
}

#[tokio::test]
async fn ap_as_user_ap_auth_without_credentials() {
    // create ActionEvent to ensure access permission for user
    let action_event = ActionEvent {
        id: ActionEventId(rand::thread_rng().gen()),
        user_id: UserId(1),
        action_id: ActionId(1),
        datetime: Utc::now() + Duration::days(1),
        arguments: None,
        enabled: true,
        last_change: Utc::now(),
        deleted: false,
    };
    create_action_event("user1", "user1-passwd", &action_event).await;

    auth_as_without_credentials("/v1.0/diary", 1).await;
}

#[tokio::test]
async fn admin_as_user_ap_auth() {
    auth_as("/v1.0/diary", ADMIN_USERNAME, 1, ADMIN_PASSWORD).await;
}

#[tokio::test]
async fn admin_as_user_ap_auth_wrong_credentials() {
    auth_as_wrong_credentials("/v1.0/diary", ADMIN_USERNAME, 1).await;
}

#[tokio::test]
async fn admin_as_user_ap_auth_without_credentials() {
    auth_as_without_credentials("/v1.0/diary", 1).await;
}

async fn create_diary<'c>(
    client: &'c Client,
    username: &str,
    password: &str,
    user_id: i64,
) -> (DiaryId, LocalResponse<'c>) {
    let mut request = client.post("/v1.0/diary");
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
    let response = request.dispatch().await;

    (diary_id, response)
}

#[tokio::test]
async fn foreign_create() {
    let client = Client::untracked(rocket())
        .await
        .expect("valid rocket instance");

    // check that create works for same user
    let (_, response) = create_diary(&client, "user1", "user1-passwd", 1).await;
    assert_ok_json(&response);

    // check that create does not work for other user
    let (_, response) = create_diary(&client, "user2", "user2-passwd", 1).await;
    assert_forbidden_json(&response);
}

#[tokio::test]
async fn foreign_get() {
    let client = Client::untracked(rocket())
        .await
        .expect("valid rocket instance");

    let (diary_id, response) = create_diary(&client, "user1", "user1-passwd", 1).await;
    assert_ok_json(&response);

    // check that get works for same user
    let mut request = client.get(format!("/v1.0/diary/{}", diary_id.0));
    request.add_header(basic_auth("user1", "user1-passwd"));
    let response = request.dispatch().await;
    assert_ok_json(&response);

    // check that get does not work for other user
    let mut request = client.get(format!("/v1.0/diary/{}", diary_id.0));
    request.add_header(basic_auth("user2", "user2-passwd"));
    let response = request.dispatch().await;
    assert_forbidden_json(&response);
}

#[tokio::test]
async fn foreign_update() {
    let client = Client::untracked(rocket())
        .await
        .expect("valid rocket instance");

    let (diary_id, response) = create_diary(&client, "user1", "user1-passwd", 1).await;
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
    let mut request = client.put("/v1.0/diary");
    request.add_header(basic_auth("user1", "user1-passwd"));
    let request = request.json(&diary);
    let response = request.dispatch().await;
    assert_ok_json(&response);

    // check that update does not work for other user
    let mut request = client.put("/v1.0/diary");
    request.add_header(basic_auth("user2", "user2-passwd"));
    let request = request.json(&diary);
    let response = request.dispatch().await;
    assert_forbidden_json(&response);
}

#[tokio::test]
async fn user_self_registration() {
    let rocket = rocket();
    let config = get_config(&rocket);
    let client = Client::untracked(rocket)
        .await
        .expect("valid rocket instance");

    let user = User {
        id: UserId(rand::thread_rng().gen()),
        username: format!("user{}", rand::thread_rng().gen::<u64>()),
        password: "password".to_owned(),
        email: format!("email{}", rand::thread_rng().gen::<u64>()),
        last_change: Utc::now(),
    };

    let request = client.post("/v1.0/user");
    let request = request.json(&user);
    let response = request.dispatch().await;

    if config.user_self_registration {
        assert_ok_json(&response);
    } else {
        assert_forbidden_json(&response);
    }
}

#[tokio::test]
async fn ap_self_registration() {
    let rocket = rocket();
    let config = get_config(&rocket);
    let client = Client::untracked(rocket)
        .await
        .expect("valid rocket instance");

    let platform = Platform {
        id: PlatformId(rand::thread_rng().gen()),
        name: format!("platform{}", rand::thread_rng().gen::<u64>()),
        credential: false,
        last_change: Utc::now(),
        deleted: false,
    };

    let request = client.post("/v1.0/ap/platform");
    let request = request.json(&platform);
    let response = request.dispatch().await;

    if config.ap_self_registration {
        assert_ok_json(&response);
    } else {
        assert_forbidden_json(&response);
    }

    let request = client.get("/v1.0/ap/platform");
    let response = request.dispatch().await;

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

    let request = client.post("/v1.0/ap/action_provider");
    let request = request.json(&action_provider);
    let response = request.dispatch().await;

    if config.ap_self_registration {
        assert_ok_json(&response);
    } else {
        assert_forbidden_json(&response);
    }
}

#[tokio::test]
async fn update_non_existing() {
    let client = Client::untracked(rocket())
        .await
        .expect("valid rocket instance");

    let diary = Diary {
        id: DiaryId(rand::thread_rng().gen()),
        user_id: UserId(1),
        date: NaiveDate::from_num_days_from_ce(rand::thread_rng().gen::<i32>() % 1_500_000),
        bodyweight: None,
        comments: None,
        last_change: Utc::now(),
        deleted: false,
    };

    let mut request = client.put("/v1.0/diary");
    request.add_header(basic_auth("user1", "user1-passwd"));
    let request = request.json(&diary);
    let response = request.dispatch().await;
    assert_forbidden_json(&response);
}

// create directly without handler && use test transaction
