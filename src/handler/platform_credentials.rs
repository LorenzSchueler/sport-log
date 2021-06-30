use super::*;
use crate::{
    model::{
        AccountId, NewPlatform, NewPlatformCredentials, Platform, PlatformCredentials,
        PlatformCredentialsId, PlatformId,
    },
    repository::platform_credentials,
};

#[post("/platform", format = "application/json", data = "<platfrom>")]
pub fn create_platform(platfrom: Json<NewPlatform>, conn: Db) -> Result<Json<Platform>, Status> {
    to_json(platform_credentials::create_platform(
        platfrom.into_inner(),
        &conn,
    ))
}

#[get("/platform")]
pub fn get_platforms(conn: Db) -> Result<Json<Vec<Platform>>, Status> {
    to_json(platform_credentials::get_platforms(&conn))
}

#[put("/platform", format = "application/json", data = "<platform>")]
pub fn update_platform(platform: Json<Platform>, conn: Db) -> Result<Json<Platform>, Status> {
    to_json(platform_credentials::update_platform(
        platform.into_inner(),
        &conn,
    ))
}

#[delete("/platform/<platform_id>")]
pub fn delete_platform(platform_id: PlatformId, conn: Db) -> Result<Status, Status> {
    platform_credentials::delete_platform(platform_id, &conn)
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
    to_json(platform_credentials::create_platform_credentials(
        credentials.into_inner(),
        &conn,
    ))
}

#[get("/platform_creadentials/account/<account_id>")]
pub fn get_own_platform_credentials(
    account_id: AccountId,
    conn: Db,
) -> Result<Json<Vec<PlatformCredentials>>, Status> {
    to_json(platform_credentials::get_platform_credentials_by_account(
        account_id, &conn,
    ))
}

#[get("/platform_creadentials/account/<account_id>/platform/<platform_id>")]
pub fn get_own_platform_credentials_by_platform(
    account_id: AccountId,
    platform_id: PlatformId,
    conn: Db,
) -> Result<Json<PlatformCredentials>, Status> {
    to_json(
        platform_credentials::get_platform_credentials_by_account_and_platform(
            account_id,
            platform_id,
            &conn,
        ),
    )
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
    to_json(platform_credentials::update_platform_credentials(
        platform_credentials.into_inner(),
        &conn,
    ))
}

#[delete("/platform_credentials/<platform_credentials_id>")]
pub fn delete_platform_credentials(
    platform_credentials_id: PlatformCredentialsId,
    conn: Db,
) -> Result<Status, Status> {
    platform_credentials::delete_platform_credentials(platform_credentials_id, &conn)
        .map(|_| Status::NoContent)
        .map_err(|_| Status::InternalServerError)
}
