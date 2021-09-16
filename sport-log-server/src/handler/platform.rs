use rocket::{http::Status, State};

use sport_log_types::{
    AuthAdmin, AuthUser, Config, Create, CreateMultiple, Db, GetAll, GetByUser, Platform,
    PlatformCredential, PlatformId, Unverified, UnverifiedId, Update, VerifyForAdminWithoutDb,
    VerifyForUserWithDb, VerifyForUserWithoutDb, VerifyIdUnchecked, VerifyMultipleForUserWithDb,
    VerifyMultipleForUserWithoutDb, VerifyUnchecked,
};

use crate::handler::{IntoJson, JsonError, JsonResult};

#[post("/adm/platform", format = "application/json", data = "<platform>")]
pub async fn adm_create_platform(
    platform: Unverified<Platform>,
    auth: AuthAdmin,
    conn: Db,
) -> JsonResult<Platform> {
    let platform = platform.verify_adm(&auth).map_err(|status| JsonError {
        status,
        message: None,
    })?;
    conn.run(|c| Platform::create(platform, c))
        .await
        .into_json()
}

#[post("/ap/platform", format = "application/json", data = "<platform>")]
pub async fn ap_create_platform(
    platform: Unverified<Platform>,
    config: &State<Config>,
    conn: Db,
) -> JsonResult<Platform> {
    if !config.ap_self_registration {
        return Err(JsonError {
            status: Status::Forbidden,
            message: None,
        });
    }
    let platform = platform.verify_unchecked().map_err(|status| JsonError {
        status,
        message: None,
    })?;
    conn.run(|c| Platform::create(platform, c))
        .await
        .into_json()
}

#[get("/adm/platform")]
pub async fn adm_get_platforms(_auth: AuthAdmin, conn: Db) -> JsonResult<Vec<Platform>> {
    conn.run(|c| Platform::get_all(c)).await.into_json()
}

#[get("/ap/platform")]
pub async fn ap_get_platforms(config: &State<Config>, conn: Db) -> JsonResult<Vec<Platform>> {
    if !config.ap_self_registration {
        return Err(JsonError {
            status: Status::Forbidden,
            message: None,
        });
    }
    conn.run(|c| Platform::get_all(c)).await.into_json()
}

#[get("/platform")]
pub async fn get_platforms(_auth: AuthUser, conn: Db) -> JsonResult<Vec<Platform>> {
    conn.run(|c| Platform::get_all(c)).await.into_json()
}

#[put("/adm/platform", format = "application/json", data = "<platform>")]
pub async fn adm_update_platform(
    platform: Unverified<Platform>,
    auth: AuthAdmin,
    conn: Db,
) -> JsonResult<Platform> {
    let platform = platform.verify_adm(&auth).map_err(|status| JsonError {
        status,
        message: None,
    })?;
    conn.run(|c| Platform::update(platform, c))
        .await
        .into_json()
}

#[post(
    "/platform_credential",
    format = "application/json",
    data = "<platform_credential>"
)]
pub async fn create_platform_credential(
    platform_credential: Unverified<PlatformCredential>,
    auth: AuthUser,
    conn: Db,
) -> JsonResult<PlatformCredential> {
    let platform_credential =
        platform_credential
            .verify_user_without_db(&auth)
            .map_err(|status| JsonError {
                status,
                message: None,
            })?;
    conn.run(|c| PlatformCredential::create(platform_credential, c))
        .await
        .into_json()
}

#[post(
    "/platform_credentials",
    format = "application/json",
    data = "<platform_credentials>"
)]
pub async fn create_platform_credentials(
    platform_credentials: Unverified<Vec<PlatformCredential>>,
    auth: AuthUser,
    conn: Db,
) -> JsonResult<Vec<PlatformCredential>> {
    let platform_credentials =
        platform_credentials
            .verify_user_without_db(&auth)
            .map_err(|status| JsonError {
                status,
                message: None,
            })?;
    conn.run(|c| PlatformCredential::create_multiple(platform_credentials, c))
        .await
        .into_json()
}

#[get("/platform_credential")]
pub async fn get_platform_credentials(
    auth: AuthUser,
    conn: Db,
) -> JsonResult<Vec<PlatformCredential>> {
    conn.run(move |c| PlatformCredential::get_by_user(*auth, c))
        .await
        .into_json()
}

#[get("/platform_credential/platform/<platform_id>")]
pub async fn get_platform_credentials_by_platform(
    platform_id: UnverifiedId<PlatformId>,
    auth: AuthUser,
    conn: Db,
) -> JsonResult<PlatformCredential> {
    let platform_id = platform_id.verify_unchecked().map_err(|status| JsonError {
        status,
        message: None,
    })?;
    conn.run(move |c| PlatformCredential::get_by_user_and_platform(*auth, platform_id, c))
        .await
        .into_json()
}

#[put(
    "/platform_credential",
    format = "application/json",
    data = "<platform_credential>"
)]
pub async fn update_platform_credential(
    platform_credential: Unverified<PlatformCredential>,
    auth: AuthUser,
    conn: Db,
) -> JsonResult<PlatformCredential> {
    let platform_credential = conn
        .run(move |c| platform_credential.verify_user(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| PlatformCredential::update(platform_credential, c))
        .await
        .into_json()
}

#[put(
    "/platform_credentials",
    format = "application/json",
    data = "<platform_credentials>"
)]
pub async fn update_platform_credentials(
    platform_credentials: Unverified<Vec<PlatformCredential>>,
    auth: AuthUser,
    conn: Db,
) -> JsonResult<Vec<PlatformCredential>> {
    let platform_credentials = conn
        .run(move |c| platform_credentials.verify_user(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| PlatformCredential::update_multiple(platform_credentials, c))
        .await
        .into_json()
}
