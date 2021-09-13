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

use sport_log_types::{Config, ADMIN_USERNAME};

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

fn assert_ok_json(response: &LocalResponse) {
    assert_eq!(Status::Ok, response.status());
    assert_eq!(
        "application/json",
        response.headers().get_one("Content-Type").unwrap(),
    );
}

fn assert_unauthorized_json(response: &LocalResponse) {
    assert_eq!(Status::Unauthorized, response.status());
    assert_eq!(
        "application/json",
        response.headers().get_one("Content-Type").unwrap(),
    );
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

// TODO test Status::Forbidden if access to element not allowed
// TODO test self registration
