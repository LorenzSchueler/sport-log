use rocket::{http::Status, serde::json::Json};

use crate::{auth::AuthenticatedUser, model::User};

impl User {
    pub fn verify(user: Json<User>, auth: AuthenticatedUser) -> Result<User, Status> {
        let user = user.into_inner();
        if user.id == *auth {
            Ok(user)
        } else {
            Err(Status::Forbidden)
        }
    }
}
