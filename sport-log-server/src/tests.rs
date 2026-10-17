use std::sync::LazyLock;

use axum::{
    Router,
    body::{self, Body},
    http::{
        HeaderName, HeaderValue, Method, Request, StatusCode,
        header::{ACCEPT_ENCODING, AUTHORIZATION, CONTENT_TYPE},
    },
    response::Response,
};
use base64::{Engine, engine::general_purpose::STANDARD};
use chrono::{Duration, Utc};
use diesel::QueryDsl;
use diesel_async::{
    AsyncConnection, AsyncPgConnection, RunQueryDsl,
    pooled_connection::{
        AsyncDieselConnectionManager,
        deadpool::{Hook, Pool},
    },
};
use flate2::read::GzDecoder;
use hyper::header::CONTENT_ENCODING;
use mime::APPLICATION_JSON;
use rand::RngExt;
use rstest::{fixture, rstest};
use serde::de::DeserializeOwned;
use sport_log_types::{
    ADMIN_USERNAME, AccountData, Action, ActionEvent, ActionEventId, ActionId, ActionProvider,
    ActionProviderId, CardioSession, CardioSessionId, CardioType, Diary, DiaryId, Epoch, EpochMap,
    EpochResponse, ID_HEADER, Movement, MovementDimension, MovementId, Platform,
    PlatformCredential, PlatformCredentialId, PlatformId, Route, RouteId, User, UserId,
    schema::{action_provider, cardio_session, platform},
    uri::{
        ACCOUNT_DATA, ADM_PLATFORM, AP_ACTION_PROVIDER, AP_PLATFORM, CARDIO_SESSION, DIARY, USER,
        route_max_version,
    },
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

struct TestContext {
    router: Router,
    db_pool: DbPool,
}

#[fixture]
async fn ctx(
    #[default(false)] user_self_registration: bool,
    #[default(false)] ap_self_registration: bool,
) -> TestContext {
    // Every test case gets its own context and therefore its own db pool.
    // For each pool there is only a single database connection that uses a test transaction (which
    // is never committed). By restricting the number of connections to a single one per db
    // pool, the connection that can be retrieved from the pool in order to run setup code
    // is guaranteed to be the same one that will be later used by the axum handlers.
    // Make sure to drop any reference to DbConn before invoking router,
    // because otherwise handlers will time out trying to retrieve a connection from the pool.

    let config = Box::leak(Box::new(Config {
        user_self_registration,
        ap_self_registration,
        ..get_config().await.unwrap()
    }));

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

    TestContext { router, db_pool }
}

fn rnd() -> i64 {
    rand::rng().random()
}

fn user() -> User {
    User {
        id: UserId(rnd()),
        username: format!("user{}", rnd()),
        password: String::from("Password1"),
        email: format!("email{}", rnd()),
    }
}

fn platform() -> Platform {
    Platform {
        id: PlatformId(rnd()),
        name: format!("platform{}", rnd()),
        credential: false,
        deleted: false,
    }
}

fn action_provider(platform_id: PlatformId) -> ActionProvider {
    ActionProvider {
        id: ActionProviderId(rnd()),
        name: format!("ap{}", rnd()),
        password: String::from("Password1"),
        platform_id,
        description: None,
        deleted: false,
    }
}

fn action_event(user_id: UserId, action_id: ActionId) -> ActionEvent {
    ActionEvent {
        id: ActionEventId(rnd()),
        user_id,
        action_id,
        datetime: Utc::now() + Duration::try_days(1).unwrap(),
        arguments: None,
        enabled: true,
        deleted: false,
    }
}

fn platform_credential(user_id: UserId, platform_id: PlatformId) -> PlatformCredential {
    PlatformCredential {
        id: PlatformCredentialId(rnd()),
        user_id,
        platform_id,
        username: String::from("username"),
        password: String::from("password"),
        deleted: false,
    }
}

fn movement(user_id: Option<UserId>) -> Movement {
    Movement {
        id: MovementId(rnd()),
        user_id,
        name: format!("movement{}", rnd()),
        description: None,
        movement_dimension: MovementDimension::Reps,
        cardio: false,
        deleted: false,
    }
}

fn route(user_id: UserId) -> Route {
    Route {
        id: RouteId(rnd()),
        user_id,
        name: format!("route{}", rnd()),
        distance: None,
        ascent: None,
        descent: None,
        track: None,
        marked_positions: None,
        deleted: false,
    }
}

fn cardio_session(user_id: UserId, movement_id: MovementId) -> CardioSession {
    CardioSession {
        id: CardioSessionId(rnd()),
        user_id,
        movement_id,
        cardio_type: CardioType::Training,
        datetime: Utc::now(),
        distance: None,
        ascent: None,
        descent: None,
        time: None,
        calories: None,
        track: None,
        avg_cadence: None,
        cadence: None,
        avg_heart_rate: None,
        heart_rate: None,
        route_id: None,
        comments: None,
        deleted: false,
    }
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

fn assert_json(response: &Response) {
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
    epoch_map: Option<EpochMap>,
) -> (StatusCode, AccountData) {
    let auth_header = auth_header(&TEST_USER.username, &TEST_USER.password);
    let response = request(
        router,
        Request::get(route_max_version("", ACCOUNT_DATA, None))
            .header(auth_header.0, auth_header.1)
            .header(CONTENT_TYPE, APPLICATION_JSON.as_ref())
            .body(serde_json::to_string(&Some(epoch_map)).unwrap().into())
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
    serde_json::from_slice(&bytes).unwrap()
}

async fn parse_gzip_body<T: DeserializeOwned>(response: Response) -> T {
    let bytes = body::to_bytes(response.into_body(), usize::MAX)
        .await
        .unwrap();
    serde_json::from_reader(GzDecoder::new(&*bytes)).unwrap()
}

enum Auth {
    None,
    Basic(&'static str, &'static str),
    As(&'static str, &'static str, i64),
    Id(i64),
}

async fn request_with_auth(router: &mut Router, route: &str, auth: Auth) -> Response {
    let mut builder = Request::get(route_max_version("", route, None));
    match auth {
        Auth::None => {}
        Auth::Basic(username, password) => {
            let (name, value) = auth_header(username, password);
            builder = builder.header(name, value);
        }
        Auth::As(username, password, id) => {
            let (name, value) = auth_header(username, password);
            builder = builder
                .header(name, value)
                .header(ID_HEADER, id.to_string());
        }
        Auth::Id(id) => builder = builder.header(ID_HEADER, id.to_string()),
    }
    request(router, builder.body(Body::empty()).unwrap()).await
}

#[rstest]
#[case::admin(
    ADM_PLATFORM,
    Auth::Basic(ADMIN_USERNAME, ADMIN_PASSWORD_PLAINTEXT),
    StatusCode::OK
)]
#[case::admin_wrong_password(
    ADM_PLATFORM,
    Auth::Basic(ADMIN_USERNAME, "wrong password"),
    StatusCode::UNAUTHORIZED
)]
#[case::admin_wrong_username(
    ADM_PLATFORM,
    Auth::Basic("wrong username", ADMIN_PASSWORD_PLAINTEXT),
    StatusCode::UNAUTHORIZED
)]
#[case::admin_without_credentials(ADM_PLATFORM, Auth::None, StatusCode::UNAUTHORIZED)]
#[case::ap(AP_ACTION_PROVIDER, Auth::Basic(&TEST_AP.name, &TEST_AP.password), StatusCode::OK)]
#[case::ap_wrong_password(
    AP_ACTION_PROVIDER,
    Auth::Basic(&TEST_AP.name, "wrong password"),
    StatusCode::UNAUTHORIZED
)]
#[case::ap_wrong_username(
    AP_ACTION_PROVIDER,
    Auth::Basic("wrong username", &TEST_AP.password),
    StatusCode::UNAUTHORIZED
)]
#[case::ap_without_credentials(AP_ACTION_PROVIDER, Auth::None, StatusCode::UNAUTHORIZED)]
#[case::admin_as_ap(
    AP_ACTION_PROVIDER,
    Auth::As(ADMIN_USERNAME, ADMIN_PASSWORD_PLAINTEXT, TEST_AP.id.0),
    StatusCode::OK
)]
#[case::admin_as_ap_wrong_password(
    AP_ACTION_PROVIDER,
    Auth::As(ADMIN_USERNAME, "wrong password", TEST_AP.id.0),
    StatusCode::UNAUTHORIZED
)]
#[case::admin_as_ap_wrong_username(
    AP_ACTION_PROVIDER,
    Auth::As("wrong username", ADMIN_PASSWORD_PLAINTEXT, TEST_AP.id.0),
    StatusCode::UNAUTHORIZED
)]
#[case::admin_as_ap_without_credentials(
    AP_ACTION_PROVIDER,
    Auth::Id(TEST_AP.id.0),
    StatusCode::UNAUTHORIZED
)]
#[case::user(USER, Auth::Basic(&TEST_USER.username, &TEST_USER.password), StatusCode::OK)]
#[case::user_wrong_password(
    USER,
    Auth::Basic(&TEST_USER.username, "wrong password"),
    StatusCode::UNAUTHORIZED
)]
#[case::user_wrong_username(
    USER,
    Auth::Basic("wrong username", &TEST_USER.password),
    StatusCode::UNAUTHORIZED
)]
#[case::user_without_credentials(USER, Auth::None, StatusCode::UNAUTHORIZED)]
#[case::admin_as_user(
    USER,
    Auth::As(ADMIN_USERNAME, ADMIN_PASSWORD_PLAINTEXT, TEST_USER.id.0),
    StatusCode::OK
)]
#[case::admin_as_user_wrong_password(
    USER,
    Auth::As(ADMIN_USERNAME, "wrong password", TEST_USER.id.0),
    StatusCode::UNAUTHORIZED
)]
#[case::admin_as_user_wrong_username(
    USER,
    Auth::As("wrong username", ADMIN_PASSWORD_PLAINTEXT, TEST_USER.id.0),
    StatusCode::UNAUTHORIZED
)]
#[case::admin_as_user_without_credentials(
    USER,
    Auth::Id(TEST_USER.id.0),
    StatusCode::UNAUTHORIZED
)]
#[case::user_ap(DIARY, Auth::Basic(&TEST_USER.username, &TEST_USER.password), StatusCode::OK)]
#[case::user_ap_wrong_password(
    DIARY,
    Auth::Basic(&TEST_USER.username, "wrong password"),
    StatusCode::UNAUTHORIZED
)]
#[case::user_ap_wrong_username(
    DIARY,
    Auth::Basic("wrong username", &TEST_USER.password),
    StatusCode::UNAUTHORIZED
)]
#[case::user_ap_without_credentials(DIARY, Auth::None, StatusCode::UNAUTHORIZED)]
#[case::ap_as_user_ap(
    DIARY,
    Auth::As(&TEST_AP.name, &TEST_AP.password, TEST_USER.id.0),
    StatusCode::OK
)]
#[case::ap_as_user_ap_wrong_password(
    DIARY,
    Auth::As(&TEST_AP.name, "wrong password", TEST_USER.id.0),
    StatusCode::UNAUTHORIZED
)]
#[case::ap_as_user_ap_wrong_username(
    DIARY,
    Auth::As("wrong username", &TEST_AP.password, TEST_USER.id.0),
    StatusCode::UNAUTHORIZED
)]
#[case::ap_as_user_ap_without_credentials(
    DIARY,
    Auth::Id(TEST_USER.id.0),
    StatusCode::UNAUTHORIZED
)]
#[case::admin_as_user_ap(
    DIARY,
    Auth::As(ADMIN_USERNAME, ADMIN_PASSWORD_PLAINTEXT, TEST_USER.id.0),
    StatusCode::OK
)]
#[case::admin_as_user_ap_wrong_password(
    DIARY,
    Auth::As(ADMIN_USERNAME, "wrong password", TEST_USER.id.0),
    StatusCode::UNAUTHORIZED
)]
#[case::admin_as_user_ap_wrong_username(
    DIARY,
    Auth::As("wrong username", ADMIN_PASSWORD_PLAINTEXT, TEST_USER.id.0),
    StatusCode::UNAUTHORIZED
)]
#[case::admin_as_user_ap_without_credentials(
    DIARY,
    Auth::Id(TEST_USER.id.0),
    StatusCode::UNAUTHORIZED
)]
#[tokio::test]
async fn auth(
    #[future(awt)] mut ctx: TestContext,
    #[case] route: &str,
    #[case] credentials: Auth,
    #[case] status: StatusCode,
) {
    // grants the action provider access to the user's data
    let action_event = action_event(TEST_USER.id, TEST_ACTION.id);
    ActionEventDb::create(&action_event, &mut ctx.db_pool.get().await.unwrap())
        .await
        .unwrap();

    let response = request_with_auth(&mut ctx.router, route, credentials).await;

    assert_eq!(response.status(), status);
    assert_json(&response);
}

#[rstest]
#[case::no_event(None)]
#[case::disabled_event(Some(ActionEvent {
    enabled: false,
    ..action_event(TEST_USER.id, TEST_ACTION.id)
}))]
#[case::deleted_event(Some(ActionEvent {
    deleted: true,
    ..action_event(TEST_USER.id, TEST_ACTION.id)
}))]
#[tokio::test]
async fn ap_as_user_ap_auth_no_event(
    #[future(awt)] mut ctx: TestContext,
    #[case] action_event: Option<ActionEvent>,
) {
    if let Some(action_event) = action_event {
        ActionEventDb::create(&action_event, &mut ctx.db_pool.get().await.unwrap())
            .await
            .unwrap();
    }

    let response = request_with_auth(
        &mut ctx.router,
        DIARY,
        Auth::As(&TEST_AP.name, &TEST_AP.password, TEST_USER.id.0),
    )
    .await;

    assert_eq!(response.status(), StatusCode::FORBIDDEN);
    assert_json(&response);
}

#[rstest]
#[case::own_create(Method::POST, true, false, StatusCode::OK)]
#[case::foreign_create(Method::POST, false, false, StatusCode::FORBIDDEN)]
#[case::own_get(Method::GET, true, true, StatusCode::OK)]
#[case::own_get_non_existing(Method::GET, true, false, StatusCode::FORBIDDEN)]
#[case::foreign_get(Method::GET, false, true, StatusCode::FORBIDDEN)]
#[case::own_update(Method::PUT, true, true, StatusCode::OK)]
#[case::own_update_non_existing(Method::PUT, true, false, StatusCode::FORBIDDEN)]
#[case::foreign_update(Method::PUT, false, true, StatusCode::FORBIDDEN)]
#[tokio::test]
async fn request_authorization(
    #[future(awt)] mut ctx: TestContext,
    #[case] method: Method,
    #[case] same_user: bool,
    #[case] diary_exists: bool,
    #[case] status: StatusCode,
) {
    if diary_exists {
        DiaryDb::create(&TEST_DIARY, &mut ctx.db_pool.get().await.unwrap())
            .await
            .unwrap();
    }

    let user = if same_user { &TEST_USER } else { &TEST_USER2 };
    let header = auth_header(&user.username, &user.password);
    let diary_request = if method == Method::GET {
        Request::get(route_max_version(
            "",
            DIARY,
            Some(&[("id", &TEST_DIARY.id.0.to_string())]),
        ))
        .header(header.0, header.1)
        .body(Body::empty())
    } else {
        Request::builder()
            .method(&method)
            .uri(route_max_version("", DIARY, None))
            .header(header.0, header.1)
            .header(CONTENT_TYPE, APPLICATION_JSON.as_ref())
            .body(serde_json::to_string(&TEST_DIARY as &Diary).unwrap().into())
    };
    let response = request(&mut ctx.router, diary_request.unwrap()).await;

    assert_eq!(response.status(), status);
    assert_json(&response);
    if method == Method::GET && status == StatusCode::OK {
        let diary: Vec<Diary> = parse_body(response).await;
        assert_eq!(diary.len(), 1);
        assert_eq!(diary[0].id, TEST_DIARY.id);
    }
}

#[rstest]
#[tokio::test]
async fn request_gzip(#[future(awt)] mut ctx: TestContext) {
    DiaryDb::create(&TEST_DIARY, &mut ctx.db_pool.get().await.unwrap())
        .await
        .unwrap();

    let header = auth_header(&TEST_USER.username, &TEST_USER.password);
    let response = request(
        &mut ctx.router,
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
    assert_eq!(
        response.headers().get(CONTENT_ENCODING),
        Some(&HeaderValue::from_static("gzip"))
    );
    let diary: Vec<Diary> = parse_gzip_body(response).await;
    assert_eq!(diary.len(), 1);
    assert_eq!(diary[0].id, TEST_DIARY.id);
}

#[rstest]
#[case::new_session_with_live_route(true, false, false, true)]
#[case::new_session_with_route_deleted_on_server(true, true, false, false)]
#[case::changed_session_with_route_deleted_on_server(true, true, true, false)]
#[case::new_session_with_route_never_synced(false, false, false, false)]
#[tokio::test]
async fn cardio_session_referencing_missing_route(
    #[future(awt)] mut ctx: TestContext,
    #[case] route_created: bool,
    #[case] route_deleted: bool,
    #[case] session_exists: bool,
    #[case] route_kept: bool,
) {
    let mut db = ctx.db_pool.get().await.unwrap();
    let movement = Movement {
        movement_dimension: MovementDimension::Distance,
        cardio: true,
        ..movement(Some(TEST_USER.id))
    };
    MovementDb::create(&movement, &mut db).await.unwrap();
    let mut route = route(TEST_USER.id);
    if route_created {
        RouteDb::create(&route, &mut db).await.unwrap();
    }
    if route_deleted {
        route.deleted = true;
        RouteDb::update(&route, &mut db).await.unwrap();
    }
    let mut cardio_session = cardio_session(TEST_USER.id, movement.id);
    if session_exists {
        CardioSessionDb::create(&cardio_session, &mut db)
            .await
            .unwrap();
    }
    drop(db);

    cardio_session.route_id = Some(route.id);
    let uri = route_max_version("", CARDIO_SESSION, None);
    let header = auth_header(&TEST_USER.username, &TEST_USER.password);
    let response = request(
        &mut ctx.router,
        if session_exists {
            Request::put(uri)
        } else {
            Request::post(uri)
        }
        .header(header.0, header.1)
        .header(CONTENT_TYPE, APPLICATION_JSON.as_ref())
        .body(serde_json::to_string(&cardio_session).unwrap().into())
        .unwrap(),
    )
    .await;

    assert_eq!(response.status(), StatusCode::OK);
    let route_id: Option<RouteId> = cardio_session::table
        .find(cardio_session.id)
        .select(cardio_session::route_id)
        .get_result(&mut ctx.db_pool.get().await.unwrap())
        .await
        .unwrap();
    assert_eq!(route_id, route_kept.then_some(route.id));
}

#[rstest]
#[tokio::test]
async fn get_account_data(#[future(awt)] mut ctx: TestContext) {
    // get all - check empty
    let (status, account_data) = account_data_request(&mut ctx.router, None).await;
    let epoch = account_data.epoch_map;

    assert_eq!(status, StatusCode::OK);
    assert!(account_data.diaries.is_empty());

    // get updates - check no new data
    let (status, account_data) = account_data_request(&mut ctx.router, Some(epoch)).await;
    let epoch = account_data.epoch_map;

    assert_eq!(status, StatusCode::OK);
    assert!(account_data.diaries.is_empty());

    // get updates - check new diary
    DiaryDb::create(&TEST_DIARY, &mut ctx.db_pool.get().await.unwrap())
        .await
        .unwrap();
    let (status, account_data) = account_data_request(&mut ctx.router, Some(epoch)).await;
    let epoch = account_data.epoch_map;

    assert_eq!(status, StatusCode::OK);
    assert_eq!(account_data.diaries.len(), 1);
    assert_eq!(account_data.diaries[0].id, TEST_DIARY.id);

    // get updates - check no new data
    let (status, account_data) = account_data_request(&mut ctx.router, Some(epoch)).await;
    let epoch = account_data.epoch_map;

    assert_eq!(status, StatusCode::OK);
    assert!(account_data.diaries.is_empty());

    // get updates - check updated diary
    DiaryDb::update(&TEST_DIARY, &mut ctx.db_pool.get().await.unwrap())
        .await
        .unwrap();
    let (status, account_data) = account_data_request(&mut ctx.router, Some(epoch)).await;

    assert_eq!(status, StatusCode::OK);
    assert_eq!(account_data.diaries.len(), 1);
    assert_eq!(account_data.diaries[0].id, TEST_DIARY.id);

    // get all - check diary
    let (status, account_data) = account_data_request(&mut ctx.router, None).await;

    assert_eq!(status, StatusCode::OK);
    assert_eq!(account_data.diaries.len(), 1);
    assert_eq!(account_data.diaries[0].id, TEST_DIARY.id);
}

#[rstest]
#[tokio::test]
async fn get_account_data_in_epoch_order(#[future(awt)] mut ctx: TestContext) {
    // One table for each of the macros `GetByUserAndEpoch`, `GetByUserAndEpochOptional` and
    // `GetByEpoch`, and one for the manual implementation of action providers.
    let (_, account_data) = account_data_request(&mut ctx.router, None).await;
    let epoch_map = account_data.epoch_map;

    let mut db = ctx.db_pool.get().await.unwrap();
    let mut diary = TEST_DIARY.clone();
    DiaryDb::create(&diary, &mut db).await.unwrap();
    diary.deleted = true;
    DiaryDb::update(&diary, &mut db).await.unwrap();
    let new_diary = Diary {
        id: DiaryId(rnd()),
        ..TEST_DIARY.clone()
    };
    DiaryDb::create(&new_diary, &mut db).await.unwrap();
    let mut movement = movement(Some(TEST_USER.id));
    MovementDb::create(&movement, &mut db).await.unwrap();
    movement.deleted = true;
    MovementDb::update(&movement, &mut db).await.unwrap();
    let new_movement = Movement {
        id: MovementId(rnd()),
        deleted: false,
        ..movement.clone()
    };
    MovementDb::create(&new_movement, &mut db).await.unwrap();
    let mut platform = platform();
    PlatformDb::create(&platform, &mut db).await.unwrap();
    platform.deleted = true;
    PlatformDb::update(&platform, &mut db).await.unwrap();
    let new_platform = Platform {
        id: PlatformId(rnd()),
        deleted: false,
        ..platform.clone()
    };
    PlatformDb::create(&new_platform, &mut db).await.unwrap();
    let action_provider = action_provider(TEST_PLATFORM.id);
    ActionProviderDb::create(&mut action_provider.clone(), &mut db)
        .await
        .unwrap();
    diesel::delete(action_provider::table.find(action_provider.id))
        .execute(&mut db)
        .await
        .unwrap();
    let new_action_provider = ActionProvider {
        id: ActionProviderId(rnd()),
        ..action_provider.clone()
    };
    ActionProviderDb::create(&mut new_action_provider.clone(), &mut db)
        .await
        .unwrap();
    drop(db);

    let (_, account_data) = account_data_request(&mut ctx.router, Some(epoch_map)).await;

    let ids: Vec<_> = account_data.diaries.iter().map(|d| d.id).collect();
    assert_eq!(ids, [diary.id, new_diary.id]);
    let ids: Vec<_> = account_data.movements.iter().map(|m| m.id).collect();
    assert_eq!(ids, [movement.id, new_movement.id]);
    let ids: Vec<_> = account_data.platforms.iter().map(|p| p.id).collect();
    assert_eq!(ids, [platform.id, new_platform.id]);
    let ids: Vec<_> = account_data
        .action_providers
        .iter()
        .map(|ap| ap.id)
        .collect();
    assert_eq!(ids, [action_provider.id, new_action_provider.id]);
}

#[rstest]
#[tokio::test]
async fn epoch_from_create_and_update(#[future(awt)] mut ctx: TestContext) {
    // get account data - check empty & extract diary epoch
    let (status, account_data) = account_data_request(&mut ctx.router, None).await;
    let epoch = account_data.epoch_map.diary;

    assert_eq!(status, StatusCode::OK);
    assert!(account_data.diaries.is_empty());

    // create new diary - check epoch increased by one
    let header = auth_header(&TEST_USER.username, &TEST_USER.password);
    let response = request(
        &mut ctx.router,
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
        &mut ctx.router,
        Request::put(route_max_version("", DIARY, None))
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

#[rstest]
#[case::soft_delete(false)]
#[case::hard_delete(true)]
#[tokio::test]
async fn epoch_from_cascaded_delete(
    #[future(awt)] mut ctx: TestContext,
    #[case] hard_delete: bool,
) {
    let credential = platform_credential(TEST_USER.id, TEST_PLATFORM.id);
    let mut db = ctx.db_pool.get().await.unwrap();
    PlatformCredentialDb::create(&credential, &mut db)
        .await
        .unwrap();
    drop(db);

    let (_, account_data) = account_data_request(&mut ctx.router, None).await;
    let epoch_map = account_data.epoch_map;

    let mut db = ctx.db_pool.get().await.unwrap();
    if hard_delete {
        diesel::delete(platform::table.find(TEST_PLATFORM.id))
            .execute(&mut db)
            .await
            .unwrap();
    } else {
        let mut platform = TEST_PLATFORM.clone();
        platform.deleted = true;
        PlatformDb::update(&platform, &mut db).await.unwrap();
    }
    drop(db);

    let (_, account_data) = account_data_request(&mut ctx.router, Some(epoch_map.clone())).await;

    assert_eq!(account_data.platform_credentials.len(), 1);
    assert_eq!(account_data.platform_credentials[0].id, credential.id);
    assert!(account_data.platform_credentials[0].deleted);
    assert_eq!(account_data.epoch_map.platform.0, epoch_map.platform.0 + 1);
    assert_eq!(
        account_data.epoch_map.platform_credential.0,
        epoch_map.platform_credential.0 + 1
    );
}

#[rstest]
#[tokio::test]
async fn epoch_from_cascaded_delete_of_multiple_rows(#[future(awt)] mut ctx: TestContext) {
    let mut db = ctx.db_pool.get().await.unwrap();
    let mut action_event_ids = Vec::new();
    for days in 1..=2 {
        let action_event = ActionEvent {
            datetime: Utc::now() + Duration::try_days(days).unwrap(),
            ..action_event(TEST_USER.id, TEST_ACTION.id)
        };
        ActionEventDb::create(&action_event, &mut db).await.unwrap();
        action_event_ids.push(action_event.id);
    }
    drop(db);

    let (_, account_data) = account_data_request(&mut ctx.router, None).await;
    let epoch_map = account_data.epoch_map;

    diesel::delete(action_provider::table.find(TEST_AP.id))
        .execute(&mut ctx.db_pool.get().await.unwrap())
        .await
        .unwrap();

    let (_, account_data) = account_data_request(&mut ctx.router, Some(epoch_map.clone())).await;

    let mut deleted_ids: Vec<_> = account_data
        .action_events
        .iter()
        .inspect(|action_event| assert!(action_event.deleted))
        .map(|action_event| action_event.id)
        .collect();
    deleted_ids.sort_by_key(|id| id.0);
    action_event_ids.sort_by_key(|id| id.0);
    assert_eq!(deleted_ids, action_event_ids);
    assert_eq!(
        account_data.epoch_map.action_event.0,
        epoch_map.action_event.0 + 2
    );
}

#[rstest]
#[case::global_first(true)]
#[case::user_first(false)]
#[tokio::test]
async fn epoch_from_create_of_user_and_global_movements(
    #[future(awt)] mut ctx: TestContext,
    #[case] global_first: bool,
) {
    let (first_user_id, second_user_id) = if global_first {
        (None, Some(TEST_USER.id))
    } else {
        (Some(TEST_USER.id), None)
    };
    // enough movements to raise their epochs above the user's and the global movements
    let mut db = ctx.db_pool.get().await.unwrap();
    let epoch = MovementDb::get_epoch_by_user_optional(TEST_USER.id, &mut db)
        .await
        .unwrap();
    let movements: Vec<_> = (0..=epoch.0).map(|_| movement(first_user_id)).collect();
    MovementDb::create_multiple(&movements, &mut db)
        .await
        .unwrap();
    drop(db);

    let (_, account_data) = account_data_request(&mut ctx.router, None).await;
    let epoch_map = account_data.epoch_map;

    let movement = movement(second_user_id);
    MovementDb::create(&movement, &mut ctx.db_pool.get().await.unwrap())
        .await
        .unwrap();

    let (_, account_data) = account_data_request(&mut ctx.router, Some(epoch_map)).await;

    let ids: Vec<_> = account_data.movements.iter().map(|m| m.id).collect();
    assert_eq!(ids, [movement.id]);
}

#[rstest]
#[case::enabled(true, StatusCode::OK)]
#[case::disabled(false, StatusCode::FORBIDDEN)]
#[tokio::test]
async fn user_self_registration(#[case] enabled: bool, #[case] status: StatusCode) {
    let mut ctx = ctx(enabled, !enabled).await;

    let user = user();

    let response = request(
        &mut ctx.router,
        Request::post(route_max_version("", USER, None))
            .header(CONTENT_TYPE, APPLICATION_JSON.as_ref())
            .body(serde_json::to_string(&user).unwrap().into())
            .unwrap(),
    )
    .await;

    assert_eq!(response.status(), status);
}

#[rstest]
#[case::enabled(true, StatusCode::OK)]
#[case::disabled(false, StatusCode::FORBIDDEN)]
#[tokio::test]
async fn ap_self_registration(#[case] enabled: bool, #[case] status: StatusCode) {
    let mut ctx = ctx(!enabled, enabled).await;

    let platform = platform();

    let response = request(
        &mut ctx.router,
        Request::post(route_max_version("", AP_PLATFORM, None))
            .header(CONTENT_TYPE, APPLICATION_JSON.as_ref())
            .body(serde_json::to_string(&platform).unwrap().into())
            .unwrap(),
    )
    .await;

    assert_eq!(response.status(), status);

    let response = request(
        &mut ctx.router,
        Request::get(route_max_version("", AP_PLATFORM, None))
            .body(Body::empty())
            .unwrap(),
    )
    .await;

    assert_eq!(response.status(), status);

    let action_provider = action_provider(TEST_PLATFORM.id);

    let response = request(
        &mut ctx.router,
        Request::post(route_max_version("", AP_ACTION_PROVIDER, None))
            .header(CONTENT_TYPE, APPLICATION_JSON.as_ref())
            .body(serde_json::to_string(&action_provider).unwrap().into())
            .unwrap(),
    )
    .await;

    assert_eq!(response.status(), status);
}
