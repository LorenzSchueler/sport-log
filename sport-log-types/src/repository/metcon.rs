use diesel::{prelude::*, PgConnection, QueryResult};

use crate::{
    schema::{metcon, metcon_movement},
    types::{GetByUser, MetconId, MetconMovement, UserId},
};

impl GetByUser for MetconMovement {
    fn get_by_user(user_id: UserId, conn: &PgConnection) -> QueryResult<Vec<Self>> {
        metcon_movement::table
            .filter(
                metcon_movement::columns::metcon_id.eq_any(
                    metcon::table
                        .filter(metcon::columns::user_id.eq(user_id))
                        .select(metcon::columns::id)
                        .get_results::<MetconId>(conn)?,
                ),
            )
            .get_results(conn)
    }
}

impl MetconMovement {
    pub fn get_by_metcon(metcon_id: MetconId, conn: &PgConnection) -> QueryResult<Vec<Self>> {
        metcon_movement::table
            .filter(metcon_movement::columns::metcon_id.eq(metcon_id))
            .get_results(conn)
    }
}
