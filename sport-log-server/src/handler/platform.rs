use rocket::http::Status;
use rocket_contrib::json::Json;

use crate::{
    auth::AuthenticatedUser,
    handler::to_json,
    model::{NewPlatform, NewPlatformCredentials, Platform, PlatformCredentials, PlatformId},
    verification::UnverifiedPlatformCredentialsId,
    Db,
};

// TODO authentification
#[post("/platform", format = "application/json", data = "<platfrom>")]
pub fn create_platform(platfrom: Json<NewPlatform>, conn: Db) -> Result<Json<Platform>, Status> {
    to_json(Platform::create(platfrom.into_inner(), &conn))
}

// TODO authentification
#[get("/platform")]
pub fn get_platforms(conn: Db) -> Result<Json<Vec<Platform>>, Status> {
    to_json(Platform::get_all(&conn))
}

// TODO authentification
#[put("/platform", format = "application/json", data = "<platform>")]
pub fn update_platform(platform: Json<Platform>, conn: Db) -> Result<Json<Platform>, Status> {
    to_json(Platform::update(platform.into_inner(), &conn))
}

// TODO authentification
#[delete("/platform/<platform_id>")]
pub fn delete_platform(platform_id: PlatformId, conn: Db) -> Result<Status, Status> {
    Platform::delete(platform_id, &conn)
        .map(|_| Status::NoContent)
        .map_err(|_| Status::InternalServerError)
}

#[post(
    "/platform_credentials",
    format = "application/json",
    data = "<platform_credentials>"
)]
pub fn create_platform_credentials(
    platform_credentials: Json<NewPlatformCredentials>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<PlatformCredentials>, Status> {
    to_json(PlatformCredentials::create(
        NewPlatformCredentials::verify(platform_credentials, auth)?,
        &conn,
    ))
}

#[get("/platform_creadentials")]
pub fn get_own_platform_credentials(
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Vec<PlatformCredentials>>, Status> {
    to_json(PlatformCredentials::get_by_user(*auth, &conn))
}

#[get("/platform_creadentials/platform/<platform_id>")]
pub fn get_own_platform_credentials_by_platform(
    platform_id: PlatformId,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<PlatformCredentials>, Status> {
    to_json(PlatformCredentials::get_by_user_and_platform(
        *auth,
        platform_id,
        &conn,
    ))
}

#[put(
    "/platform_credentials",
    format = "application/json",
    data = "<platform_credentials>"
)]
pub fn update_platform_credentials(
    platform_credentials: Json<PlatformCredentials>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<PlatformCredentials>, Status> {
    to_json(PlatformCredentials::update(
        PlatformCredentials::verify(platform_credentials, auth)?,
        &conn,
    ))
}

#[delete("/platform_credentials/<platform_credentials_id>")]
pub fn delete_platform_credentials(
    platform_credentials_id: UnverifiedPlatformCredentialsId,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Status, Status> {
    PlatformCredentials::delete(platform_credentials_id.verify(auth, &conn)?, &conn)
        .map(|_| Status::NoContent)
        .map_err(|_| Status::InternalServerError)
}
