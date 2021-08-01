use std::ops::Deref;

use rocket::{
    http::Status,
    outcome::Outcome,
    request::{FromRequest, Request},
};

use crate::{ActionProvider, ActionProviderId, Admin, Db, User, UserId};

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

#[rocket::async_trait]
impl<'r> FromRequest<'r> for AuthenticatedUser {
    type Error = ();

    async fn from_request(request: &'r Request<'_>) -> Outcome<Self, (Status, Self::Error), ()> {
        let (username, password) = match parse_username_password(request) {
            Some((username, password)) => (username, password),
            None => return Outcome::Failure((Status::Unauthorized, ())),
        };

        let conn = match Db::from_request(request).await {
            Outcome::Success(conn) => conn,
            Outcome::Failure(f) => return Outcome::Failure(f),
            Outcome::Forward(f) => return Outcome::Forward(f),
        };
        conn.run(move |c| match User::auth(&username, &password, c) {
            Ok(id) => Outcome::Success(AuthenticatedUser(id)),
            Err(_) => {
                if let Some((name, Ok(user_id))) = username
                    .split_once("$id$")
                    .map(|(name, id)| (name, id.parse().map(UserId)))
                {
                    if ActionProvider::auth_as_user(&name, &password, user_id, c).is_ok() {
                        return Outcome::Success(AuthenticatedUser(user_id));
                    } else if Admin::auth(&name, &password, c).is_ok() {
                        return Outcome::Success(AuthenticatedUser(user_id));
                    }
                };
                Outcome::Failure((Status::Unauthorized, ()))
            }
        })
        .await
    }
}

#[rocket::async_trait]
impl<'r> FromRequest<'r> for AuthenticatedActionProvider {
    type Error = ();

    async fn from_request(request: &'r Request<'_>) -> Outcome<Self, (Status, Self::Error), ()> {
        let (username, password) = match parse_username_password(request) {
            Some((username, password)) => (username, password),
            None => return Outcome::Failure((Status::Unauthorized, ())),
        };

        let conn = match Db::from_request(request).await {
            Outcome::Success(conn) => conn,
            Outcome::Failure(f) => return Outcome::Failure(f),
            Outcome::Forward(f) => return Outcome::Forward(f),
        };
        conn.run(
            move |c| match ActionProvider::auth(&username, &password, c) {
                Ok(id) => Outcome::Success(AuthenticatedActionProvider(id)),
                Err(_) => {
                    if let Some((name, Ok(id))) = username
                        .split_once("$id$")
                        .map(|(name, id)| (name, id.parse()))
                    {
                        if Admin::auth(&name, &password, c).is_ok() {
                            return Outcome::Success(AuthenticatedActionProvider(
                                ActionProviderId(id),
                            ));
                        }
                    };
                    Outcome::Failure((Status::Unauthorized, ()))
                }
            },
        )
        .await
    }
}

#[rocket::async_trait]
impl<'r> FromRequest<'r> for AuthenticatedAdmin {
    type Error = ();

    async fn from_request(request: &'r Request<'_>) -> Outcome<Self, (Status, Self::Error), ()> {
        let (username, password) = match parse_username_password(request) {
            Some((username, password)) => (username, password),
            None => return Outcome::Failure((Status::Unauthorized, ())),
        };

        let conn = match Db::from_request(request).await {
            Outcome::Success(conn) => conn,
            Outcome::Failure(f) => return Outcome::Failure(f),
            Outcome::Forward(f) => return Outcome::Forward(f),
        };
        conn.run(move |c| match Admin::auth(&username, &password, c) {
            Ok(_) => Outcome::Success(AuthenticatedAdmin),
            Err(_) => Outcome::Failure((Status::Unauthorized, ())),
        })
        .await
    }
}
