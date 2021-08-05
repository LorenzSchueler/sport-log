use rocket::{http::Status, serde::json::Json};

use sport_log_types::{
    AuthAdmin, AuthUser, Create, CreateMultiple, Db, Delete, DeleteMultiple, GetAll, GetByUser,
    NewPlatform, NewPlatformCredential, Platform, PlatformCredential, PlatformCredentialId,
    PlatformId, Unverified, UnverifiedId, UnverifiedIds, Update, VerifyForAdminWithoutDb,
    VerifyForUserWithDb, VerifyForUserWithoutDb, VerifyIdForAdmin, VerifyIdForUser,
    VerifyIdForUserUnchecked, VerifyMultipleForUserWithoutDb, VerifyMultipleIdForUser,
};

use crate::handler::IntoJson;

#[post("/adm/platform", format = "application/json", data = "<platform>")]
pub async fn adm_create_platform(
    platform: Unverified<NewPlatform>,
    auth: AuthAdmin,
    conn: Db,
) -> Result<Json<Platform>, Status> {
    let platform = platform.verify_adm(&auth)?;
    conn.run(|c| Platform::create(platform, c))
        .await
        .into_json()
}

#[get("/adm/platform")]
pub async fn adm_get_platforms(_auth: AuthAdmin, conn: Db) -> Result<Json<Vec<Platform>>, Status> {
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

#[delete("/adm/platform/<platform_id>")]
pub async fn adm_delete_platform(
    platform_id: UnverifiedId<PlatformId>,
    auth: AuthAdmin,
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
    "/platform_credential",
    format = "application/json",
    data = "<platform_credential>"
)]
pub async fn create_platform_credential(
    platform_credential: Unverified<NewPlatformCredential>,
    auth: AuthUser,
    conn: Db,
) -> Result<Json<PlatformCredential>, Status> {
    let platform_credential = platform_credential.verify(&auth)?;
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
    // TODO change name to credential
    platform_credentials: Unverified<Vec<NewPlatformCredential>>,
    auth: AuthUser,
    conn: Db,
) -> Result<Json<Vec<PlatformCredential>>, Status> {
    let platform_credentials = platform_credentials.verify(&auth)?;
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
    let platform_id = platform_id.verify_unchecked(&auth)?;
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
        .run(move |c| platform_credential.verify(&auth, c))
        .await?;
    conn.run(|c| PlatformCredential::update(platform_credential, c))
        .await
        .into_json()
}

#[delete("/platform_credential/<platform_credential_id>")]
pub async fn delete_platform_credential(
    platform_credential_id: UnverifiedId<PlatformCredentialId>,
    auth: AuthUser,
    conn: Db,
) -> Result<Status, Status> {
    conn.run(move |c| {
        PlatformCredential::delete(platform_credential_id.verify(&auth, c)?, c)
            .map(|_| Status::NoContent)
            .map_err(|_| Status::InternalServerError)
    })
    .await
}

#[delete(
    "/platform_credentials",
    format = "application/json",
    data = "<platform_credential_ids>"
)]
pub async fn delete_platform_credentials(
    platform_credential_ids: UnverifiedIds<PlatformCredentialId>,
    auth: AuthUser,
    conn: Db,
) -> Result<Status, Status> {
    conn.run(move |c| {
        PlatformCredential::delete_multiple(platform_credential_ids.verify(&auth, c)?, c)
            .map(|_| Status::NoContent)
            .map_err(|_| Status::InternalServerError)
    })
    .await
}
