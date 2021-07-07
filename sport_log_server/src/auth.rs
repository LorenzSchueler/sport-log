use std::ops::Deref;

use diesel::{PgConnection, QueryResult};
use rocket::{
    http::Status,
    outcome::Outcome,
    request::{FromRequest, Request},
};

use crate::{
    model::{Account, AccountId, ActionProvider, ActionProviderId},
    Db,
};

pub struct AuthenticatedAccount {
    account_id: AccountId,
}

impl Deref for AuthenticatedAccount {
    type Target = AccountId;

    fn deref(&self) -> &Self::Target {
        &self.account_id
    }
}

pub struct AuthenticatedActionProvider {
    action_provider_id: ActionProviderId,
}

impl Deref for AuthenticatedActionProvider {
    type Target = ActionProviderId;

    fn deref(&self) -> &Self::Target {
        &self.action_provider_id
    }
}

fn parse_username_password(auth_header: &str) -> Option<(String, String)> {
    let auth_str = String::from_utf8(base64::decode(&auth_header[6..]).ok()?).ok()?;
    let mut username_password = auth_str.splitn(2, ':');
    let username = username_password.next()?;
    let password = username_password.next()?;

    Some((username.to_owned(), password.to_owned()))
}

fn authenticate<R>(
    request: &'_ Request<'_>,
    auth_method: fn(&str, &str, &PgConnection) -> QueryResult<R>,
) -> Outcome<R, (Status, ()), ()> {
    match request.headers().get("Authorization").next() {
        Some(auth_header) if auth_header.len() >= 7 && &auth_header[..6] == "Basic " => {
            let (username, password) = match parse_username_password(auth_header) {
                Some((username, password)) => (username, password),
                None => return Outcome::Failure((Status::BadRequest, ())),
            };

            let conn = match Db::from_request(request) {
                Outcome::Success(conn) => conn,
                Outcome::Failure(f) => return Outcome::Failure(f),
                Outcome::Forward(f) => return Outcome::Forward(f),
            };

            match auth_method(&username, &password, &conn) {
                Ok(account_id) => Outcome::Success(account_id),
                Err(_) => Outcome::Failure((Status::Unauthorized, ())),
            }
        }
        _ => Outcome::Failure((Status::Unauthorized, ())),
    }
}

//#[rocket::async_trait]
impl<'r> FromRequest<'_, '_> for AuthenticatedAccount {
    type Error = ();

    fn from_request(request: &'_ Request<'_>) -> Outcome<Self, (Status, Self::Error), ()> {
        match authenticate::<AccountId>(request, Account::authenticate) {
            Outcome::Success(account_id) => Outcome::Success(Self { account_id }),
            Outcome::Failure(f) => Outcome::Failure(f),
            Outcome::Forward(f) => Outcome::Forward(f),
        }
    }
}

impl<'r> FromRequest<'_, '_> for AuthenticatedActionProvider {
    type Error = ();

    fn from_request(request: &'_ Request<'_>) -> Outcome<Self, (Status, Self::Error), ()> {
        match authenticate::<ActionProviderId>(request, ActionProvider::authenticate) {
            Outcome::Success(action_provider_id) => Outcome::Success(Self { action_provider_id }),
            Outcome::Failure(f) => Outcome::Failure(f),
            Outcome::Forward(f) => Outcome::Forward(f),
        }
    }
}
