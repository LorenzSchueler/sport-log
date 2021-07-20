use std::ops::Deref;

use diesel::{PgConnection, QueryResult};
use rocket::{
    http::Status,
    outcome::Outcome,
    request::{FromRequest, Request},
};

use crate::types::{ActionProvider, ActionProviderId, Db, User, UserId, CONFIG};

pub struct AuthenticatedUser(UserId);

impl Deref for AuthenticatedUser {
    type Target = UserId;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

pub struct AuthenticatedActionProvider(ActionProviderId);

impl Deref for AuthenticatedActionProvider {
    type Target = ActionProviderId;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

pub struct AuthenticatedAdmin;

fn parse_username_password(request: &'_ Request<'_>) -> Option<(String, String)> {
    let auth_header = request.headers().get("Authorization").next()?;
    if auth_header.len() >= 7 && &auth_header[..6] == "Basic " {
        let auth_str = String::from_utf8(base64::decode(&auth_header[6..]).ok()?).ok()?;
        let mut username_password = auth_str.splitn(2, ':');
        let username = username_password.next()?;
        let password = username_password.next()?;

        Some((username.to_owned(), password.to_owned()))
    } else {
        None
    }
}

async fn authenticate<R: Send + 'static>(
    request: &'_ Request<'_>,
    auth_method: fn(&str, &str, &PgConnection) -> QueryResult<R>,
) -> Outcome<R, (Status, ()), ()> {
    let (username, password) = match parse_username_password(request) {
        Some((username, password)) => (username, password),
        None => return Outcome::Failure((Status::Unauthorized, ())),
    };

    let conn = match Db::from_request(request).await {
        Outcome::Success(conn) => conn,
        Outcome::Failure(f) => return Outcome::Failure(f),
        Outcome::Forward(f) => return Outcome::Forward(f),
    };
    conn.run(move |c| match auth_method(&username, &password, c) {
        Ok(user_id) => Outcome::Success(user_id),
        Err(_) => Outcome::Failure((Status::Unauthorized, ())),
    })
    .await
}

#[rocket::async_trait]
impl<'r> FromRequest<'r> for AuthenticatedUser {
    type Error = ();

    async fn from_request(request: &'r Request<'_>) -> Outcome<Self, (Status, Self::Error), ()> {
        match authenticate::<UserId>(request, User::authenticate).await {
            Outcome::Success(user_id) => Outcome::Success(Self(user_id)),
            Outcome::Failure(f) => Outcome::Failure(f),
            Outcome::Forward(f) => Outcome::Forward(f),
        }
    }
}

#[rocket::async_trait]
impl<'r> FromRequest<'r> for AuthenticatedActionProvider {
    type Error = ();

    async fn from_request(request: &'r Request<'_>) -> Outcome<Self, (Status, Self::Error), ()> {
        match authenticate::<ActionProviderId>(request, ActionProvider::authenticate).await {
            Outcome::Success(action_provider_id) => Outcome::Success(Self(action_provider_id)),
            Outcome::Failure(f) => Outcome::Failure(f),
            Outcome::Forward(f) => Outcome::Forward(f),
        }
    }
}

#[rocket::async_trait]
impl<'r> FromRequest<'r> for AuthenticatedAdmin {
    type Error = ();

    async fn from_request(request: &'r Request<'_>) -> Outcome<Self, (Status, Self::Error), ()> {
        match parse_username_password(request) {
            Some((username, password))
                if username == CONFIG.admin_username && password == CONFIG.admin_password =>
            {
                Outcome::Success(Self)
            }
            _ => Outcome::Failure((Status::Unauthorized, ())),
        }
    }
}
