use super::*;
use crate::model::{
    NewPlatform, NewPlatformCredentials, Platform, PlatformCredentials, PlatformCredentialsId,
    PlatformId, UserId,
};

#[post("/platform", format = "application/json", data = "<platfrom>")]
pub fn create_platform(platfrom: Json<NewPlatform>, conn: Db) -> Result<Json<Platform>, Status> {
    to_json(Platform::create(platfrom.into_inner(), &conn))
}

#[get("/platform")]
pub fn get_platforms(conn: Db) -> Result<Json<Vec<Platform>>, Status> {
    to_json(Platform::get_all(&conn))
}

#[put("/platform", format = "application/json", data = "<platform>")]
pub fn update_platform(platform: Json<Platform>, conn: Db) -> Result<Json<Platform>, Status> {
    to_json(Platform::update(platform.into_inner(), &conn))
}

#[delete("/platform/<platform_id>")]
pub fn delete_platform(platform_id: PlatformId, conn: Db) -> Result<Status, Status> {
    Platform::delete(platform_id, &conn)
        .map(|_| Status::NoContent)
        .map_err(|_| Status::InternalServerError)
}

#[post(
    "/platform_credentials",
    format = "application/json",
    data = "<credentials>"
)]
pub fn create_platform_credentials(
    credentials: Json<NewPlatformCredentials>,
    conn: Db,
) -> Result<Json<PlatformCredentials>, Status> {
    to_json(PlatformCredentials::create(credentials.into_inner(), &conn))
}

#[get("/platform_creadentials/user/<user_id>")]
pub fn get_own_platform_credentials(
    user_id: UserId,
    conn: Db,
) -> Result<Json<Vec<PlatformCredentials>>, Status> {
    to_json(PlatformCredentials::get_by_user(user_id, &conn))
}

#[get("/platform_creadentials/user/<user_id>/platform/<platform_id>")]
pub fn get_own_platform_credentials_by_platform(
    user_id: UserId,
    platform_id: PlatformId,
    conn: Db,
) -> Result<Json<PlatformCredentials>, Status> {
    to_json(PlatformCredentials::get_by_user_and_platform(
        user_id,
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
    conn: Db,
) -> Result<Json<PlatformCredentials>, Status> {
    to_json(PlatformCredentials::update(
        platform_credentials.into_inner(),
        &conn,
    ))
}

#[delete("/platform_credentials/<platform_credentials_id>")]
pub fn delete_platform_credentials(
    platform_credentials_id: PlatformCredentialsId,
    conn: Db,
) -> Result<Status, Status> {
    PlatformCredentials::delete(platform_credentials_id, &conn)
        .map(|_| Status::NoContent)
        .map_err(|_| Status::InternalServerError)
}
