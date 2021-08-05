use std::ops::Deref;

use rocket::{
    http::Status,
    outcome::Outcome,
    request::{FromRequest, Request},
};

use crate::{ActionProvider, ActionProviderId, Admin, Db, User, UserId};

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

/// [AuthUser] is used as a request guard to ensure that the endpoint can only be accessed by the user who owns the data.
///
/// For the creation of an [AuthUser] the username and password have to be transmitted via HTTP basic auth.
///
/// [Admin] can also use endpoints with an [AuthUser] as request guard.
///
/// In order to do so, the username has to be set to `admin$id$<user_id>` and the password is the password of the [Admin] as configured in [Config](crate::Config).
pub struct AuthUser(UserId);

impl Deref for AuthUser {
    type Target = UserId;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

#[rocket::async_trait]
impl<'r> FromRequest<'r> for AuthUser {
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
            Ok(id) => Outcome::Success(AuthUser(id)),
            Err(_) => {
                if let Some((name, Ok(user_id))) = username
                    .split_once("$id$")
                    .map(|(name, id)| (name, id.parse().map(UserId)))
                {
                    if Admin::auth(name, &password, c).is_ok() {
                        return Outcome::Success(AuthUser(user_id));
                    }
                };
                Outcome::Failure((Status::Unauthorized, ()))
            }
        })
        .await
    }
}

/// [AuthUserOrAP] is used as a request guard to ensure that the endpoint can only be accessed by the user who owns the data.
///
/// For the creation of an [AuthUserOrAP] the username and password have to be transmitted via HTTP basic auth.
///
/// [ActionProvider] can also use endpoints with an [AuthUserOrAP] as request guard
/// if there is an [ActionEvent](crate::ActionEvent) which references an [Action](crate::Action) that is provided by the [ActionProvider]
/// and the [ActionEvent](crate::ActionEvent) is owned by the [User] the [ActionProvider] is trying to authenticate as.
///
/// In this case the username has to be set to `<ap_name>$id$<user_id>` and the password is the password of the [ActionProvider].
///
/// [Admin] can also use endpoints with an [AuthUserOrAP] as request guard.
///
/// In order to do so, the username has to be set to `admin$id$<user_id>` and the password is the password of the [Admin] as configured in [Config](crate::Config).
pub struct AuthUserOrAP(UserId);

impl Deref for AuthUserOrAP {
    type Target = UserId;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

#[rocket::async_trait]
impl<'r> FromRequest<'r> for AuthUserOrAP {
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
            Ok(id) => Outcome::Success(AuthUserOrAP(id)),
            Err(_) => {
                if let Some((name, Ok(user_id))) = username
                    .split_once("$id$")
                    .map(|(name, id)| (name, id.parse().map(UserId)))
                {
                    if ActionProvider::auth_as_user(name, &password, user_id, c).is_ok()
                        || Admin::auth(name, &password, c).is_ok()
                    {
                        return Outcome::Success(AuthUserOrAP(user_id));
                    }
                };
                Outcome::Failure((Status::Unauthorized, ()))
            }
        })
        .await
    }
}

/// [AuthAP] is used as a request guard to ensure that the endpoint can only be accessed by the [ActionProvider] who provides the [ActionEvent](crate::ActionEvent).
///
/// For the creation of an [AuthAP] the username and password have to be transmitted via HTTP basic auth.
///
/// [Admin] can also use endpoints with an [AuthAP] as request guard.
///
/// In order to do so, the username has to be set to `admin$id$<action_provider_id>` and the password is the password of the [Admin] as configured in [Config](crate::Config).
pub struct AuthAP(ActionProviderId);

impl Deref for AuthAP {
    type Target = ActionProviderId;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

#[rocket::async_trait]
impl<'r> FromRequest<'r> for AuthAP {
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
                Ok(id) => Outcome::Success(AuthAP(id)),
                Err(_) => {
                    if let Some((name, Ok(id))) = username
                        .split_once("$id$")
                        .map(|(name, id)| (name, id.parse()))
                    {
                        if Admin::auth(name, &password, c).is_ok() {
                            return Outcome::Success(AuthAP(ActionProviderId(id)));
                        }
                    };
                    Outcome::Failure((Status::Unauthorized, ()))
                }
            },
        )
        .await
    }
}

/// [AuthAdmin] is used as a request guard to ensure that the endpoint can only be accessed by the [Admin].
///
/// For the creation of an [AuthAdmin] the username and password have to be transmitted via HTTP basic auth.
///
/// The username has to be set to `admin` and the password is the password of the [Admin] as configured in [Config](crate::Config).
pub struct AuthAdmin;

#[rocket::async_trait]
impl<'r> FromRequest<'r> for AuthAdmin {
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
            Ok(_) => Outcome::Success(AuthAdmin),
            Err(_) => Outcome::Failure((Status::Unauthorized, ())),
        })
        .await
    }
}
