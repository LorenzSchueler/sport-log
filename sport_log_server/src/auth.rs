use base64;
use rocket::{
    http::Status,
    outcome::Outcome,
    request::{FromRequest, Outcome as FromRequestOutcome, Request},
};

use crate::{
    model::{Account, AccountId},
    Db,
};

#[derive(Debug)]
pub enum BasicAuthError {
    NoAuth,
    InvalidRequest,
}

#[derive(Debug)]
struct BasicAuth {
    pub username: String,
    pub password: String,
}

impl BasicAuth {
    pub fn new(raw_header: &str) -> Result<Self, BasicAuthError> {
        if raw_header.len() < 7 || &raw_header[..6] != "Basic " {
            return Err(BasicAuthError::NoAuth);
        }

        let auth_str = String::from_utf8(
            base64::decode(raw_header).map_err(|_| BasicAuthError::InvalidRequest)?,
        )
        .map_err(|_| BasicAuthError::InvalidRequest)?;
        let username_password: Vec<&str> = auth_str.splitn(2, ":").collect();

        if username_password.len() < 2 {
            return Err(BasicAuthError::InvalidRequest);
        }
        Ok(Self {
            username: username_password[0].to_owned(),
            password: username_password[1].to_owned(),
        })
    }
}

pub struct AuthenticatedAccount {
    account_id: AccountId,
}

//#[rocket::async_trait]
impl<'r> FromRequest<'_, '_> for AuthenticatedAccount {
    type Error = ();

    fn from_request(request: &'_ Request<'_>) -> FromRequestOutcome<Self, Self::Error> {
        match request.headers().get("Authorization").next() {
            None => Outcome::Forward(()),
            Some(auth_header) => match BasicAuth::new(auth_header) {
                Ok(basic_auth) => {
                    let conn = match Db::from_request(request) {
                        Outcome::Success(conn) => conn,
                        Outcome::Failure(f) => return Outcome::Failure(f),
                        Outcome::Forward(f) => return Outcome::Forward(f),
                    };

                    match Account::authenticate(basic_auth.username, basic_auth.password, &conn) {
                        Ok(account_id) => Outcome::Success(AuthenticatedAccount { account_id }),
                        Err(_) => Outcome::Failure((Status::Unauthorized, ())),
                    }
                }
                Err(_) => Outcome::Failure((Status::BadRequest, ())),
            },
        }
    }
}
