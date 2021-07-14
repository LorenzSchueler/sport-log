use rocket::{http::Status, serde::json::Json};

use crate::{
    auth::{AuthenticatedAdmin, AuthenticatedUser},
    handler::IntoJson,
    model::{NewPlatform, NewPlatformCredentials, Platform, PlatformCredentials, PlatformId},
    verification::UnverifiedPlatformCredentialsId,
    Db,
};

#[post("/adm/platform", format = "application/json", data = "<platfrom>")]
pub async fn create_platform(
    platfrom: Json<NewPlatform>,
    _auth: AuthenticatedAdmin,
    conn: Db,
) -> Result<Json<Platform>, Status> {
    conn.run(|c| Platform::create(platfrom.into_inner(), c))
        .await
        .into_json()
}

#[get("/adm/platform")]
pub async fn get_platforms(
    _auth: AuthenticatedAdmin,
    conn: Db,
) -> Result<Json<Vec<Platform>>, Status> {
    conn.run(|c| Platform::get_all(c)).await.into_json()
}

#[get("/platform")]
pub async fn get_platforms_u(
    _auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Vec<Platform>>, Status> {
    conn.run(|c| Platform::get_all(c)).await.into_json()
}

#[put("/adm/platform", format = "application/json", data = "<platform>")]
pub async fn update_platform(
    platform: Json<Platform>,
    _auth: AuthenticatedAdmin,
    conn: Db,
) -> Result<Json<Platform>, Status> {
    conn.run(|c| Platform::update(platform.into_inner(), c))
        .await
        .into_json()
}

#[delete("/adm/platform/<platform_id>")]
pub async fn delete_platform(
    platform_id: PlatformId,
    _auth: AuthenticatedAdmin,
    conn: Db,
) -> Result<Status, Status> {
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
    platform_credentials: Json<NewPlatformCredentials>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<PlatformCredentials>, Status> {
    let platform_credentials = NewPlatformCredentials::verify(platform_credentials, auth)?;
    conn.run(|c| PlatformCredentials::create(platform_credentials, c))
        .await
        .into_json()
}

#[get("/platform_credentials")]
pub async fn get_own_platform_credentials(
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Vec<PlatformCredentials>>, Status> {
    conn.run(move |c| PlatformCredentials::get_by_user(*auth, c))
        .await
        .into_json()
}

#[get("/platform_credentials/platform/<platform_id>")]
pub async fn get_own_platform_credentials_by_platform(
    platform_id: PlatformId,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<PlatformCredentials>, Status> {
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
    platform_credentials: Json<PlatformCredentials>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<PlatformCredentials>, Status> {
    let platform_credentials = PlatformCredentials::verify(platform_credentials, auth)?;
    conn.run(|c| PlatformCredentials::update(platform_credentials, c))
        .await
        .into_json()
}

#[delete("/platform_credentials/<platform_credentials_id>")]
pub async fn delete_platform_credentials(
    platform_credentials_id: UnverifiedPlatformCredentialsId,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Status, Status> {
    conn.run(|c| {
        PlatformCredentials::delete(platform_credentials_id.verify(auth, c)?, c)
            .map(|_| Status::NoContent)
            .map_err(|_| Status::InternalServerError)
    })
    .await
}
