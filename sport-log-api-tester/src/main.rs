//! The sport-log-api-tester sends HTTP request to the server and prints the formatted response.
//!
//! # Usage
//!
//! sport-log-api-tester \[OPTIONS\]
//!
//! ### OPTIONS
//!
//! POST `endpoint` `data`
//!
//! POST `endpoint` `username` `password` `data`
//!
//! GET `endpoint` `username` `password`
//!
//! PUT `endpoint` `username` `password` `data`
//!
//! DELETE `endpoint` `username` `password`
//!
//! # Examples
//!
//! Create a [User](../sport_log_types/types/struct.User.html)
//!
//! ```sh
//! sport-log-api-tester POST /v1/user '
//! {
//!     "username": "MyUsername",
//!     "password": "MyPassword",
//!     "email": "MyEmail"
//! }'
//! ```
//!
//! Create new [PlatformCredential](../sport_log_types/types/struct.PlatformCredential.html)
//!
//! ```sh
//! sport-log-api-tester POST /v1/platform_credential MyUsername MyPassword '
//! {
//!     "user_id": 4,
//!     "platform_id": 1,
//!     "username": "MyUsernameForPlatform1",
//!     "password": "MyPasswordForPlatform1"
//! }'
//! ```
//!
//! Get own [User](../sport_log_types/types/struct.User.html)
//!
//! ```sh
//! sport-log-api-tester GET /v1/user MyUsername MyPassword
//! ```
//!
//! Update own [User](../sport_log_types/types/struct.User.html)
//!
//! ```sh
//! sport-log-api-tester PUT /v1/user MyUsername MyPassword '
//! {
//!     "id": 4,
//!     "username": "MyNewUsername",
//!     "password": "MyNewPassword",
//!     "email": "MyNewEmail"
//! }'
//! ```
//!
//! Delete own [User](../sport_log_types/types/struct.User.html)
//!
//! ```sh
//! sport-log-api-tester DELETE /v1/user MyUsername MyPassword
//! ```

use std::{
    env::{self},
    process,
};

use reqwest::{
    blocking::Client,
    header::{HeaderValue, CONTENT_TYPE},
};
use serde_json::Value;

const BASE_URL: &str = "http://localhost:8000";

fn main() {
    let args: Vec<_> = env::args().collect();
    let (mut request, credentials, data) = match &args[1..] {
        [method, endpoint, data] if method == "POST" => {
            let request = Client::new().post(format!("{}{}", BASE_URL, endpoint));
            (request, None, Some(data))
        }
        [method, endpoint, username, password, data] if method == "POST" => {
            let request = Client::new().post(format!("{}{}", BASE_URL, endpoint));
            (request, Some((username, password)), Some(data))
        }
        [method, endpoint, username, password] if method == "GET" => {
            let request = Client::new().get(format!("{}{}", BASE_URL, endpoint));
            (request, Some((username, password)), None)
        }
        [method, endpoint, username, password, data] if method == "PUT" => {
            let request = Client::new().put(format!("{}{}", BASE_URL, endpoint));
            (request, Some((username, password)), Some(data))
        }
        [method, endpoint, username, password] if method == "DELETE" => {
            let request = Client::new().delete(format!("{}{}", BASE_URL, endpoint));
            (request, Some((username, password)), None)
        }
        _ => {
            println!(
                "sport-log-api-tester\n\n\
                
                OPTIONS:\n\
                POST <endpoint> <data>\n\
                POST <endpoint> <username> <password> <data>\n\
                GET <endpoint> <username> <password>\n\
                PUT <endpoint> <username> <password> <data>\n\
                DELETE <endpoint> <username> <password>"
            );
            process::exit(1);
        }
    };

    if let Some((username, password)) = credentials {
        request = request.basic_auth(username, Some(password));
    }
    if let Some(data) = data {
        request = request.body(data.to_owned());
        request = request.header(CONTENT_TYPE, "application/json");
    }
    let response = request.send().unwrap();

    println!("{}\n", response.status());
    println!("{:#?}\n", response.headers());
    if response.headers().get(CONTENT_TYPE) == Some(&HeaderValue::from_static("application/json")) {
        let response = response.json::<Value>().unwrap();
        println!("{}", serde_json::to_string_pretty(&response).unwrap());
    } else {
        println!("{}", response.text().unwrap());
    }
}
