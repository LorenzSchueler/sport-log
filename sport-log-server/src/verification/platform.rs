use rocket::{http::Status, serde::json::Json};

use sport_log_server_derive::{
    InnerIntFromParam, VerifyIdForAdmin, VerifyIdForUser, VerifyIdForUserWithoutCheck,
};

use crate::{
    auth::{AuthenticatedAdmin, AuthenticatedUser},
    model::{NewPlatform, NewPlatformCredentials, Platform, PlatformCredentials},
};

impl NewPlatform {
    pub fn verify_adm(
        platform: Json<NewPlatform>,
        _auth: &AuthenticatedAdmin,
    ) -> Result<NewPlatform, Status> {
        Ok(platform.into_inner())
    }
}

impl Platform {
    pub fn verify_adm(
        platform: Json<Platform>,
        _auth: &AuthenticatedAdmin,
    ) -> Result<Platform, Status> {
        Ok(platform.into_inner())
    }
}

#[derive(InnerIntFromParam, VerifyIdForAdmin, VerifyIdForUserWithoutCheck)]
pub struct UnverifiedPlatformId(i32);

impl NewPlatformCredentials {
    pub fn verify(
        platform_credentials: Json<NewPlatformCredentials>,
        auth: &AuthenticatedUser,
    ) -> Result<NewPlatformCredentials, Status> {
        let platform_credentials = platform_credentials.into_inner();
        if platform_credentials.user_id == **auth {
            Ok(platform_credentials)
        } else {
            Err(Status::Forbidden)
        }
    }
}

impl PlatformCredentials {
    pub fn verify(
        platform_credentials: Json<PlatformCredentials>,
        auth: &AuthenticatedUser,
    ) -> Result<PlatformCredentials, Status> {
        let platform_credentials = platform_credentials.into_inner();
        if platform_credentials.user_id == **auth {
            Ok(platform_credentials)
        } else {
            Err(Status::Forbidden)
        }
    }
}

#[derive(VerifyIdForUser, InnerIntFromParam)]
pub struct UnverifiedPlatformCredentialsId(i32);
