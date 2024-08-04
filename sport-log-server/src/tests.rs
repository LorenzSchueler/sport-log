use std::{io::Write, sync::LazyLock};

use axum::{
    body::{self, Body},
    http::{
        header::{ACCEPT_ENCODING, AUTHORIZATION, CONTENT_TYPE},
        HeaderName, HeaderValue, Request, StatusCode,
    },
    response::Response,
    Router,
};
use base64::{engine::general_purpose::STANDARD, Engine};
use chrono::{Duration, Utc};
use diesel_async::{
    pooled_connection::{
        deadpool::{Hook, Pool},
        AsyncDieselConnectionManager,
    },
    AsyncConnection, AsyncPgConnection,
};
use flate2::write::GzDecoder;
use hyper::header::CONTENT_ENCODING;
use mime::APPLICATION_JSON;
use rand::Rng;
use serde::de::DeserializeOwned;
use sport_log_types::{
    uri::{
        route_max_version, ACCOUNT_DATA, ADM_PLATFORM, AP_ACTION_PROVIDER, AP_PLATFORM, DIARY, USER,
    },
    AccountData, Action, ActionEvent, ActionEventId, ActionId, ActionProvider, ActionProviderId,
    Diary, DiaryId, Epoch, EpochResponse, Platform, PlatformId, User, UserId, ADMIN_USERNAME,
    ID_HEADER,
};
use tower::Service;

use crate::{
    config::Config,
    db::*,
    get_config, router,
    state::{AppState, DbPool},
};

const ADMIN_PASSWORD_PLAINTEXT: &str = "admin-passwd";

static TEST_USER: LazyLock<User> = LazyLock::new(|| User {
    id: UserId(123_456_789),
    username: String::from("test-user-username-123456789"),
    password: String::from("test-user-Password-123456789"),
    email: String::from("test-user-email-123456789"),
});
static TEST_USER2: LazyLock<User> = LazyLock::new(|| User {
    id: UserId(213_456_789),
    username: String::from("test-user2-username-213456789"),
    password: String::from("test-user2-Password-213456789"),
    email: String::from("test-user2-email-213456789"),
});
static TEST_PLATFORM: LazyLock<Platform> = LazyLock::new(|| Platform {
    id: PlatformId(123_456_789),
    name: String::from("test-platform-123456789"),
    credential: false,
    deleted: false,
});
static TEST_AP: LazyLock<ActionProvider> = LazyLock::new(|| ActionProvider {
    id: ActionProviderId(123_456_789),
    name: String::from("test-ap-name-123456789"),
    password: String::from("test-ap-Password-123456789"),
    platform_id: TEST_PLATFORM.id,
    description: None,
    deleted: false,
});
static TEST_ACTION: LazyLock<Action> = LazyLock::new(|| Action {
    id: ActionId(123_456_789),
    name: String::from("test-action-name-123456789"),
    action_provider_id: TEST_AP.id,
    description: None,
    create_before: 1,
    delete_after: 1,
    deleted: false,
});
static TEST_DIARY: LazyLock<Diary> = LazyLock::new(|| Diary {
    id: DiaryId(123_456_789),
    user_id: TEST_USER.id,
    date: Utc::now().date_naive(),
    bodyweight: None,
    comments: None,
    deleted: false,
});

fn get_test_db_pool(config: &Config) -> DbPool {
    let db_config = AsyncDieselConnectionManager::<AsyncPgConnection>::new(&config.database_url);

    Pool::builder(db_config)
        .post_create(Hook::AsyncFn(Box::new(
            |conn: &mut AsyncPgConnection, _| {
                Box::pin(async {
                    conn.begin_test_transaction()
                        .await
                        .expect("Failed to start test transaction");
                    Ok(())
                })
            },
        )))
        .max_size(1)
        .build()
        .unwrap()
}

async fn init() -> (Router, DbPool, &'static Config) {
    // Every test case calls [`init`] to get the router (and if needed also the db pool and the
    // config). Therefore all test will have their own db pools.
    // For each pool there is only a single database connection that uses a test transaction (which
    // is never committed). By restricting the number of connections to a single one per db
    // pool, the connection that can be retrieved from the pool in order to run setup code
    // is guaranteed to be the same one that will be later used by the axum handlers.
    // Make sure to drop any reference to DbConn before invoking router,
    // because otherwise handlers will time out trying to retrieve a connection from the pool.

    let config = Box::leak(Box::new(get_config().await.unwrap()));

    let db_pool = get_test_db_pool(config);

    let state = AppState {
        db_pool: db_pool.clone(),
        config,
    };

    let router = router::get_router(state);

    let mut db = db_pool.get().await.unwrap();

    UserDb::create(&mut TEST_USER.clone(), &mut db)
        .await
        .unwrap();
    UserDb::create(&mut TEST_USER2.clone(), &mut db)
        .await
        .unwrap();
    PlatformDb::create(&TEST_PLATFORM, &mut db).await.unwrap();
    ActionProviderDb::create(&mut TEST_AP.clone(), &mut db)
        .await
        .unwrap();
    ActionDb::create(&TEST_ACTION, &mut db).await.unwrap();

    (router, db_pool, config)
}

fn rnd() -> i64 {
    rand::thread_rng().gen()
}

fn auth_header(username: &str, password: &str) -> (HeaderName, String) {
    (
        AUTHORIZATION,
        format!(
            "Basic {}",
            STANDARD.encode(format!("{username}:{password}"))
        ),
    )
}

fn auth_as_headers(username: &str, id: i64, password: &str) -> [(HeaderName, String); 2] {
    [auth_header(username, password), (ID_HEADER, id.to_string())]
}

fn assert_json(response: &Response) {
    assert!(response.headers().contains_key(CONTENT_TYPE));
    assert_eq!(
        response.headers().get(CONTENT_TYPE).unwrap(),
        APPLICATION_JSON.as_ref(),
    );
}

async fn request(router: &mut Router, request: Request<Body>) -> Response {
    <axum::Router as tower::ServiceExt<Request<Body>>>::ready(router)
        .await
        .unwrap()
        .call(request)
        .await
        .unwrap()
}

async fn account_data_request(
    router: &mut Router,
    epoch: Option<Epoch>,
) -> (StatusCode, AccountData) {
    let header = auth_header(&TEST_USER.username, &TEST_USER.password);
    let epoch = epoch.map(|epoch| epoch.0.to_string());
    let epoch = epoch.as_ref();
    let query = epoch.map(|epoch| [("epoch", epoch.as_str())]);
    let query = query.as_ref().map(<[_; 1]>::as_slice);
    let response = request(
        router,
        Request::get(route_max_version("", ACCOUNT_DATA, query))
            .header(header.0, header.1)
            .body(Body::empty())
            .unwrap(),
    )
    .await;

    let status = response.status();
    let account_data = parse_body(response).await;
    (status, account_data)
}

async fn parse_body<T: DeserializeOwned>(response: Response) -> T {
    let bytes = body::to_bytes(response.into_body(), usize::MAX)
        .await
        .unwrap();
    let data = std::str::from_utf8(&bytes).unwrap();
    serde_json::from_str(data).unwrap()
}

async fn parse_gzip_body<T: DeserializeOwned>(response: Response) -> T {
    let bytes = body::to_bytes(response.into_body(), usize::MAX)
        .await
        .unwrap();
    let mut decoded = Vec::new();
    let mut decoder = GzDecoder::new(decoded);
    decoder.write_all(&bytes).unwrap();
    decoded = decoder.finish().unwrap();
    let data = std::str::from_utf8(&decoded).unwrap();
    serde_json::from_str(data).unwrap()
}

/// Use a get request to make sure that the authentication succeeds.
async fn auth(router: &mut Router, route: &str, username: &str, password: &str) {
    let header = auth_header(username, password);
    let response = request(
        router,
        Request::get(route)
            .header(header.0, header.1)
            .body(Body::empty())
            .unwrap(),
    )
    .await;

    assert_eq!(response.status(), StatusCode::OK);
    assert_json(&response);
}

/// Use a get request to make sure that the authentication with wrong
/// credentials does not succeed.
async fn auth_wrong_credentials(router: &mut Router, route: &str, username: &str) {
    let header = auth_header(username, "wrong password");
    let response = request(
        router,
        Request::get(route)
            .header(header.0, header.1)
            .body(Body::empty())
            .unwrap(),
    )
    .await;

    assert_eq!(response.status(), StatusCode::UNAUTHORIZED);
    assert_json(&response);

    let header = auth_header("wrong username", "wrong password");
    let response = request(
        router,
        Request::get(route)
            .header(header.0, header.1)
            .body(Body::empty())
            .unwrap(),
    )
    .await;

    assert_eq!(response.status(), StatusCode::UNAUTHORIZED);
    assert_json(&response);
}

/// Use a get request to make sure that the authentication without credentials
/// does not succeed.
async fn auth_without_credentials(router: &mut Router, route: &str) {
    let response = request(router, Request::get(route).body(Body::empty()).unwrap()).await;

    assert_eq!(response.status(), StatusCode::UNAUTHORIZED);
    assert_json(&response);
}

/// Use a get request to make sure that the authentication as a user succeeds.
async fn auth_as(router: &mut Router, route: &str, username: &str, id: i64, password: &str) {
    let [basic_header, user_id_header] = auth_as_headers(username, id, password);
    let response = request(
        router,
        Request::get(route)
            .header(basic_header.0, basic_header.1)
            .header(user_id_header.0, user_id_header.1)
            .body(Body::empty())
            .unwrap(),
    )
    .await;

    assert_eq!(response.status(), StatusCode::OK);
    assert_json(&response);
}

/// Use a get request to make sure that the authentication as a user does not
/// succeed.
async fn auth_as_not_allowed(
    router: &mut Router,
    route: &str,
    username: &str,
    id: i64,
    password: &str,
) {
    let [basic_header, user_id_header] = auth_as_headers(username, id, password);
    let response = request(
        router,
        Request::get(route)
            .header(basic_header.0, basic_header.1)
            .header(user_id_header.0, user_id_header.1)
            .body(Body::empty())
            .unwrap(),
    )
    .await;

    assert_eq!(response.status(), StatusCode::FORBIDDEN);
    assert_json(&response);
}

/// Use a get request to make sure that the authentication as a user with wrong credentials does not
/// succeed.
async fn auth_as_wrong_credentials(router: &mut Router, route: &str, username: &str, id: i64) {
    let [basic_header, user_id_header] = auth_as_headers(username, id, "wrong password");
    let response = request(
        router,
        Request::get(route)
            .header(basic_header.0, basic_header.1)
            .header(user_id_header.0, user_id_header.1)
            .body(Body::empty())
            .unwrap(),
    )
    .await;

    assert_eq!(response.status(), StatusCode::UNAUTHORIZED);
    assert_json(&response);

    let [basic_header, user_id_header] = auth_as_headers("wrong username", 1, "wrong password");
    let response = request(
        router,
        Request::get(route)
            .header(basic_header.0, basic_header.1)
            .header(user_id_header.0, user_id_header.1)
            .body(Body::empty())
            .unwrap(),
    )
    .await;

    assert_eq!(response.status(), StatusCode::UNAUTHORIZED);
    assert_json(&response);
}

/// Use a get request to make sure that the authentication as a user without credentials does not
/// succeed.
async fn auth_as_without_credentials(router: &mut Router, route: &str, id: i64) {
    let [basic_header, user_id_header] = auth_as_headers("", id, "wrong password");
    let response = request(
        router,
        Request::get(route)
            .header(basic_header.0, basic_header.1)
            .header(user_id_header.0, user_id_header.1)
            .body(Body::empty())
            .unwrap(),
    )
    .await;

    assert_eq!(response.status(), StatusCode::UNAUTHORIZED);
    assert_json(&response);
}

#[tokio::test]
async fn admin_auth() {
    let (mut router, _, _) = init().await;
    auth(
        &mut router,
        &route_max_version("", ADM_PLATFORM, None),
        ADMIN_USERNAME,
        ADMIN_PASSWORD_PLAINTEXT,
    )
    .await;
}

#[tokio::test]
async fn admin_auth_wrong_credentials() {
    let (mut router, _, _) = init().await;
    auth_wrong_credentials(
        &mut router,
        &route_max_version("", ADM_PLATFORM, None),
        ADMIN_USERNAME,
    )
    .await;
}

#[tokio::test]
async fn admin_auth_without_credentials() {
    let (mut router, _, _) = init().await;
    auth_without_credentials(&mut router, &route_max_version("", ADM_PLATFORM, None)).await;
}

#[tokio::test]
async fn ap_auth() {
    let (mut router, _, _) = init().await;
    auth(
        &mut router,
        &route_max_version("", AP_ACTION_PROVIDER, None),
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
        &route_max_version("", AP_ACTION_PROVIDER, None),
        &TEST_AP.name,
    )
    .await;
}

#[tokio::test]
async fn ap_auth_without_credentials() {
    let (mut router, _, _) = init().await;
    auth_without_credentials(
        &mut router,
        &route_max_version("", AP_ACTION_PROVIDER, None),
    )
    .await;
}

#[tokio::test]
async fn admin_as_ap_auth() {
    let (mut router, _, _) = init().await;
    auth_as(
        &mut router,
        &route_max_version("", AP_ACTION_PROVIDER, None),
        ADMIN_USERNAME,
        TEST_AP.id.0,
        ADMIN_PASSWORD_PLAINTEXT,
    )
    .await;
}

#[tokio::test]
async fn admin_as_ap_auth_wrong_credentials() {
    let (mut router, _, _) = init().await;
    auth_as_wrong_credentials(
        &mut router,
        &route_max_version("", AP_ACTION_PROVIDER, None),
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
        &route_max_version("", AP_ACTION_PROVIDER, None),
        TEST_AP.id.0,
    )
    .await;
}

#[tokio::test]
async fn user_auth() {
    let (mut router, _, _) = init().await;
    auth(
        &mut router,
        &route_max_version("", USER, None),
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
        &route_max_version("", USER, None),
        &TEST_USER.username,
    )
    .await;
}

#[tokio::test]
async fn user_auth_without_credentials() {
    let (mut router, _, _) = init().await;
    auth_without_credentials(&mut router, &route_max_version("", USER, None)).await;
}

#[tokio::test]
async fn admin_as_user_auth() {
    let (mut router, _, _) = init().await;
    auth_as(
        &mut router,
        &route_max_version("", USER, None),
        ADMIN_USERNAME,
        TEST_USER.id.0,
        ADMIN_PASSWORD_PLAINTEXT,
    )
    .await;
}

#[tokio::test]
async fn admin_as_user_auth_wrong_credentials() {
    let (mut router, _, _) = init().await;
    auth_as_wrong_credentials(
        &mut router,
        &route_max_version("", USER, None),
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
        &route_max_version("", USER, None),
        TEST_USER.id.0,
    )
    .await;
}

#[tokio::test]
async fn user_ap_auth() {
    let (mut router, _, _) = init().await;
    auth(
        &mut router,
        &route_max_version("", DIARY, None),
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
        &route_max_version("", DIARY, None),
        &TEST_USER.username,
    )
    .await;
}

#[tokio::test]
async fn user_ap_auth_without_credentials() {
    let (mut router, _, _) = init().await;
    auth_without_credentials(&mut router, &route_max_version("", DIARY, None)).await;
}

#[tokio::test]
async fn ap_as_user_ap_auth() {
    let (mut router, db_pool, _) = init().await;

    // create ActionEvent to ensure access permission for user
    let action_event = ActionEvent {
        id: ActionEventId(rnd()),
        user_id: TEST_USER.id,
        action_id: TEST_ACTION.id,
        datetime: Utc::now() + Duration::try_days(1).unwrap(),
        arguments: None,
        enabled: true,
        deleted: false,
    };
    ActionEventDb::create(&action_event, &mut db_pool.get().await.unwrap())
        .await
        .unwrap();

    auth_as(
        &mut router,
        &route_max_version("", DIARY, None),
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
        datetime: Utc::now() + Duration::try_days(1).unwrap(),
        arguments: None,
        enabled: false,
        deleted: false,
    };
    ActionEventDb::create(&action_event1, &mut db_pool.get().await.unwrap())
        .await
        .unwrap();

    // create deleted ActionEvent
    let action_event2 = ActionEvent {
        id: ActionEventId(rnd()),
        user_id: TEST_USER.id,
        action_id: TEST_ACTION.id,
        datetime: Utc::now() + Duration::try_days(1).unwrap(),
        arguments: None,
        enabled: true,
        deleted: true,
    };
    ActionEventDb::create(&action_event2, &mut db_pool.get().await.unwrap())
        .await
        .unwrap();

    //  check that ap has no access
    auth_as_not_allowed(
        &mut router,
        &route_max_version("", DIARY, None),
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
        datetime: Utc::now() + Duration::try_days(1).unwrap(),
        arguments: None,
        enabled: true,
        deleted: false,
    };
    ActionEventDb::create(&action_event, &mut db_pool.get().await.unwrap())
        .await
        .unwrap();

    auth_as_wrong_credentials(
        &mut router,
        &route_max_version("", DIARY, None),
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
        datetime: Utc::now() + Duration::try_days(1).unwrap(),
        arguments: None,
        enabled: true,
        deleted: false,
    };
    ActionEventDb::create(&action_event, &mut db_pool.get().await.unwrap())
        .await
        .unwrap();

    auth_as_without_credentials(
        &mut router,
        &route_max_version("", DIARY, None),
        TEST_USER.id.0,
    )
    .await;
}

#[tokio::test]
async fn admin_as_user_ap_auth() {
    let (mut router, _, _) = init().await;

    auth_as(
        &mut router,
        &route_max_version("", DIARY, None),
        ADMIN_USERNAME,
        TEST_USER.id.0,
        ADMIN_PASSWORD_PLAINTEXT,
    )
    .await;
}

#[tokio::test]
async fn admin_as_user_ap_auth_wrong_credentials() {
    let (mut router, _, _) = init().await;

    auth_as_wrong_credentials(
        &mut router,
        &route_max_version("", DIARY, None),
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
        &route_max_version("", DIARY, None),
        TEST_USER.id.0,
    )
    .await;
}

#[tokio::test]
async fn own_create() {
    let (mut router, _, _) = init().await;

    // check that create works for same user
    let header = auth_header(&TEST_USER.username, &TEST_USER.password);
    let response = request(
        &mut router,
        Request::post(route_max_version("", DIARY, None))
            .header(header.0, header.1)
            .header(CONTENT_TYPE, APPLICATION_JSON.as_ref())
            .body(serde_json::to_string(&TEST_DIARY as &Diary).unwrap().into())
            .unwrap(),
    )
    .await;

    assert_eq!(response.status(), StatusCode::OK);
}

#[tokio::test]
async fn foreign_create() {
    let (mut router, _, _) = init().await;

    // check that create does not work for other user
    let header = auth_header(&TEST_USER2.username, &TEST_USER2.password);
    let response = request(
        &mut router,
        Request::post(route_max_version("", DIARY, None))
            .header(header.0, header.1)
            .header(CONTENT_TYPE, APPLICATION_JSON.as_ref())
            .body(serde_json::to_string(&TEST_DIARY as &Diary).unwrap().into())
            .unwrap(),
    )
    .await;

    assert_eq!(response.status(), StatusCode::FORBIDDEN);
}

#[tokio::test]
async fn own_get() {
    let (mut router, db_pool, _) = init().await;

    DiaryDb::create(&TEST_DIARY, &mut db_pool.get().await.unwrap())
        .await
        .unwrap();

    // check that get works for same user
    let header = auth_header(&TEST_USER.username, &TEST_USER.password);
    let response = request(
        &mut router,
        Request::get(route_max_version(
            "",
            DIARY,
            Some(&[("id", &TEST_DIARY.id.0.to_string())]),
        ))
        .header(header.0, header.1)
        .body(Body::empty())
        .unwrap(),
    )
    .await;

    assert_eq!(response.status(), StatusCode::OK);
    assert_json(&response);
    let diary: Vec<Diary> = parse_body(response).await;
    assert_eq!(diary.len(), 1);
    assert_eq!(diary[0].id, TEST_DIARY.id);
}

#[tokio::test]
async fn own_get_gzip() {
    let (mut router, db_pool, _) = init().await;

    DiaryDb::create(&TEST_DIARY, &mut db_pool.get().await.unwrap())
        .await
        .unwrap();

    // check that get works for same user
    let header = auth_header(&TEST_USER.username, &TEST_USER.password);
    let response = request(
        &mut router,
        Request::get(route_max_version(
            "",
            DIARY,
            Some(&[("id", &TEST_DIARY.id.0.to_string())]),
        ))
        .header(header.0, header.1)
        .header(ACCEPT_ENCODING, "gzip")
        .body(Body::empty())
        .unwrap(),
    )
    .await;

    assert_eq!(response.status(), StatusCode::OK);
    assert_json(&response);
    assert!(response.headers().contains_key(CONTENT_ENCODING));
    assert_eq!(
        response.headers().get(CONTENT_ENCODING),
        Some(&HeaderValue::from_static("gzip"))
    );
    let diary: Vec<Diary> = parse_gzip_body(response).await;
    assert_eq!(diary.len(), 1);
    assert_eq!(diary[0].id, TEST_DIARY.id);
}

#[tokio::test]
async fn own_get_non_existing() {
    let (mut router, _, _) = init().await;

    let header = auth_header(&TEST_USER.username, &TEST_USER.password);
    let response = request(
        &mut router,
        Request::get(route_max_version(
            "",
            DIARY,
            Some(&[("id", &TEST_DIARY.id.0.to_string())]),
        ))
        .header(header.0, header.1)
        .body(Body::empty())
        .unwrap(),
    )
    .await;

    assert_eq!(response.status(), StatusCode::FORBIDDEN);
}

#[tokio::test]
async fn foreign_get() {
    let (mut router, db_pool, _) = init().await;

    DiaryDb::create(&TEST_DIARY, &mut db_pool.get().await.unwrap())
        .await
        .unwrap();

    // check that get does not work for other user
    let header = auth_header(&TEST_USER2.username, &TEST_USER2.password);
    let response = request(
        &mut router,
        Request::get(route_max_version(
            "",
            DIARY,
            Some(&[("id", &TEST_DIARY.id.0.to_string())]),
        ))
        .header(header.0, header.1)
        .body(Body::empty())
        .unwrap(),
    )
    .await;

    assert_eq!(response.status(), StatusCode::FORBIDDEN);
}

#[tokio::test]
async fn own_update() {
    let (mut router, db_pool, _) = init().await;

    DiaryDb::create(&TEST_DIARY, &mut db_pool.get().await.unwrap())
        .await
        .unwrap();

    // check that update works for same user
    let header = auth_header(&TEST_USER.username, &TEST_USER.password);
    let response = request(
        &mut router,
        Request::put(&route_max_version("", DIARY, None))
            .header(header.0, header.1)
            .header(CONTENT_TYPE, APPLICATION_JSON.as_ref())
            .body(serde_json::to_string(&TEST_DIARY as &Diary).unwrap().into())
            .unwrap(),
    )
    .await;

    assert_eq!(response.status(), StatusCode::OK);
}

#[tokio::test]
async fn own_update_non_existing() {
    let (mut router, _, _) = init().await;

    let header = auth_header(&TEST_USER.username, &TEST_USER.password);
    let response = request(
        &mut router,
        Request::put(&route_max_version("", DIARY, None))
            .header(header.0, header.1)
            .header(CONTENT_TYPE, APPLICATION_JSON.as_ref())
            .body(serde_json::to_string(&TEST_DIARY as &Diary).unwrap().into())
            .unwrap(),
    )
    .await;

    assert_eq!(response.status(), StatusCode::FORBIDDEN);
}

#[tokio::test]
async fn foreign_update() {
    let (mut router, db_pool, _) = init().await;

    DiaryDb::create(&TEST_DIARY, &mut db_pool.get().await.unwrap())
        .await
        .unwrap();

    // check that update does not work for other user
    let header = auth_header(&TEST_USER2.username, &TEST_USER2.password);
    let response = request(
        &mut router,
        Request::put(&route_max_version("", DIARY, None))
            .header(header.0, header.1)
            .header(CONTENT_TYPE, APPLICATION_JSON.as_ref())
            .body(serde_json::to_string(&TEST_DIARY as &Diary).unwrap().into())
            .unwrap(),
    )
    .await;

    assert_eq!(response.status(), StatusCode::FORBIDDEN);
}

#[tokio::test]
async fn get_account_data() {
    let (mut router, db_pool, _) = init().await;

    // get all - check empty
    let (status, account_data) = account_data_request(&mut router, None).await;
    let epoch = account_data.epoch_map.diary;

    assert_eq!(status, StatusCode::OK);
    assert!(account_data.diaries.is_empty());

    // get updates - check no new data
    let (status, account_data) = account_data_request(&mut router, Some(epoch)).await;
    let epoch = account_data.epoch_map.diary;

    assert_eq!(status, StatusCode::OK);
    assert!(account_data.diaries.is_empty());

    // get updates - check new diary
    DiaryDb::create(&TEST_DIARY, &mut db_pool.get().await.unwrap())
        .await
        .unwrap();
    let (status, account_data) = account_data_request(&mut router, Some(epoch)).await;
    let epoch = account_data.epoch_map.diary;

    assert_eq!(status, StatusCode::OK);
    assert_eq!(account_data.diaries.len(), 1);
    assert_eq!(account_data.diaries[0].id, TEST_DIARY.id);

    // get updates - check no new data
    let (status, account_data) = account_data_request(&mut router, Some(epoch)).await;
    let epoch = account_data.epoch_map.diary;

    assert_eq!(status, StatusCode::OK);
    assert!(account_data.diaries.is_empty());

    // get updates - check updated diary
    DiaryDb::update(&TEST_DIARY, &mut db_pool.get().await.unwrap())
        .await
        .unwrap();
    let (status, account_data) = account_data_request(&mut router, Some(epoch)).await;

    assert_eq!(status, StatusCode::OK);
    assert_eq!(account_data.diaries.len(), 1);
    assert_eq!(account_data.diaries[0].id, TEST_DIARY.id);

    // get all - check diary
    let (status, account_data) = account_data_request(&mut router, None).await;

    assert_eq!(status, StatusCode::OK);
    assert_eq!(account_data.diaries.len(), 1);
    assert_eq!(account_data.diaries[0].id, TEST_DIARY.id);
}

#[tokio::test]
async fn epoch_from_create_and_update() {
    let (mut router, _, _) = init().await;

    // get account data - check empty & extract diary epoch
    let (status, account_data) = account_data_request(&mut router, None).await;
    let epoch = account_data.epoch_map.diary;

    assert_eq!(status, StatusCode::OK);
    assert!(account_data.diaries.is_empty());

    // create new diary - check epoch increased by one
    let header = auth_header(&TEST_USER.username, &TEST_USER.password);
    let response = request(
        &mut router,
        Request::post(route_max_version("", DIARY, None))
            .header(header.0, header.1)
            .header(CONTENT_TYPE, APPLICATION_JSON.as_ref())
            .body(serde_json::to_string(&TEST_DIARY as &Diary).unwrap().into())
            .unwrap(),
    )
    .await;

    assert_eq!(response.status(), StatusCode::OK);
    let epoch_response: EpochResponse = parse_body(response).await;
    assert_eq!(epoch_response.epoch, Epoch(epoch.0 + 1));

    // update diary - check epoch increased again by one
    let header = auth_header(&TEST_USER.username, &TEST_USER.password);
    let response = request(
        &mut router,
        Request::put(&route_max_version("", DIARY, None))
            .header(header.0, header.1)
            .header(CONTENT_TYPE, APPLICATION_JSON.as_ref())
            .body(serde_json::to_string(&TEST_DIARY as &Diary).unwrap().into())
            .unwrap(),
    )
    .await;

    assert_eq!(response.status(), StatusCode::OK);
    let epoch_response: EpochResponse = parse_body(response).await;
    assert_eq!(epoch_response.epoch, Epoch(epoch.0 + 2));
}

#[tokio::test]
async fn user_self_registration() {
    let (mut router, _, config) = init().await;

    let user_id = UserId(rnd());
    let user = User {
        id: user_id,
        username: format!("user{}", user_id.0),
        password: "Password1".to_owned(),
        email: format!("email{}", user_id.0),
    };

    let response = request(
        &mut router,
        Request::post(&route_max_version("", USER, None))
            .header(CONTENT_TYPE, APPLICATION_JSON.as_ref())
            .body(serde_json::to_string(&user).unwrap().into())
            .unwrap(),
    )
    .await;

    if config.user_self_registration {
        assert_eq!(response.status(), StatusCode::OK);
    } else {
        assert_eq!(response.status(), StatusCode::FORBIDDEN);
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

    let response = request(
        &mut router,
        Request::post(&route_max_version("", AP_PLATFORM, None))
            .header(CONTENT_TYPE, APPLICATION_JSON.as_ref())
            .body(serde_json::to_string(&platform).unwrap().into())
            .unwrap(),
    )
    .await;

    if config.ap_self_registration {
        assert_eq!(response.status(), StatusCode::OK);
    } else {
        assert_eq!(response.status(), StatusCode::FORBIDDEN);
    }

    let response = request(
        &mut router,
        Request::get(&route_max_version("", AP_PLATFORM, None))
            .body(Body::empty())
            .unwrap(),
    )
    .await;

    if config.ap_self_registration {
        assert_eq!(response.status(), StatusCode::OK);
    } else {
        assert_eq!(response.status(), StatusCode::FORBIDDEN);
    }

    let ap_id = ActionProviderId(rnd());
    let action_provider = ActionProvider {
        id: ap_id,
        name: format!("ap{}", ap_id.0),
        password: "Password1".to_owned(),
        platform_id: TEST_PLATFORM.id,
        description: None,
        deleted: false,
    };

    let response = request(
        &mut router,
        Request::post(&route_max_version("", AP_ACTION_PROVIDER, None))
            .header(CONTENT_TYPE, APPLICATION_JSON.as_ref())
            .body(serde_json::to_string(&action_provider).unwrap().into())
            .unwrap(),
    )
    .await;

    if config.ap_self_registration {
        assert_eq!(response.status(), StatusCode::OK);
    } else {
        assert_eq!(response.status(), StatusCode::FORBIDDEN);
    }
}
