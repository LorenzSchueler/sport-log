use diesel::PgConnection;
use rocket::{http::Status, serde::json::Json};

use sport_log_server_derive::{FromParam, UnverifiedFromParamToVerifiedForUser};

use crate::{
    auth::AuthenticatedUser,
    model::{NewPlatformCredentials, PlatformCredentials, PlatformCredentialsId},
};

impl NewPlatformCredentials {
    pub fn verify(
        platform_credentials: Json<NewPlatformCredentials>,
        auth: AuthenticatedUser,
    ) -> Result<NewPlatformCredentials, Status> {
        let platform_credentials = platform_credentials.into_inner();
        if platform_credentials.user_id == *auth {
            Ok(platform_credentials)
        } else {
            Err(Status::Forbidden)
        }
    }
}

impl PlatformCredentials {
    pub fn verify(
        platform_credentials: Json<PlatformCredentials>,
        auth: AuthenticatedUser,
    ) -> Result<PlatformCredentials, Status> {
        let platform_credentials = platform_credentials.into_inner();
        if platform_credentials.user_id == *auth {
            Ok(platform_credentials)
        } else {
            Err(Status::Forbidden)
        }
    }
}

#[derive(UnverifiedFromParamToVerifiedForUser, FromParam)]
pub struct UnverifiedPlatformCredentialsId(PlatformCredentialsId);
