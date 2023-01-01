use diesel::prelude::*;

use crate::{schema::platform_credential, PlatformCredential, PlatformId, UserId};

impl PlatformCredential {
    pub fn get_by_user_and_platform(
        user_id: UserId,
        platform_id: PlatformId,
        db: &mut PgConnection,
    ) -> QueryResult<Self> {
        platform_credential::table
            .filter(platform_credential::columns::user_id.eq(user_id))
            .filter(platform_credential::columns::platform_id.eq(platform_id))
            .select(PlatformCredential::as_select())
            .get_result(db)
    }
}
