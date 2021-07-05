use diesel::prelude::*;

use crate::{
    model::{AccountId, PlatformCredentials, PlatformId},
    schema::platform_credentials,
};

//impl Platform {
//}

impl PlatformCredentials {
    pub fn get_by_account(
        account_id: AccountId,
        conn: &PgConnection,
    ) -> QueryResult<Vec<PlatformCredentials>> {
        platform_credentials::table
            .filter(platform_credentials::columns::account_id.eq(account_id))
            .get_results(conn)
    }

    pub fn get_by_account_and_platform(
        account_id: AccountId,
        platform_id: PlatformId,
        conn: &PgConnection,
    ) -> QueryResult<PlatformCredentials> {
        platform_credentials::table
            .filter(platform_credentials::columns::account_id.eq(account_id))
            .filter(platform_credentials::columns::platform_id.eq(platform_id))
            .get_result(conn)
    }
}
