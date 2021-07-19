use diesel::prelude::*;

use crate::{
    schema::platform_credentials,
    types::{PlatformCredentials, PlatformId, UserId},
};

impl PlatformCredentials {
    pub fn get_by_user_and_platform(
        user_id: UserId,
        platform_id: PlatformId,
        conn: &PgConnection,
    ) -> QueryResult<PlatformCredentials> {
        platform_credentials::table
            .filter(platform_credentials::columns::user_id.eq(user_id))
            .filter(platform_credentials::columns::platform_id.eq(platform_id))
            .get_result(conn)
    }
}
