use rocket::{http::Status, serde::json::Json};

use sport_log_types::{
    AuthAdmin, AuthUser, Create, CreateMultiple, Db, GetAll, GetByUser, Platform,
    PlatformCredential, PlatformId, Unverified, UnverifiedId, Update, VerifyForAdminWithoutDb,
    VerifyForUserWithDb, VerifyForUserWithoutDb, VerifyIdUnchecked, VerifyMultipleForUserWithDb,
    VerifyMultipleForUserWithoutDb, VerifyUnchecked, CONFIG,
};

use crate::handler::IntoJson;

#[post("/adm/platform", format = "application/json", data = "<platform>")]
pub async fn adm_create_platform(
    platform: Unverified<Platform>,
    auth: AuthAdmin,
    conn: Db,
) -> Result<Json<Platform>, Status> {
    let platform = platform.verify_adm(&auth)?;
    conn.run(|c| Platform::create(platform, c))
        .await
        .into_json()
}

#[post("/ap/platform", format = "application/json", data = "<platform>")]
pub async fn ap_create_platform(
    platform: Unverified<Platform>,
    conn: Db,
) -> Result<Json<Platform>, Status> {
    if !CONFIG.ap_self_registration {
        return Err(Status::Forbidden);
    }
    let platform = platform.verify_unchecked()?;
    conn.run(|c| Platform::create(platform, c))
        .await
        .into_json()
}

#[get("/adm/platform")]
pub async fn adm_get_platforms(_auth: AuthAdmin, conn: Db) -> Result<Json<Vec<Platform>>, Status> {
    conn.run(|c| Platform::get_all(c)).await.into_json()
}

#[get("/ap/platform")]
pub async fn ap_get_platforms(conn: Db) -> Result<Json<Vec<Platform>>, Status> {
    if !CONFIG.ap_self_registration {
        return Err(Status::Forbidden);
    }
    conn.run(|c| Platform::get_all(c)).await.into_json()
}

#[get("/platform")]
pub async fn get_platforms(_auth: AuthUser, conn: Db) -> Result<Json<Vec<Platform>>, Status> {
    conn.run(|c| Platform::get_all(c)).await.into_json()
}

#[put("/adm/platform", format = "application/json", data = "<platform>")]
pub async fn adm_update_platform(
    platform: Unverified<Platform>,
    auth: AuthAdmin,
    conn: Db,
) -> Result<Json<Platform>, Status> {
    let platform = platform.verify_adm(&auth)?;
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
) -> Result<Json<PlatformCredential>, Status> {
    let platform_credential = platform_credential.verify_user_without_db(&auth)?;
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
) -> Result<Json<Vec<PlatformCredential>>, Status> {
    let platform_credentials = platform_credentials.verify_user_without_db(&auth)?;
    conn.run(|c| PlatformCredential::create_multiple(platform_credentials, c))
        .await
        .into_json()
}

#[get("/platform_credential")]
pub async fn get_platform_credentials(
    auth: AuthUser,
    conn: Db,
) -> Result<Json<Vec<PlatformCredential>>, Status> {
    conn.run(move |c| PlatformCredential::get_by_user(*auth, c))
        .await
        .into_json()
}

#[get("/platform_credential/platform/<platform_id>")]
pub async fn get_platform_credentials_by_platform(
    platform_id: UnverifiedId<PlatformId>,
    auth: AuthUser,
    conn: Db,
) -> Result<Json<PlatformCredential>, Status> {
    let platform_id = platform_id.verify_unchecked()?;
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
) -> Result<Json<PlatformCredential>, Status> {
    let platform_credential = conn
        .run(move |c| platform_credential.verify_user(&auth, c))
        .await?;
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
) -> Result<Json<Vec<PlatformCredential>>, Status> {
    let platform_credentials = conn
        .run(move |c| platform_credentials.verify_user(&auth, c))
        .await?;
    conn.run(|c| PlatformCredential::update_multiple(platform_credentials, c))
        .await
        .into_json()
}
