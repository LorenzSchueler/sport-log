use diesel::prelude::*;

use crate::{
    model::{User, UserId},
    schema::user,
};

impl User {
    pub fn authenticate(
        username: &str,
        password: &str,
        conn: &PgConnection,
    ) -> QueryResult<UserId> {
        user::table
            .filter(user::columns::username.eq(username))
            .filter(user::columns::password.eq(password)) // TODO use hash function
            .select(user::columns::id)
            .get_result(conn)
    }
}
