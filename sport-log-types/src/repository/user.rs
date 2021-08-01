use argon2::{
    password_hash::{PasswordHash, PasswordHasher, PasswordVerifier, SaltString},
    Argon2,
};
use diesel::{prelude::*, result::Error};
use rand_core::OsRng;

use crate::{schema::user, Create, NewUser, Update, User, UserId};

impl Create for User {
    type New = NewUser;

    fn create(mut user: Self::New, conn: &PgConnection) -> QueryResult<Self> {
        let salt = SaltString::generate(&mut OsRng);
        user.password = Argon2::default()
            .hash_password_simple(user.password.as_bytes(), &salt)
            .unwrap()
            .to_string();

        diesel::insert_into(user::table)
            .values(user)
            .get_result(conn)
    }
}

impl Update for User {
    fn update(mut user: Self, conn: &PgConnection) -> QueryResult<Self> {
        let salt = SaltString::generate(&mut OsRng);
        user.password = Argon2::default()
            .hash_password_simple(user.password.as_bytes(), &salt)
            .unwrap()
            .to_string();

        diesel::update(user::table.find(user.id))
            .set(user)
            .get_result(conn)
    }
}

impl User {
    pub fn auth(username: &str, password: &str, conn: &PgConnection) -> QueryResult<UserId> {
        let (user_id, password_hash): (UserId, String) = user::table
            .filter(user::columns::username.eq(username))
            .select((user::columns::id, user::columns::password))
            .get_result(conn)?;

        let password_hash = PasswordHash::new(password_hash.as_str())
            .expect("invalid password hash stored in database");
        if Argon2::default()
            .verify_password(password.as_bytes(), &password_hash)
            .is_ok()
        {
            Ok(user_id)
        } else {
            Err(Error::NotFound)
        }
    }
}
