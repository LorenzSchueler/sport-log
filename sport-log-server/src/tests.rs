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
    Ignite, Phase, Rocket,
};

use sport_log_types::{
    Action, ActionEvent, ActionEventId, ActionId, ActionProvider, ActionProviderId, Config, Create,
    Db, Diary, DiaryId, HardDelete, Platform, PlatformId, Update, User, UserId, ADMIN_USERNAME,
};

use crate::{rocket, VERSION};

const ADMIN_PASSWORD: &str = "admin-passwd";
const AP_ID: ActionProviderId = ActionProviderId(123456789);
const AP_USERNAME: &str = "ap123456789";
const AP_PASSWORD: &str = "ap123456789-passwd";
const USER_ID: UserId = UserId(123456789);
const USER_USERNAME: &str = "user123456789";
const USER_PASSWORD: &str = "user123456789-passwd";
const USER2_ID: UserId = UserId(2123456789);
const USER2_USERNAME: &str = "user2123456789";
const USER2_PASSWORD: &str = "user2123456789-passwd";
const PLATFORM_ID: PlatformId = PlatformId(123456789);
const ACTION_ID: ActionId = ActionId(123456789);

fn route(path: &str) -> String {
    format!("/v{VERSION}{path}")
}

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

async fn get_db(rocket: &Rocket<Ignite>) -> Db {
    Db::get_one(rocket).await.unwrap()
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
async fn aa_setup() {
    let rocket = rocket().ignite().await.unwrap();
    let db = get_db(&rocket).await;

    let user = User {
        id: USER_ID,
        username: USER_USERNAME.to_owned(),
        password: USER_PASSWORD.to_owned(),
        email: "email123456789".to_owned(),
        last_change: Utc::now(),
    };
    db.run(|c| User::create(user, c)).await.unwrap();

    let user2 = User {
        id: USER2_ID,
        username: USER2_USERNAME.to_owned(),
        password: USER2_PASSWORD.to_owned(),
        email: "email2123456789".to_owned(),
        last_change: Utc::now(),
    };
    db.run(|c| User::create(user2, c)).await.unwrap();

    let platform = Platform {
        id: PLATFORM_ID,
        name: "platform123456789".to_owned(),
        credential: false,
        last_change: Utc::now(),
        deleted: false,
    };
    db.run(|c| Platform::create(platform, c)).await.unwrap();

    let ap = ActionProvider {
        id: AP_ID,
        name: AP_USERNAME.to_owned(),
        password: AP_PASSWORD.to_owned(),
        platform_id: PLATFORM_ID,
        description: None,
        last_change: Utc::now(),
        deleted: false,
    };
    db.run(|c| ActionProvider::create(ap, c)).await.unwrap();

    let action = Action {
        id: ACTION_ID,
        name: "action123456789".to_owned(),
        action_provider_id: AP_ID,
        description: None,
        create_before: 1,
        delete_after: 1,
        last_change: Utc::now(),
        deleted: false,
    };
    db.run(|c| Action::create(action, c)).await.unwrap();
}

#[tokio::test]
async fn zz_teardown() {
    let rocket = rocket().ignite().await.unwrap();
    let db = get_db(&rocket).await;

    db.run(|c| User::delete(USER_ID, c)).await.unwrap();
    db.run(|c| User::delete(USER2_ID, c)).await.unwrap();

    let platform = Platform {
        id: PLATFORM_ID,
        name: "platform123456789".to_owned(),
        credential: false,
        last_change: Utc::now(),
        deleted: true,
    };
    db.run(|c| Platform::update(platform, c)).await.unwrap();
    db.run(|c| Platform::hard_delete(Utc::now() - Duration::seconds(10), c))
        .await
        .unwrap();
    db.run(|c| Action::hard_delete(Utc::now() - Duration::seconds(10), c))
        .await
        .unwrap();
    db.run(|c| ActionProvider::hard_delete(Utc::now() - Duration::seconds(10), c))
        .await
        .unwrap();
}

async fn create_action_event(action_event: ActionEvent) {
    let rocket = rocket().ignite().await.unwrap();
    let db = get_db(&rocket).await;

    db.run(|c| ActionEvent::create(action_event, c))
        .await
        .unwrap();
}

async fn delete_action_event(mut action_event: ActionEvent) {
    let rocket = rocket().ignite().await.unwrap();
    let db = get_db(&rocket).await;

    action_event.deleted = true;
    db.run(|c| ActionEvent::update(action_event, c))
        .await
        .unwrap();
}

async fn assert_cors(response: &LocalResponse<'_>) {
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

#[tokio::test]
async fn cors() {
    let client = Client::untracked(rocket())
        .await
        .expect("valid rocket instance");
    let response = client.get("/version").dispatch().await;
    assert_cors(&response).await;
}

#[tokio::test]
async fn cors_preflight() {
    let client = Client::untracked(rocket())
        .await
        .expect("valid rocket instance");
    let response = client.options("/").dispatch().await;
    assert_cors(&response).await;
}

async fn auth(route: &str, username: &str, password: &str) {
    let rocket = rocket();
    let client = Client::untracked(rocket)
        .await
        .expect("valid rocket instance");
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
    auth(&route("/adm/platform"), ADMIN_USERNAME, ADMIN_PASSWORD).await
}

#[tokio::test]
async fn admin_auth_wrong_credentials() {
    auth_wrong_credentials(&route("/adm/platform"), ADMIN_USERNAME).await;
}

#[tokio::test]
async fn admin_auth_without_credentials() {
    auth_without_credentials(&route("/adm/platform")).await;
}

#[tokio::test]
async fn ap_auth() {
    auth(&route("/ap/action_provider"), AP_USERNAME, AP_PASSWORD).await;
}

#[tokio::test]
async fn ap_auth_wrong_credentials() {
    auth_wrong_credentials(&route("/ap/action_provider"), AP_USERNAME).await;
}

#[tokio::test]
async fn ap_auth_without_credentials() {
    auth_without_credentials(&route("/ap/action_provider")).await;
}

#[tokio::test]
async fn admin_as_ap_auth() {
    auth_as(
        &route("/ap/action_provider"),
        ADMIN_USERNAME,
        AP_ID.0,
        ADMIN_PASSWORD,
    )
    .await;
}

#[tokio::test]
async fn admin_as_ap_auth_wrong_credentials() {
    auth_as_wrong_credentials(&route("/ap/action_provider"), ADMIN_USERNAME, AP_ID.0).await;
}

#[tokio::test]
async fn admin_as_ap_auth_without_credentials() {
    auth_as_without_credentials(&route("/ap/action_provider"), AP_ID.0).await;
}

#[tokio::test]
async fn user_auth() {
    auth(&route("/user"), USER_USERNAME, USER_PASSWORD).await;
}

#[tokio::test]
async fn user_auth_wrong_credentials() {
    auth_wrong_credentials(&route("/user"), USER_USERNAME).await;
}

#[tokio::test]
async fn user_auth_without_credentials() {
    auth_without_credentials(&route("/user")).await;
}

#[tokio::test]
async fn admin_as_user_auth() {
    auth_as(&route("/user"), ADMIN_USERNAME, USER_ID.0, ADMIN_PASSWORD).await;
}

#[tokio::test]
async fn admin_as_user_auth_wrong_credentials() {
    auth_as_wrong_credentials(&route("/user"), ADMIN_USERNAME, USER_ID.0).await;
}

#[tokio::test]
async fn admin_as_user_auth_without_credentials() {
    auth_as_without_credentials(&route("/user"), USER_ID.0).await;
}

#[tokio::test]
async fn user_ap_auth() {
    auth(&route("/diary"), USER_USERNAME, USER_PASSWORD).await;
}

#[tokio::test]
async fn user_ap_auth_wrong_credentials() {
    auth_wrong_credentials(&route("/diary"), USER_USERNAME).await;
}

#[tokio::test]
async fn user_ap_auth_without_credentials() {
    auth_without_credentials(&route("/diary")).await;
}

#[tokio::test]
async fn ap_as_user_ap_auth() {
    // create ActionEvent to ensure access permission for user
    let action_event = ActionEvent {
        id: ActionEventId(rand::thread_rng().gen()),
        user_id: USER_ID,
        action_id: ACTION_ID,
        datetime: Utc::now() + Duration::days(1),
        arguments: None,
        enabled: true,
        last_change: Utc::now(),
        deleted: false,
    };
    create_action_event(action_event.clone()).await;

    auth_as(&route("/diary"), AP_USERNAME, USER_ID.0, AP_PASSWORD).await;

    delete_action_event(action_event).await;
}

#[tokio::test]
async fn ap_as_user_ap_auth_no_event() {
    // create disabled ActionEvent
    let action_event1 = ActionEvent {
        id: ActionEventId(rand::thread_rng().gen()),
        user_id: USER_ID,
        action_id: ACTION_ID,
        datetime: Utc::now() + Duration::days(1),
        arguments: None,
        enabled: false,
        last_change: Utc::now(),
        deleted: false,
    };
    create_action_event(action_event1.clone()).await;

    // create deleted ActionEvent
    let action_event2 = ActionEvent {
        id: ActionEventId(rand::thread_rng().gen()),
        user_id: USER_ID,
        action_id: ACTION_ID,
        datetime: Utc::now() + Duration::days(1),
        arguments: None,
        enabled: true,
        last_change: Utc::now(),
        deleted: true,
    };
    create_action_event(action_event2.clone()).await;

    //  check that ap has no access
    auth_as_not_allowed(&route("/diary"), AP_USERNAME, USER_ID.0, AP_PASSWORD).await;

    delete_action_event(action_event1).await;
    delete_action_event(action_event2).await;
}

#[tokio::test]
async fn ap_as_user_ap_auth_wrong_credentials() {
    // create ActionEvent to ensure access permission for user
    let action_event = ActionEvent {
        id: ActionEventId(rand::thread_rng().gen()),
        user_id: USER_ID,
        action_id: ACTION_ID,
        datetime: Utc::now() + Duration::days(1),
        arguments: None,
        enabled: true,
        last_change: Utc::now(),
        deleted: false,
    };
    create_action_event(action_event.clone()).await;

    auth_as_wrong_credentials(&route("/diary"), AP_USERNAME, USER_ID.0).await;

    delete_action_event(action_event).await;
}

#[tokio::test]
async fn ap_as_user_ap_auth_without_credentials() {
    // create ActionEvent to ensure access permission for user
    let action_event = ActionEvent {
        id: ActionEventId(rand::thread_rng().gen()),
        user_id: USER_ID,
        action_id: ACTION_ID,
        datetime: Utc::now() + Duration::days(1),
        arguments: None,
        enabled: true,
        last_change: Utc::now(),
        deleted: false,
    };
    create_action_event(action_event).await;

    auth_as_without_credentials(&route("/diary"), USER_ID.0).await;
}

#[tokio::test]
async fn admin_as_user_ap_auth() {
    auth_as(&route("/diary"), ADMIN_USERNAME, USER_ID.0, ADMIN_PASSWORD).await;
}

#[tokio::test]
async fn admin_as_user_ap_auth_wrong_credentials() {
    auth_as_wrong_credentials(&route("/diary"), ADMIN_USERNAME, USER_ID.0).await;
}

#[tokio::test]
async fn admin_as_user_ap_auth_without_credentials() {
    auth_as_without_credentials(&route("/diary"), USER_ID.0).await;
}

//#[allow(clippy::needless_lifetimes)]
async fn create_diary<'c>(
    client: &'c Client,
    username: &str,
    password: &str,
    user_id: i64,
) -> (DiaryId, LocalResponse<'c>) {
    let mut request = client.post("/v0.2/diary");
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
    let (_, response) = create_diary(&client, USER_USERNAME, USER_PASSWORD, USER_ID.0).await;
    assert_ok_json(&response);

    // check that create does not work for other user
    let (_, response) = create_diary(&client, USER2_USERNAME, USER2_PASSWORD, USER_ID.0).await;
    assert_forbidden_json(&response);
}

#[tokio::test]
async fn foreign_get() {
    let client = Client::untracked(rocket())
        .await
        .expect("valid rocket instance");

    let (diary_id, response) = create_diary(&client, USER_USERNAME, USER_PASSWORD, USER_ID.0).await;
    assert_ok_json(&response);

    // check that get works for same user
    let mut request = client.get(format!("{}/{}", route("/diary"), diary_id.0));
    request.add_header(basic_auth(USER_USERNAME, USER_PASSWORD));
    let response = request.dispatch().await;
    assert_ok_json(&response);

    // check that get does not work for other user
    let mut request = client.get(format!("{}/{}", route("/diary"), diary_id.0));

    request.add_header(basic_auth(USER2_USERNAME, USER2_PASSWORD));
    let response = request.dispatch().await;
    assert_forbidden_json(&response);
}

#[tokio::test]
async fn foreign_update() {
    let client = Client::untracked(rocket())
        .await
        .expect("valid rocket instance");

    let (diary_id, response) = create_diary(&client, USER_USERNAME, USER_PASSWORD, USER_ID.0).await;
    assert_ok_json(&response);

    let diary = Diary {
        id: diary_id,
        user_id: USER_ID,
        date: NaiveDate::from_num_days_from_ce(rand::thread_rng().gen::<i32>() % 1_500_000),
        bodyweight: None,
        comments: None,
        last_change: Utc::now(),
        deleted: false,
    };

    // check that update works for same user
    let route = route("/diary");
    let mut request = client.put(&route);
    request.add_header(basic_auth(USER_USERNAME, USER_PASSWORD));
    let request = request.json(&diary);
    let response = request.dispatch().await;
    assert_ok_json(&response);

    // check that update does not work for other user
    let mut request = client.put(&route);
    request.add_header(basic_auth(USER2_USERNAME, USER2_PASSWORD));
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

    let route = route("/user");
    let request = client.post(&route);
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

    let platform_route = route("/ap/platform");
    let request = client.post(&platform_route);
    let request = request.json(&platform);
    let response = request.dispatch().await;

    if config.ap_self_registration {
        assert_ok_json(&response);
    } else {
        assert_forbidden_json(&response);
    }

    let request = client.get(&platform_route);
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
        platform_id: PLATFORM_ID,
        description: None,
        last_change: Utc::now(),
        deleted: false,
    };

    let ap_route = route("/ap/action_provider");
    let request = client.post(&ap_route);
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
        user_id: USER_ID,
        date: NaiveDate::from_num_days_from_ce(rand::thread_rng().gen::<i32>() % 1_500_000),
        bodyweight: None,
        comments: None,
        last_change: Utc::now(),
        deleted: false,
    };

    let route = route("/diary");
    let mut request = client.put(&route);
    request.add_header(basic_auth(USER_USERNAME, USER_PASSWORD));
    let request = request.json(&diary);
    let response = request.dispatch().await;
    assert_forbidden_json(&response);
}

// create directly without handler && use test transaction
