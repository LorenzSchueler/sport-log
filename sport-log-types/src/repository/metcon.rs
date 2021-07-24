use diesel::{prelude::*, PgConnection, QueryResult};

use crate::{
    schema::metcon_movement,
    types::{MetconId, MetconMovement},
};

impl MetconMovement {
    pub fn get_by_metcon(metcon_id: MetconId, conn: &PgConnection) -> QueryResult<Vec<Self>> {
        metcon_movement::table
            .filter(metcon_movement::columns::metcon_id.eq(metcon_id))
            .get_results(conn)
    }
}
