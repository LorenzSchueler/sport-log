use std::ops::Deref;

use base64;
use rocket::{
    http::Status,
    outcome::Outcome,
    request::{FromRequest, Request},
};

use crate::{
    model::{Account, AccountId},
    Db,
};

pub struct AuthenticatedAccount {
    account_id: AccountId,
}

//#[rocket::async_trait]
impl<'r> FromRequest<'_, '_> for AuthenticatedAccount {
    type Error = ();

    fn from_request(request: &'_ Request<'_>) -> Outcome<Self, (Status, Self::Error), ()> {
        match request.headers().get("Authorization").next() {
            Some(auth_header) if auth_header.len() >= 7 && &auth_header[..6] == "Basic " => {
                let auth_str = match String::from_utf8(match base64::decode(auth_header) {
                    Ok(data) => data,
                    Err(_) => return Outcome::Failure((Status::BadRequest, ())),
                }) {
                    Ok(string) => string,
                    Err(_) => return Outcome::Failure((Status::BadRequest, ())),
                };
                let username_password: Vec<&str> = auth_str.splitn(2, ":").collect();

                if username_password.len() < 2 {
                    return Outcome::Failure((Status::BadRequest, ()));
                }
                let username = username_password.get(0).unwrap();
                let password = username_password.get(1).unwrap();

                let conn = match Db::from_request(request) {
                    Outcome::Success(conn) => conn,
                    Outcome::Failure(f) => return Outcome::Failure(f),
                    Outcome::Forward(f) => return Outcome::Forward(f),
                };

                match Account::authenticate(username, password, &conn) {
                    Ok(account_id) => Outcome::Success(AuthenticatedAccount { account_id }),
                    Err(_) => Outcome::Failure((Status::Unauthorized, ())),
                }
            }
            _ => Outcome::Forward(()),
        }
    }
}

impl Deref for AuthenticatedAccount {
    type Target = AccountId;

    fn deref(&self) -> &Self::Target {
        &self.account_id
    }
}
