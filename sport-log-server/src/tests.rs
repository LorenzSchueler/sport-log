//! test must be run sequentially
//! ```bash
//! cargo test -- --test-threads=1
//! ```

use std::sync::Arc;

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
use chrono::{Duration, Utc};
use mime::APPLICATION_JSON;
use rand::Rng;
use sport_log_types::{
    uri::{route_max_version, ADM_PLATFORM, AP_ACTION_PROVIDER, AP_PLATFORM, DIARY, USER},
    Action, ActionEvent, ActionEventId, ActionId, ActionProvider, ActionProviderId, AppState,
    Config, Create, DbPool, Diary, DiaryId, HardDelete, Platform, PlatformId, Update, User, UserId,
    ADMIN_USERNAME,
};
use tower::{Service, ServiceExt};

use crate::{get_config, get_db_pool, router};

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

fn rnd() -> i64 {
    rand::thread_rng().gen()
}

fn basic_auth(username: &str, password: &str) -> (HeaderName, String) {
    (
        AUTHORIZATION,
        format!(
            "Basic {}",
            base64::encode(format!("{}:{}", username, password))
        ),
    )
}

fn basic_auth_as(username: &str, id: i64, password: &str) -> (HeaderName, String) {
    (
        AUTHORIZATION,
        format!(
            "Basic {}",
            base64::encode(format!("{}$id${}:{}", username, id, password))
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

async fn init() -> (Router, DbPool, Config) {
    let config = get_config().await.unwrap();

    let db_pool = get_db_pool(&config).await.unwrap();

    let state = AppState {
        db_pool: db_pool.clone(),
        config: Arc::new(config.clone()),
    };

    let router = router::get_router(state).await;

    (router, db_pool, config)
}

#[tokio::test]
async fn aa_setup() {
    let (_, db_pool, _) = init().await;
    let mut db = db_pool.get().unwrap();

    let user = User {
        id: USER_ID,
        username: USER_USERNAME.to_owned(),
        password: USER_PASSWORD.to_owned(),
        email: "email123456789".to_owned(),
    };
    User::create(user, &mut db).unwrap();

    let user2 = User {
        id: USER2_ID,
        username: USER2_USERNAME.to_owned(),
        password: USER2_PASSWORD.to_owned(),
        email: "email2123456789".to_owned(),
    };
    User::create(user2, &mut db).unwrap();

    let platform = Platform {
        id: PLATFORM_ID,
        name: "platform123456789".to_owned(),
        credential: false,
        deleted: false,
    };
    Platform::create(platform, &mut db).unwrap();

    let ap = ActionProvider {
        id: AP_ID,
        name: AP_USERNAME.to_owned(),
        password: AP_PASSWORD.to_owned(),
        platform_id: PLATFORM_ID,
        description: None,
        deleted: false,
    };
    ActionProvider::create(ap, &mut db).unwrap();

    let action = Action {
        id: ACTION_ID,
        name: "action123456789".to_owned(),
        action_provider_id: AP_ID,
        description: None,
        create_before: 1,
        delete_after: 1,
        deleted: false,
    };
    Action::create(action, &mut db).unwrap();
}

#[tokio::test]
async fn zz_teardown() {
    let (_, db_pool, _) = init().await;
    let mut db = db_pool.get().unwrap();

    User::delete(USER_ID, &mut db).unwrap();
    User::delete(USER2_ID, &mut db).unwrap();

    let platform = Platform {
        id: PLATFORM_ID,
        name: "platform123456789".to_owned(),
        credential: false,
        deleted: true,
    };
    Platform::update(platform, &mut db).unwrap();
    Platform::hard_delete(Utc::now(), &mut db).unwrap();
    Action::hard_delete(Utc::now(), &mut db).unwrap();
    ActionProvider::hard_delete(Utc::now(), &mut db).unwrap();
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
        AP_USERNAME,
        AP_PASSWORD,
    )
    .await;
}

#[tokio::test]
async fn ap_auth_wrong_credentials() {
    let (mut router, _, _) = init().await;
    auth_wrong_credentials(
        &mut router,
        &route_max_version("", AP_ACTION_PROVIDER, &[]),
        AP_USERNAME,
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
        AP_ID.0,
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
        AP_ID.0,
    )
    .await;
}

#[tokio::test]
async fn admin_as_ap_auth_without_credentials() {
    let (mut router, _, _) = init().await;
    auth_as_without_credentials(
        &mut router,
        &route_max_version("", AP_ACTION_PROVIDER, &[]),
        AP_ID.0,
    )
    .await;
}

#[tokio::test]
async fn user_auth() {
    let (mut router, _, _) = init().await;
    auth(
        &mut router,
        &route_max_version("", USER, &[]),
        USER_USERNAME,
        USER_PASSWORD,
    )
    .await;
}

#[tokio::test]
async fn user_auth_wrong_credentials() {
    let (mut router, _, _) = init().await;
    auth_wrong_credentials(
        &mut router,
        &route_max_version("", USER, &[]),
        USER_USERNAME,
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
        USER_ID.0,
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
        USER_ID.0,
    )
    .await;
}

#[tokio::test]
async fn admin_as_user_auth_without_credentials() {
    let (mut router, _, _) = init().await;
    auth_as_without_credentials(&mut router, &route_max_version("", USER, &[]), USER_ID.0).await;
}

#[tokio::test]
async fn user_ap_auth() {
    let (mut router, _, _) = init().await;
    auth(
        &mut router,
        &route_max_version("", DIARY, &[]),
        USER_USERNAME,
        USER_PASSWORD,
    )
    .await;
}

#[tokio::test]
async fn user_ap_auth_wrong_credentials() {
    let (mut router, _, _) = init().await;
    auth_wrong_credentials(
        &mut router,
        &route_max_version("", DIARY, &[]),
        USER_USERNAME,
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
    let mut db = db_pool.get().unwrap();

    // create ActionEvent to ensure access permission for user
    let mut action_event = ActionEvent {
        id: ActionEventId(rnd()),
        user_id: USER_ID,
        action_id: ACTION_ID,
        datetime: Utc::now() + Duration::days(1),
        arguments: None,
        enabled: true,
        deleted: false,
    };
    ActionEvent::create(action_event.clone(), &mut db).unwrap();

    auth_as(
        &mut router,
        &route_max_version("", DIARY, &[]),
        AP_USERNAME,
        USER_ID.0,
        AP_PASSWORD,
    )
    .await;

    action_event.deleted = true;
    ActionEvent::update(action_event, &mut db).unwrap();
}

#[tokio::test]
async fn ap_as_user_ap_auth_no_event() {
    let (mut router, db_pool, _) = init().await;
    let mut db = db_pool.get().unwrap();

    // create disabled ActionEvent
    let mut action_event1 = ActionEvent {
        id: ActionEventId(rnd()),
        user_id: USER_ID,
        action_id: ACTION_ID,
        datetime: Utc::now() + Duration::days(1),
        arguments: None,
        enabled: false,
        deleted: false,
    };
    ActionEvent::create(action_event1.clone(), &mut db).unwrap();

    // create deleted ActionEvent
    let mut action_event2 = ActionEvent {
        id: ActionEventId(rnd()),
        user_id: USER_ID,
        action_id: ACTION_ID,
        datetime: Utc::now() + Duration::days(1),
        arguments: None,
        enabled: true,
        deleted: true,
    };
    ActionEvent::create(action_event2.clone(), &mut db).unwrap();

    //  check that ap has no access
    auth_as_not_allowed(
        &mut router,
        &route_max_version("", DIARY, &[]),
        AP_USERNAME,
        USER_ID.0,
        AP_PASSWORD,
    )
    .await;

    action_event1.deleted = true;
    ActionEvent::update(action_event1, &mut db).unwrap();
    action_event2.deleted = true;
    ActionEvent::update(action_event2, &mut db).unwrap();
}

#[tokio::test]
async fn ap_as_user_ap_auth_wrong_credentials() {
    let (mut router, db_pool, _) = init().await;
    let mut db = db_pool.get().unwrap();

    // create ActionEvent to ensure access permission for user
    let mut action_event = ActionEvent {
        id: ActionEventId(rnd()),
        user_id: USER_ID,
        action_id: ACTION_ID,
        datetime: Utc::now() + Duration::days(1),
        arguments: None,
        enabled: true,
        deleted: false,
    };
    ActionEvent::create(action_event.clone(), &mut db).unwrap();

    auth_as_wrong_credentials(
        &mut router,
        &route_max_version("", DIARY, &[]),
        AP_USERNAME,
        USER_ID.0,
    )
    .await;

    action_event.deleted = true;
    ActionEvent::update(action_event, &mut db).unwrap();
}

#[tokio::test]
async fn ap_as_user_ap_auth_without_credentials() {
    let (mut router, db_pool, _) = init().await;
    let mut db = db_pool.get().unwrap();

    // create ActionEvent to ensure access permission for user
    let action_event = ActionEvent {
        id: ActionEventId(rnd()),
        user_id: USER_ID,
        action_id: ACTION_ID,
        datetime: Utc::now() + Duration::days(1),
        arguments: None,
        enabled: true,
        deleted: false,
    };
    ActionEvent::create(action_event, &mut db).unwrap();

    auth_as_without_credentials(&mut router, &route_max_version("", DIARY, &[]), USER_ID.0).await;
}

#[tokio::test]
async fn admin_as_user_ap_auth() {
    let (mut router, _, _) = init().await;

    auth_as(
        &mut router,
        &route_max_version("", DIARY, &[]),
        ADMIN_USERNAME,
        USER_ID.0,
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
        USER_ID.0,
    )
    .await;
}

#[tokio::test]
async fn admin_as_user_ap_auth_without_credentials() {
    let (mut router, _, _) = init().await;

    auth_as_without_credentials(&mut router, &route_max_version("", DIARY, &[]), USER_ID.0).await;
}

async fn create_diary(
    router: &mut Router,
    username: &str,
    password: &str,
    user_id: i64,
) -> (DiaryId, Response) {
    let diary_id = DiaryId(rnd());
    let diary = Diary {
        id: diary_id,
        user_id: UserId(user_id),
        date: Utc::now().date_naive() - Duration::days(rnd() % 10000),
        bodyweight: None,
        comments: None,
        deleted: false,
    };

    let header = basic_auth(username, password);
    let response = router
        .ready()
        .await
        .unwrap()
        .call(
            Request::post(route_max_version("", DIARY, &[]))
                .header(header.0, header.1)
                .header(CONTENT_TYPE, APPLICATION_JSON.as_ref())
                .body(serde_json::to_string(&diary).unwrap().into())
                .unwrap(),
        )
        .await
        .unwrap();

    (diary_id, response)
}

#[tokio::test]
async fn foreign_create() {
    let (mut router, _, _) = init().await;

    // check that create works for same user
    let (_, response) = create_diary(&mut router, USER_USERNAME, USER_PASSWORD, USER_ID.0).await;
    assert_status(&response, StatusCode::OK);

    let (mut router, _, _) = init().await;

    // check that create does not work for other user
    let (_, response) = create_diary(&mut router, USER2_USERNAME, USER2_PASSWORD, USER_ID.0).await;
    assert_status(&response, StatusCode::FORBIDDEN);
}

#[tokio::test]
async fn foreign_get() {
    let (mut router, _, _) = init().await;

    let (diary_id, response) =
        create_diary(&mut router, USER_USERNAME, USER_PASSWORD, USER_ID.0).await;
    assert_status(&response, StatusCode::OK);

    let (mut router, _, _) = init().await;

    // check that get works for same user
    let header = basic_auth(USER_USERNAME, USER_PASSWORD);
    let response = router
        .ready()
        .await
        .unwrap()
        .call(
            Request::get(route_max_version(
                "",
                DIARY,
                &[("id", &diary_id.0.to_string())],
            ))
            .header(header.0, header.1)
            .body(Body::empty())
            .unwrap(),
        )
        .await
        .unwrap();

    assert_status(&response, StatusCode::OK);

    let (mut router, _, _) = init().await;

    // check that get does not work for other user
    let header = basic_auth(USER2_USERNAME, USER2_PASSWORD);
    let response = router
        .ready()
        .await
        .unwrap()
        .call(
            Request::get(route_max_version(
                "",
                DIARY,
                &[("id", &diary_id.0.to_string())],
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
async fn foreign_update() {
    let (mut router, _, _) = init().await;

    let (diary_id, response) =
        create_diary(&mut router, USER_USERNAME, USER_PASSWORD, USER_ID.0).await;
    assert_status(&response, StatusCode::OK);

    let diary = Diary {
        id: diary_id,
        user_id: USER_ID,
        date: Utc::now().date_naive() - Duration::days(rnd() % 10000),
        bodyweight: None,
        comments: None,
        deleted: false,
    };

    let (mut router, _, _) = init().await;

    // check that update works for same user
    let header = basic_auth(USER_USERNAME, USER_PASSWORD);
    let response = router
        .ready()
        .await
        .unwrap()
        .call(
            Request::put(&route_max_version("", DIARY, &[]))
                .header(header.0, header.1)
                .header(CONTENT_TYPE, APPLICATION_JSON.as_ref())
                .body(serde_json::to_string(&diary).unwrap().into())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_status(&response, StatusCode::OK);

    let (mut router, _, _) = init().await;

    // check that update does not work for other user
    let header = basic_auth(USER2_USERNAME, USER2_PASSWORD);
    let response = router
        .ready()
        .await
        .unwrap()
        .call(
            Request::put(&route_max_version("", DIARY, &[]))
                .header(header.0, header.1)
                .header(CONTENT_TYPE, APPLICATION_JSON.as_ref())
                .body(serde_json::to_string(&diary).unwrap().into())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_status(&response, StatusCode::FORBIDDEN);
}

#[tokio::test]
async fn user_self_registration() {
    let (mut router, db_pool, config) = init().await;
    let mut db = db_pool.get().unwrap();

    let user_id = UserId(rnd());
    let user = User {
        id: user_id,
        username: format!("user{}", user_id.0),
        password: "password".to_owned(),
        email: format!("email{}", user_id.0),
    };

    let route = route_max_version("", USER, &[]);
    let response = router
        .ready()
        .await
        .unwrap()
        .call(
            Request::post(&route)
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

    User::delete(user_id, &mut db).unwrap();
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

    let (mut router, _, _) = init().await;

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
        platform_id: PLATFORM_ID,
        description: None,
        deleted: false,
    };

    let (mut router, _, _) = init().await;

    let ap_route = route_max_version("", AP_ACTION_PROVIDER, &[]);
    let response = router
        .ready()
        .await
        .unwrap()
        .call(
            Request::post(&ap_route)
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

    let diary = Diary {
        id: DiaryId(rnd()),
        user_id: USER_ID,
        date: Utc::now().date_naive() - Duration::days(rnd() % 10000),
        bodyweight: None,
        comments: None,
        deleted: false,
    };

    let route = route_max_version("", DIARY, &[]);
    let header = basic_auth(USER_USERNAME, USER_PASSWORD);
    let response = router
        .ready()
        .await
        .unwrap()
        .call(
            Request::put(&route)
                .header(header.0, header.1)
                .header(CONTENT_TYPE, APPLICATION_JSON.as_ref())
                .body(serde_json::to_string(&diary).unwrap().into())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_status(&response, StatusCode::FORBIDDEN);
}

// TODO use test transaction
