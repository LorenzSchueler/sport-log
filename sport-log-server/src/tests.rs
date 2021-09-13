use rocket::{
    http::{
        hyper::header::{
            ACCESS_CONTROL_ALLOW_CREDENTIALS, ACCESS_CONTROL_ALLOW_HEADERS,
            ACCESS_CONTROL_ALLOW_METHODS, ACCESS_CONTROL_ALLOW_ORIGIN, ACCESS_CONTROL_MAX_AGE,
            AUTHORIZATION,
        },
        Header, Status,
    },
    local::blocking::Client,
    Build, Rocket,
};

use sport_log_types::{Config, ADMIN_USERNAME};

use crate::rocket;

const ADMIN_PASSWORD: &str = "admin-passwd";

fn basic_auth_header<'h>(username: &str, password: &str) -> Header<'h> {
    Header::new(
        AUTHORIZATION.as_str(),
        format!(
            "Basic {}",
            base64::encode(format!("{}:{}", username, password))
        ),
    )
}

fn rocket_with_config() -> (Rocket<Build>, Config) {
    let rocket = rocket();
    let figment = rocket.figment();
    let config: Config = figment.extract().expect("unable to extract Config");

    (rocket, config)
}

#[test]
fn cors() {
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

#[test]
fn admin_auth() {
    let client = Client::untracked(rocket()).expect("valid rocket instance");
    let mut request = client.get("/v1/adm/platform");
    request.add_header(basic_auth_header(ADMIN_USERNAME, ADMIN_PASSWORD));
    let response = request.dispatch();
    assert_eq!(response.status(), Status::Ok);
    assert_eq!(
        response.headers().get_one("Content-Type").unwrap(),
        "application/json"
    );
}

#[test]
fn admin_auth_wrong_credentials() {
    let client = Client::untracked(rocket()).expect("valid rocket instance");

    let mut request = client.get("/v1/adm/platform");
    request.add_header(basic_auth_header("admin", "wrong password"));
    let response = request.dispatch();
    assert_eq!(response.status(), Status::Unauthorized);
    assert_eq!(
        response.headers().get_one("Content-Type").unwrap(),
        "application/json"
    );

    request = client.get("/v1/adm/platform");
    request.add_header(basic_auth_header("wrong username", "wrong password"));
    let response = request.dispatch();
    assert_eq!(response.status(), Status::Unauthorized);
    assert_eq!(
        response.headers().get_one("Content-Type").unwrap(),
        "application/json"
    );
}

#[test]
fn admin_auth_without_credentials() {
    let client = Client::untracked(rocket()).expect("valid rocket instance");
    let response = client.get("/v1/adm/platform").dispatch();
    assert_eq!(response.status(), Status::Unauthorized);
    assert_eq!(
        response.headers().get_one("Content-Type").unwrap(),
        "application/json"
    );
}

// TODO test Status::Forbidden if access to element not allowed
