use axum::{
    body::Body,
    headers::HeaderName,
    http::{
        header::{AUTHORIZATION, CONTENT_TYPE},
        Request, StatusCode,
    },
    response::Response,
    Router,
};
use base64::{engine::general_purpose::STANDARD, Engine};
use chrono::{Duration, Utc};
use diesel::r2d2::{ConnectionManager, CustomizeConnection, Pool};
use mime::APPLICATION_JSON;
use rand::Rng;
use sport_log_types::{
    uri::{route_max_version, ADM_PLATFORM, AP_ACTION_PROVIDER, AP_PLATFORM, DIARY, USER},
    Action, ActionEvent, ActionEventId, ActionId, ActionProvider, ActionProviderId, AppState,
    Config, Create, DbPool, Diary, DiaryId, Platform, PlatformId, User, UserId, ADMIN_USERNAME,
};
use tower::{Service, ServiceExt};

use crate::{get_config, router};

const ADMIN_PASSWORD: &str = "admin-passwd";

lazy_static! {
    static ref TEST_USER: User = User {
        id: UserId(123456789),
        username: String::from("test-user-username-123456789"),
        password: String::from("test-user-password-123456789"),
        email: String::from("test-user-email-123456789"),
    };
    static ref TEST_USER2: User = User {
        id: UserId(213456789),
        username: String::from("test-user2-username-213456789"),
        password: String::from("test-user2-password-213456789"),
        email: String::from("test-user2-email-213456789"),
    };
    static ref TEST_PLATFORM: Platform = Platform {
        id: PlatformId(123456789),
        name: String::from("test-platform-123456789"),
        credential: false,
        deleted: false,
    };
    static ref TEST_AP: ActionProvider = ActionProvider {
        id: ActionProviderId(123456789),
        name: String::from("test-ap-name-123456789"),
        password: String::from("test-ap-password-123456789"),
        platform_id: TEST_PLATFORM.id,
        description: None,
        deleted: false,
    };
    static ref TEST_ACTION: Action = Action {
        id: ActionId(123456789),
        name: String::from("test-action-name-123456789"),
        action_provider_id: TEST_AP.id,
        description: None,
        create_before: 1,
        delete_after: 1,
        deleted: false,
    };
    static ref TEST_DIARY: Diary = Diary {
        id: DiaryId(123456789),
        user_id: TEST_USER.id,
        date: Utc::now().date_naive(),
        bodyweight: None,
        comments: None,
        deleted: false,
    };
}

#[derive(Debug, Clone, Copy)]
pub struct TestConnectionCustomizer;

impl<C, E> CustomizeConnection<C, E> for TestConnectionCustomizer
where
    C: diesel::Connection,
{
    fn on_acquire(&self, conn: &mut C) -> Result<(), E> {
        conn.begin_test_transaction()
            .expect("Failed to start test transaction");

        Ok(())
    }
}

fn get_test_db_pool(config: &Config) -> DbPool {
    Pool::builder()
        .connection_customizer(Box::new(TestConnectionCustomizer))
        .max_size(1)
        .build(ConnectionManager::new(&config.database_url))
        .unwrap()
}

async fn init() -> (Router, DbPool, &'static Config) {
    // Make sure to drop any reference to DbConn before invoking router,
    // because otherwise handlers will time out trying to retrieve a connection from the pool.

    let config = Box::leak(Box::new(get_config().await.unwrap()));

    let db_pool = get_test_db_pool(config);

    let state = AppState {
        db_pool: db_pool.clone(),
        config,
    };

    let router = router::get_router(state).await;

    let mut db = db_pool.get().unwrap();

    User::create(&mut TEST_USER.clone(), &mut db).unwrap();
    User::create(&mut TEST_USER2.clone(), &mut db).unwrap();
    Platform::create(&TEST_PLATFORM, &mut db).unwrap();
    ActionProvider::create(&mut TEST_AP.clone(), &mut db).unwrap();
    Action::create(&TEST_ACTION, &mut db).unwrap();

    (router, db_pool, config)
}

//async fn assert_cors(response: &Response) {
//assert_eq!(
//response
//.headers()
//.get(ACCESS_CONTROL_ALLOW_ORIGIN.as_str())
//.unwrap(),
//"*"
//);
//assert_eq!(
//response
//.headers()
//.get(ACCESS_CONTROL_ALLOW_METHODS.as_str())
//.unwrap(),
//"POST, GET, PUT, DELETE, OPTIONS"
//);
//assert_eq!(
//response
//.headers()
//.get(ACCESS_CONTROL_ALLOW_HEADERS.as_str())
//.unwrap(),
//"*"
//);
//assert_eq!(
//response
//.headers()
//.get(ACCESS_CONTROL_ALLOW_CREDENTIALS.as_str())
//.unwrap(),
//"true"
//);
//assert_eq!(
//response
//.headers()
//.get(ACCESS_CONTROL_MAX_AGE.as_str())
//.unwrap(),
//"864000"
//);
//}

//#[tokio::test]
//async fn cors() {
//let (mut router, _, _) = init().await;

//let response = router
//.ready()
//.await
//.unwrap()
//.call(Request::get(VERSION).body(Body::empty()).unwrap())
//.await
//.unwrap();
//assert_cors(&response).await;
//}

//#[tokio::test]
//async fn cors_preflight() {
//let (mut router, _, _) = init().await;

//let response = router
//.ready()
//.await
//.unwrap()
//.call(Request::options("/").body(Body::empty()).unwrap())
//.await
//.unwrap();
//assert_cors(&response).await;
//}

fn rnd() -> i64 {
    rand::thread_rng().gen()
}

fn basic_auth(username: &str, password: &str) -> (HeaderName, String) {
    (
        AUTHORIZATION,
        format!(
            "Basic {}",
            STANDARD.encode(format!("{}:{}", username, password))
        ),
    )
}

fn basic_auth_as(username: &str, id: i64, password: &str) -> (HeaderName, String) {
    (
        AUTHORIZATION,
        format!(
            "Basic {}",
            STANDARD.encode(format!("{}$id${}:{}", username, id, password))
        ),
    )
}

fn assert_status(response: &Response, status: StatusCode) {
    assert_eq!(status, response.status());
}

fn assert_json(response: &Response) {
    assert_eq!(
        response.headers().get(CONTENT_TYPE).unwrap(),
        APPLICATION_JSON.as_ref(),
    );
}

/// Use a get request to make sure that the authentication succeeds.
async fn auth(router: &mut Router, route: &str, username: &str, password: &str) {
    let header = basic_auth(username, password);
    let response = router
        .ready()
        .await
        .unwrap()
        .call(
            Request::get(route)
                .header(header.0, header.1)
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_status(&response, StatusCode::OK);
    assert_json(&response);
}

/// Use a get request to make sure that the authentication with wrong credentials does not succeed.
async fn auth_wrong_credentials(router: &mut Router, route: &str, username: &str) {
    let header = basic_auth(username, "wrong password");
    let response = router
        .ready()
        .await
        .unwrap()
        .call(
            Request::get(route)
                .header(header.0, header.1)
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_status(&response, StatusCode::UNAUTHORIZED);
    assert_json(&response);

    let header = basic_auth("wrong username", "wrong password");
    let response = router
        .ready()
        .await
        .unwrap()
        .call(
            Request::get(route)
                .header(header.0, header.1)
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_status(&response, StatusCode::UNAUTHORIZED);
    assert_json(&response);
}

/// Use a get request to make sure that the authentication without credentials does not succeed.
async fn auth_without_credentials(router: &mut Router, route: &str) {
    let response = router
        .ready()
        .await
        .unwrap()
        .call(Request::get(route).body(Body::empty()).unwrap())
        .await
        .unwrap();

    assert_status(&response, StatusCode::UNAUTHORIZED);
    assert_json(&response);
}

/// Use a get request to make sure that the authentication as a user succeeds.
async fn auth_as(router: &mut Router, route: &str, username: &str, id: i64, password: &str) {
    let header = basic_auth_as(username, id, password);
    let response = router
        .ready()
        .await
        .unwrap()
        .call(
            Request::get(route)
                .header(header.0, header.1)
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_status(&response, StatusCode::OK);
    assert_json(&response);
}

/// Use a get request to make sure that the authentication as a user does not succeed.
async fn auth_as_not_allowed(
    router: &mut Router,
    route: &str,
    username: &str,
    id: i64,
    password: &str,
) {
    let header = basic_auth_as(username, id, password);
    let response = router
        .ready()
        .await
        .unwrap()
        .call(
            Request::get(route)
                .header(header.0, header.1)
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_status(&response, StatusCode::FORBIDDEN);
    assert_json(&response);
}

/// Use a get request to make sure that the authentication as a user with wrong credentials does not succeed.
async fn auth_as_wrong_credentials(router: &mut Router, route: &str, username: &str, id: i64) {
    let header = basic_auth_as(username, id, "wrong password");
    let response = router
        .ready()
        .await
        .unwrap()
        .call(
            Request::get(route)
                .header(header.0, header.1)
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_status(&response, StatusCode::UNAUTHORIZED);
    assert_json(&response);

    let header = basic_auth_as("wrong username", 1, "wrong password");
    let response = router
        .ready()
        .await
        .unwrap()
        .call(
            Request::get(route)
                .header(header.0, header.1)
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_status(&response, StatusCode::UNAUTHORIZED);
    assert_json(&response);
}

/// Use a get request to make sure that the authentication as a user without credentials does not succeed.
async fn auth_as_without_credentials(router: &mut Router, route: &str, id: i64) {
    let header = basic_auth_as("", id, "wrong password");
    let response = router
        .ready()
        .await
        .unwrap()
        .call(
            Request::get(route)
                .header(header.0, header.1)
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_status(&response, StatusCode::UNAUTHORIZED);
    assert_json(&response);
}

#[tokio::test]
async fn admin_auth() {
    let (mut router, _, _) = init().await;
    auth(
        &mut router,
        &route_max_version("", ADM_PLATFORM, &[]),
        ADMIN_USERNAME,
        ADMIN_PASSWORD,
    )
    .await
}

#[tokio::test]
async fn admin_auth_wrong_credentials() {
    let (mut router, _, _) = init().await;
    auth_wrong_credentials(
        &mut router,
        &route_max_version("", ADM_PLATFORM, &[]),
        ADMIN_USERNAME,
    )
    .await;
}

#[tokio::test]
async fn admin_auth_without_credentials() {
    let (mut router, _, _) = init().await;
    auth_without_credentials(&mut router, &route_max_version("", ADM_PLATFORM, &[])).await;
}

#[tokio::test]
async fn ap_auth() {
    let (mut router, _, _) = init().await;
    auth(
        &mut router,
        &route_max_version("", AP_ACTION_PROVIDER, &[]),
        &TEST_AP.name,
        &TEST_AP.password,
    )
    .await;
}

#[tokio::test]
async fn ap_auth_wrong_credentials() {
    let (mut router, _, _) = init().await;
    auth_wrong_credentials(
        &mut router,
        &route_max_version("", AP_ACTION_PROVIDER, &[]),
        &TEST_AP.name,
    )
    .await;
}

#[tokio::test]
async fn ap_auth_without_credentials() {
    let (mut router, _, _) = init().await;
    auth_without_credentials(&mut router, &route_max_version("", AP_ACTION_PROVIDER, &[])).await;
}

#[tokio::test]
async fn admin_as_ap_auth() {
    let (mut router, _, _) = init().await;
    auth_as(
        &mut router,
        &route_max_version("", AP_ACTION_PROVIDER, &[]),
        ADMIN_USERNAME,
        TEST_AP.id.0,
        ADMIN_PASSWORD,
    )
    .await;
}

#[tokio::test]
async fn admin_as_ap_auth_wrong_credentials() {
    let (mut router, _, _) = init().await;
    auth_as_wrong_credentials(
        &mut router,
        &route_max_version("", AP_ACTION_PROVIDER, &[]),
        ADMIN_USERNAME,
        TEST_AP.id.0,
    )
    .await;
}

#[tokio::test]
async fn admin_as_ap_auth_without_credentials() {
    let (mut router, _, _) = init().await;
    auth_as_without_credentials(
        &mut router,
        &route_max_version("", AP_ACTION_PROVIDER, &[]),
        TEST_AP.id.0,
    )
    .await;
}

#[tokio::test]
async fn user_auth() {
    let (mut router, _, _) = init().await;
    auth(
        &mut router,
        &route_max_version("", USER, &[]),
        &TEST_USER.username,
        &TEST_USER.password,
    )
    .await;
}

#[tokio::test]
async fn user_auth_wrong_credentials() {
    let (mut router, _, _) = init().await;
    auth_wrong_credentials(
        &mut router,
        &route_max_version("", USER, &[]),
        &TEST_USER.username,
    )
    .await;
}

#[tokio::test]
async fn user_auth_without_credentials() {
    let (mut router, _, _) = init().await;
    auth_without_credentials(&mut router, &route_max_version("", USER, &[])).await;
}

#[tokio::test]
async fn admin_as_user_auth() {
    let (mut router, _, _) = init().await;
    auth_as(
        &mut router,
        &route_max_version("", USER, &[]),
        ADMIN_USERNAME,
        TEST_USER.id.0,
        ADMIN_PASSWORD,
    )
    .await;
}

#[tokio::test]
async fn admin_as_user_auth_wrong_credentials() {
    let (mut router, _, _) = init().await;
    auth_as_wrong_credentials(
        &mut router,
        &route_max_version("", USER, &[]),
        ADMIN_USERNAME,
        TEST_USER.id.0,
    )
    .await;
}

#[tokio::test]
async fn admin_as_user_auth_without_credentials() {
    let (mut router, _, _) = init().await;
    auth_as_without_credentials(
        &mut router,
        &route_max_version("", USER, &[]),
        TEST_USER.id.0,
    )
    .await;
}

#[tokio::test]
async fn user_ap_auth() {
    let (mut router, _, _) = init().await;
    auth(
        &mut router,
        &route_max_version("", DIARY, &[]),
        &TEST_USER.username,
        &TEST_USER.password,
    )
    .await;
}

#[tokio::test]
async fn user_ap_auth_wrong_credentials() {
    let (mut router, _, _) = init().await;
    auth_wrong_credentials(
        &mut router,
        &route_max_version("", DIARY, &[]),
        &TEST_USER.username,
    )
    .await;
}

#[tokio::test]
async fn user_ap_auth_without_credentials() {
    let (mut router, _, _) = init().await;
    auth_without_credentials(&mut router, &route_max_version("", DIARY, &[])).await;
}

#[tokio::test]
async fn ap_as_user_ap_auth() {
    let (mut router, db_pool, _) = init().await;

    // create ActionEvent to ensure access permission for user
    let action_event = ActionEvent {
        id: ActionEventId(rnd()),
        user_id: TEST_USER.id,
        action_id: TEST_ACTION.id,
        datetime: Utc::now() + Duration::days(1),
        arguments: None,
        enabled: true,
        deleted: false,
    };
    ActionEvent::create(&action_event, &mut db_pool.get().unwrap()).unwrap();

    auth_as(
        &mut router,
        &route_max_version("", DIARY, &[]),
        &TEST_AP.name,
        TEST_USER.id.0,
        &TEST_AP.password,
    )
    .await;
}

#[tokio::test]
async fn ap_as_user_ap_auth_no_event() {
    let (mut router, db_pool, _) = init().await;

    // create disabled ActionEvent
    let action_event1 = ActionEvent {
        id: ActionEventId(rnd()),
        user_id: TEST_USER.id,
        action_id: TEST_ACTION.id,
        datetime: Utc::now() + Duration::days(1),
        arguments: None,
        enabled: false,
        deleted: false,
    };
    ActionEvent::create(&action_event1, &mut db_pool.get().unwrap()).unwrap();

    // create deleted ActionEvent
    let action_event2 = ActionEvent {
        id: ActionEventId(rnd()),
        user_id: TEST_USER.id,
        action_id: TEST_ACTION.id,
        datetime: Utc::now() + Duration::days(1),
        arguments: None,
        enabled: true,
        deleted: true,
    };
    ActionEvent::create(&action_event2, &mut db_pool.get().unwrap()).unwrap();

    //  check that ap has no access
    auth_as_not_allowed(
        &mut router,
        &route_max_version("", DIARY, &[]),
        &TEST_AP.name,
        TEST_USER.id.0,
        &TEST_AP.password,
    )
    .await;
}

#[tokio::test]
async fn ap_as_user_ap_auth_wrong_credentials() {
    let (mut router, db_pool, _) = init().await;

    // create ActionEvent to ensure access permission for user
    let action_event = ActionEvent {
        id: ActionEventId(rnd()),
        user_id: TEST_USER.id,
        action_id: TEST_ACTION.id,
        datetime: Utc::now() + Duration::days(1),
        arguments: None,
        enabled: true,
        deleted: false,
    };
    ActionEvent::create(&action_event, &mut db_pool.get().unwrap()).unwrap();

    auth_as_wrong_credentials(
        &mut router,
        &route_max_version("", DIARY, &[]),
        &TEST_AP.name,
        TEST_USER.id.0,
    )
    .await;
}

#[tokio::test]
async fn ap_as_user_ap_auth_without_credentials() {
    let (mut router, db_pool, _) = init().await;

    // create ActionEvent to ensure access permission for user
    let action_event = ActionEvent {
        id: ActionEventId(rnd()),
        user_id: TEST_USER.id,
        action_id: TEST_ACTION.id,
        datetime: Utc::now() + Duration::days(1),
        arguments: None,
        enabled: true,
        deleted: false,
    };
    ActionEvent::create(&action_event, &mut db_pool.get().unwrap()).unwrap();

    auth_as_without_credentials(
        &mut router,
        &route_max_version("", DIARY, &[]),
        TEST_USER.id.0,
    )
    .await;
}

#[tokio::test]
async fn admin_as_user_ap_auth() {
    let (mut router, _, _) = init().await;

    auth_as(
        &mut router,
        &route_max_version("", DIARY, &[]),
        ADMIN_USERNAME,
        TEST_USER.id.0,
        ADMIN_PASSWORD,
    )
    .await;
}

#[tokio::test]
async fn admin_as_user_ap_auth_wrong_credentials() {
    let (mut router, _, _) = init().await;

    auth_as_wrong_credentials(
        &mut router,
        &route_max_version("", DIARY, &[]),
        ADMIN_USERNAME,
        TEST_USER.id.0,
    )
    .await;
}

#[tokio::test]
async fn admin_as_user_ap_auth_without_credentials() {
    let (mut router, _, _) = init().await;

    auth_as_without_credentials(
        &mut router,
        &route_max_version("", DIARY, &[]),
        TEST_USER.id.0,
    )
    .await;
}

#[tokio::test]
async fn own_create() {
    let (mut router, _, _) = init().await;

    // check that create works for same user
    let header = basic_auth(&TEST_USER.username, &TEST_USER.password);
    let response = router
        .ready()
        .await
        .unwrap()
        .call(
            Request::post(route_max_version("", DIARY, &[]))
                .header(header.0, header.1)
                .header(CONTENT_TYPE, APPLICATION_JSON.as_ref())
                .body(serde_json::to_string(&TEST_DIARY as &Diary).unwrap().into())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_status(&response, StatusCode::OK);
}

#[tokio::test]
async fn foreign_create() {
    let (mut router, _, _) = init().await;

    // check that create does not work for other user
    let header = basic_auth(&TEST_USER2.username, &TEST_USER2.password);
    let response = router
        .ready()
        .await
        .unwrap()
        .call(
            Request::post(route_max_version("", DIARY, &[]))
                .header(header.0, header.1)
                .header(CONTENT_TYPE, APPLICATION_JSON.as_ref())
                .body(serde_json::to_string(&TEST_DIARY as &Diary).unwrap().into())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_status(&response, StatusCode::FORBIDDEN);
}

#[tokio::test]
async fn own_get() {
    let (mut router, db_pool, _) = init().await;

    Diary::create(&TEST_DIARY, &mut db_pool.get().unwrap()).unwrap();

    // check that get works for same user
    let header = basic_auth(&TEST_USER.username, &TEST_USER.password);
    let response = router
        .ready()
        .await
        .unwrap()
        .call(
            Request::get(route_max_version(
                "",
                DIARY,
                &[("id", &TEST_DIARY.id.0.to_string())],
            ))
            .header(header.0, header.1)
            .body(Body::empty())
            .unwrap(),
        )
        .await
        .unwrap();

    assert_status(&response, StatusCode::OK);
}

#[tokio::test]
async fn foreign_get() {
    let (mut router, db_pool, _) = init().await;

    Diary::create(&TEST_DIARY, &mut db_pool.get().unwrap()).unwrap();

    // check that get does not work for other user
    let header = basic_auth(&TEST_USER2.username, &TEST_USER2.password);
    let response = router
        .ready()
        .await
        .unwrap()
        .call(
            Request::get(route_max_version(
                "",
                DIARY,
                &[("id", &TEST_DIARY.id.0.to_string())],
            ))
            .header(header.0, header.1)
            .body(Body::empty())
            .unwrap(),
        )
        .await
        .unwrap();

    assert_status(&response, StatusCode::FORBIDDEN);
}

#[tokio::test]
async fn own_update() {
    let (mut router, db_pool, _) = init().await;

    Diary::create(&TEST_DIARY, &mut db_pool.get().unwrap()).unwrap();

    // check that update works for same user
    let header = basic_auth(&TEST_USER.username, &TEST_USER.password);
    let response = router
        .ready()
        .await
        .unwrap()
        .call(
            Request::put(&route_max_version("", DIARY, &[]))
                .header(header.0, header.1)
                .header(CONTENT_TYPE, APPLICATION_JSON.as_ref())
                .body(serde_json::to_string(&TEST_DIARY as &Diary).unwrap().into())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_status(&response, StatusCode::OK);
}

#[tokio::test]
async fn foreign_update() {
    let (mut router, db_pool, _) = init().await;

    Diary::create(&TEST_DIARY, &mut db_pool.get().unwrap()).unwrap();

    // check that update does not work for other user
    let header = basic_auth(&TEST_USER2.username, &TEST_USER2.password);
    let response = router
        .ready()
        .await
        .unwrap()
        .call(
            Request::put(&route_max_version("", DIARY, &[]))
                .header(header.0, header.1)
                .header(CONTENT_TYPE, APPLICATION_JSON.as_ref())
                .body(serde_json::to_string(&TEST_DIARY as &Diary).unwrap().into())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_status(&response, StatusCode::FORBIDDEN);
}

#[tokio::test]
async fn user_self_registration() {
    let (mut router, _, config) = init().await;

    let user_id = UserId(rnd());
    let user = User {
        id: user_id,
        username: format!("user{}", user_id.0),
        password: "password".to_owned(),
        email: format!("email{}", user_id.0),
    };

    let response = router
        .ready()
        .await
        .unwrap()
        .call(
            Request::post(&route_max_version("", USER, &[]))
                .header(CONTENT_TYPE, APPLICATION_JSON.as_ref())
                .body(serde_json::to_string(&user).unwrap().into())
                .unwrap(),
        )
        .await
        .unwrap();

    if config.user_self_registration {
        assert_status(&response, StatusCode::OK);
    } else {
        assert_status(&response, StatusCode::FORBIDDEN);
    }
}

#[tokio::test]
async fn ap_self_registration() {
    let (mut router, _, config) = init().await;

    let platform_id = PlatformId(rnd());
    let platform = Platform {
        id: platform_id,
        name: format!("platform{}", platform_id.0),
        credential: false,
        deleted: false,
    };

    let response = router
        .ready()
        .await
        .unwrap()
        .call(
            Request::post(&route_max_version("", AP_PLATFORM, &[]))
                .header(CONTENT_TYPE, APPLICATION_JSON.as_ref())
                .body(serde_json::to_string(&platform).unwrap().into())
                .unwrap(),
        )
        .await
        .unwrap();

    if config.ap_self_registration {
        assert_status(&response, StatusCode::OK);
    } else {
        assert_status(&response, StatusCode::FORBIDDEN);
    }

    let response = router
        .ready()
        .await
        .unwrap()
        .call(
            Request::get(&route_max_version("", AP_PLATFORM, &[]))
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();

    if config.ap_self_registration {
        assert_status(&response, StatusCode::OK);
    } else {
        assert_status(&response, StatusCode::FORBIDDEN);
    }

    let ap_id = ActionProviderId(rnd());
    let action_provider = ActionProvider {
        id: ap_id,
        name: format!("ap{}", ap_id.0),
        password: "password".to_owned(),
        platform_id: TEST_PLATFORM.id,
        description: None,
        deleted: false,
    };

    let response = router
        .ready()
        .await
        .unwrap()
        .call(
            Request::post(&route_max_version("", AP_ACTION_PROVIDER, &[]))
                .header(CONTENT_TYPE, APPLICATION_JSON.as_ref())
                .body(serde_json::to_string(&action_provider).unwrap().into())
                .unwrap(),
        )
        .await
        .unwrap();

    if config.ap_self_registration {
        assert_status(&response, StatusCode::OK);
    } else {
        assert_status(&response, StatusCode::FORBIDDEN);
    }
}

#[tokio::test]
async fn update_non_existing() {
    let (mut router, _, _) = init().await;

    let header = basic_auth(&TEST_USER.username, &TEST_USER.password);
    let response = router
        .ready()
        .await
        .unwrap()
        .call(
            Request::put(&route_max_version("", DIARY, &[]))
                .header(header.0, header.1)
                .header(CONTENT_TYPE, APPLICATION_JSON.as_ref())
                .body(serde_json::to_string(&TEST_DIARY as &Diary).unwrap().into())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_status(&response, StatusCode::FORBIDDEN);
}
