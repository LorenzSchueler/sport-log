use std::ops::Deref;

use diesel::{PgConnection, QueryResult};
use rocket::{
    http::Status,
    outcome::Outcome,
    request::{FromRequest, Request},
};

use crate::{ActionProvider, ActionProviderId, Admin, Db, FromI32, User, UserId};

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

type AuthMethod<R> = fn(&str, &str, &PgConnection) -> QueryResult<R>;

async fn auth_with_fallback<R: FromI32 + Send + 'static>(
    request: &'_ Request<'_>,
    auth_method: AuthMethod<R>,
    fallback_auth_methods: Vec<AuthMethod<()>>,
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
        Ok(id) => Outcome::Success(id),
        Err(_) => {
            if let Some((name, Ok(id))) = username
                .split_once("$id$")
                .map(|(name, id)| (name, id.parse()))
            {
                for auth_method in fallback_auth_methods {
                    if auth_method(&name, &password, c).is_ok() {
                        return Outcome::Success(R::from_i32(id));
                    }
                }
            };
            Outcome::Failure((Status::Unauthorized, ()))
        }
    })
    .await
}

async fn auth<R: Send + 'static>(
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
        Ok(id) => Outcome::Success(id),
        Err(_) => Outcome::Failure((Status::Unauthorized, ())),
    })
    .await
}

#[rocket::async_trait]
impl<'r> FromRequest<'r> for AuthenticatedUser {
    type Error = ();

    async fn from_request(request: &'r Request<'_>) -> Outcome<Self, (Status, Self::Error), ()> {
        let ap_authenticate = |name: &str, password: &str, conn: &PgConnection| {
            ActionProvider::authenticate(name, password, conn).map(|_| ())
        };
        auth_with_fallback::<UserId>(
            request,
            User::authenticate,
            vec![ap_authenticate, Admin::authenticate],
        )
        .await
        .map(Self)
    }
}

#[rocket::async_trait]
impl<'r> FromRequest<'r> for AuthenticatedActionProvider {
    type Error = ();

    async fn from_request(request: &'r Request<'_>) -> Outcome<Self, (Status, Self::Error), ()> {
        auth_with_fallback::<ActionProviderId>(
            request,
            ActionProvider::authenticate,
            vec![Admin::authenticate],
        )
        .await
        .map(Self)
    }
}

#[rocket::async_trait]
impl<'r> FromRequest<'r> for AuthenticatedAdmin {
    type Error = ();

    async fn from_request(request: &'r Request<'_>) -> Outcome<Self, (Status, Self::Error), ()> {
        auth::<()>(request, Admin::authenticate)
            .await
            .map(|()| Self)
    }
}
