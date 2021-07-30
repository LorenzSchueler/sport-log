use rocket::{http::Status, serde::json::Json};

use sport_log_types::{
    AuthenticatedAdmin, AuthenticatedUser, Create, CreateMultiple, Db, Delete, DeleteMultiple,
    GetAll, GetByUser, NewPlatform, NewPlatformCredentials, Platform, PlatformCredentials,
    PlatformCredentialsId, PlatformId, Unverified, UnverifiedId, UnverifiedIds, Update,
    VerifyForAdminWithoutDb, VerifyForUserWithDb, VerifyForUserWithoutDb, VerifyIdForAdmin,
    VerifyIdForUser, VerifyIdForUserUnchecked, VerifyMultipleForUserWithoutDb,
    VerifyMultipleIdForUser,
};

use crate::handler::IntoJson;

#[post("/adm/platform", format = "application/json", data = "<platform>")]
pub async fn adm_create_platform(
    platform: Unverified<NewPlatform>,
    auth: AuthenticatedAdmin,
    conn: Db,
) -> Result<Json<Platform>, Status> {
    let platform = platform.verify_adm(&auth)?;
    conn.run(|c| Platform::create(platform, c))
        .await
        .into_json()
}

#[get("/adm/platform")]
pub async fn adm_get_platforms(
    _auth: AuthenticatedAdmin,
    conn: Db,
) -> Result<Json<Vec<Platform>>, Status> {
    conn.run(|c| Platform::get_all(c)).await.into_json()
}

#[get("/platform")]
pub async fn get_platforms(
    _auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Vec<Platform>>, Status> {
    conn.run(|c| Platform::get_all(c)).await.into_json()
}

#[put("/adm/platform", format = "application/json", data = "<platform>")]
pub async fn adm_update_platform(
    platform: Unverified<Platform>,
    auth: AuthenticatedAdmin,
    conn: Db,
) -> Result<Json<Platform>, Status> {
    let platform = platform.verify_adm(&auth)?;
    conn.run(|c| Platform::update(platform, c))
        .await
        .into_json()
}

#[delete("/adm/platform/<platform_id>")]
pub async fn adm_delete_platform(
    platform_id: UnverifiedId<PlatformId>,
    auth: AuthenticatedAdmin,
    conn: Db,
) -> Result<Status, Status> {
    let platform_id = platform_id.verify_adm(&auth)?;
    conn.run(move |c| {
        Platform::delete(platform_id, c)
            .map(|_| Status::NoContent)
            .map_err(|_| Status::InternalServerError)
    })
    .await
}

#[post(
    "/platform_credentials",
    format = "application/json",
    data = "<platform_credentials>"
)]
pub async fn create_platform_credentials(
    platform_credentials: Unverified<NewPlatformCredentials>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<PlatformCredentials>, Status> {
    let platform_credentials = platform_credentials.verify(&auth)?;
    conn.run(|c| PlatformCredentials::create(platform_credentials, c))
        .await
        .into_json()
}

#[post(
    "/platform_credentialss",
    format = "application/json",
    data = "<platform_credentialss>"
)]
pub async fn create_platform_credentialss(
    // TODO change name to credential
    platform_credentialss: Unverified<Vec<NewPlatformCredentials>>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Vec<PlatformCredentials>>, Status> {
    let platform_credentialss = platform_credentialss.verify(&auth)?;
    conn.run(|c| PlatformCredentials::create_multiple(platform_credentialss, c))
        .await
        .into_json()
}

#[get("/platform_credentials")]
pub async fn get_platform_credentials(
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Vec<PlatformCredentials>>, Status> {
    conn.run(move |c| PlatformCredentials::get_by_user(*auth, c))
        .await
        .into_json()
}

#[get("/platform_credentials/platform/<platform_id>")]
pub async fn get_platform_credentials_by_platform(
    platform_id: UnverifiedId<PlatformId>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<PlatformCredentials>, Status> {
    let platform_id = platform_id.verify_unchecked(&auth)?;
    conn.run(move |c| PlatformCredentials::get_by_user_and_platform(*auth, platform_id, c))
        .await
        .into_json()
}

#[put(
    "/platform_credentials",
    format = "application/json",
    data = "<platform_credentials>"
)]
pub async fn update_platform_credentials(
    platform_credentials: Unverified<PlatformCredentials>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<PlatformCredentials>, Status> {
    let platform_credentials = conn
        .run(move |c| platform_credentials.verify(&auth, c))
        .await?;
    conn.run(|c| PlatformCredentials::update(platform_credentials, c))
        .await
        .into_json()
}

#[delete("/platform_credentials/<platform_credentials_id>")]
pub async fn delete_platform_credentials(
    platform_credentials_id: UnverifiedId<PlatformCredentialsId>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Status, Status> {
    conn.run(move |c| {
        PlatformCredentials::delete(platform_credentials_id.verify(&auth, c)?, c)
            .map(|_| Status::NoContent)
            .map_err(|_| Status::InternalServerError)
    })
    .await
}

#[delete(
    "/platform_credentialss",
    format = "application/json",
    data = "<platform_credentials_ids>"
)]
pub async fn delete_platform_credentialss(
    platform_credentials_ids: UnverifiedIds<PlatformCredentialsId>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Status, Status> {
    conn.run(move |c| {
        PlatformCredentials::delete_multiple(platform_credentials_ids.verify(&auth, c)?, c)
            .map(|_| Status::NoContent)
            .map_err(|_| Status::InternalServerError)
    })
    .await
}
