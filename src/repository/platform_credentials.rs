use std::usize;

use super::*;
use crate::schema::platform_credentials::{columns, table as platform_credentials};

pub fn create_platform_credentials(
    new_credentials: NewPlatformCredentials,
    conn: &PgConnection,
) -> QueryResult<PlatformCredentials> {
    diesel::insert_into(platform_credentials)
        .values(new_credentials)
        .get_result(conn)
}

pub fn get_platform_credentials_by_account(
    account_id: AccountId,
    conn: &PgConnection,
) -> QueryResult<Vec<PlatformCredentials>> {
    platform_credentials
        .filter(columns::account_id.eq(account_id))
        .get_results(conn)
}

pub fn get_platform_credentials_by_account_and_platform(
    account_id: AccountId,
    platform_id: PlatformId,
    conn: &PgConnection,
) -> QueryResult<PlatformCredentials> {
    platform_credentials
        .filter(columns::account_id.eq(account_id))
        .filter(columns::platform_id.eq(platform_id))
        .get_result(conn)
}

pub fn update_platform_credentials(
    new_platform_credentials: PlatformCredentials,
    conn: &PgConnection,
) -> QueryResult<PlatformCredentials> {
    diesel::update(platform_credentials.find(new_platform_credentials.id))
        .set(new_platform_credentials)
        .get_result(conn)
}

pub fn delete_platform_credentials(
    platform_credentials_id: PlatformCredentialsId,
    conn: &PgConnection,
) -> QueryResult<usize> {
    diesel::delete(platform_credentials.find(platform_credentials_id)).execute(conn)
}
