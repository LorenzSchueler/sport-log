use base64;
use rocket::{
    http::Status,
    outcome::Outcome,
    request::{FromRequest, Outcome as FromRequestOutcome, Request},
};

#[derive(Debug)]
pub enum BasicAuthError {
    NoAuth,
    Invalid,
}

#[derive(Debug)]
pub struct BasicAuth {
    pub username: String,
    pub password: String,
}

impl BasicAuth {
    pub fn new(raw_header: &str) -> Result<Self, BasicAuthError> {
        if raw_header.len() < 7 || &raw_header[..6] != "Basic " {
            return Err(BasicAuthError::NoAuth);
        }

        let auth_str =
            String::from_utf8(base64::decode(raw_header).map_err(|_| BasicAuthError::Invalid)?)
                .map_err(|_| BasicAuthError::Invalid)?;
        let username_password: Vec<&str> = auth_str.splitn(2, ":").collect();

        if username_password.len() < 2 {
            return Err(BasicAuthError::Invalid);
        }
        Ok(Self {
            username: username_password[0].to_owned(),
            password: username_password[1].to_owned(),
        })
    }
}

//#[rocket::async_trait]
impl<'r> FromRequest<'r, 'r> for BasicAuth {
    type Error = BasicAuthError;

    fn from_request(request: &'r Request<'_>) -> FromRequestOutcome<Self, Self::Error> {
        match request.headers().get("Authorization").next() {
            None => Outcome::Forward(()),
            Some(auth_header) => match BasicAuth::new(auth_header) {
                Ok(basic_auth) => Outcome::Success(basic_auth),
                Err(error) => Outcome::Failure((Status::BadRequest, error)),
            },
        }
    }
}
