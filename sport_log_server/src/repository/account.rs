use diesel::prelude::*;

use crate::{
    model::{Account, AccountId},
    schema::account,
};

impl Account {
    pub fn authenticate(
        username: String,
        password: String,
        conn: &PgConnection,
    ) -> QueryResult<AccountId> {
        account::table
            .filter(account::columns::username.eq(username))
            .filter(account::columns::password.eq(password)) // TODO use hash function
            .select(account::columns::id)
            .get_result(conn)
    }
}
