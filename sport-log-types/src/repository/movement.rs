use diesel::prelude::*;

use crate::{
    schema::movement,
    types::{GetByUser, Movement, UserId},
};

impl GetByUser for Movement {
    fn get_by_user(user_id: UserId, conn: &PgConnection) -> QueryResult<Vec<Self>> {
        movement::table
            .filter(
                movement::columns::user_id
                    .eq(user_id)
                    .or(movement::columns::user_id.eq(Option::<UserId>::None)),
            )
            .get_results(conn)
    }
}
