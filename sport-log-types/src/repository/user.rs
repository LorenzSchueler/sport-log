use argon2::{
    password_hash::{PasswordHash, PasswordHasher, PasswordVerifier, SaltString},
    Argon2,
};
use chrono::{DateTime, Utc};
use diesel::{prelude::*, result::Error};
use rand_core::OsRng;

use crate::{schema::user, CheckUserId, Create, Update, User, UserId};

impl Create for User {
    fn create(mut user: Self, db: &mut PgConnection) -> QueryResult<usize> {
        let salt = SaltString::generate(&mut OsRng);
        user.password = Argon2::default()
            .hash_password(user.password.as_bytes(), &salt)
            .map_err(|_| Error::RollbackTransaction)? // this should not happen but prevents panic
            .to_string();

        diesel::insert_into(user::table).values(user).execute(db)
    }

    fn create_multiple(mut users: Vec<Self>, db: &mut PgConnection) -> QueryResult<usize> {
        for user in &mut users {
            let salt = SaltString::generate(&mut OsRng);
            user.password = Argon2::default()
                .hash_password(user.password.as_bytes(), &salt)
                .map_err(|_| Error::RollbackTransaction)? // this should not happen but prevents panic
                .to_string();
        }

        diesel::insert_into(user::table).values(users).execute(db)
    }
}

impl Update for User {
    fn update(mut user: Self, db: &mut PgConnection) -> QueryResult<usize> {
        let salt = SaltString::generate(&mut OsRng);
        user.password = Argon2::default()
            .hash_password(user.password.as_bytes(), &salt)
            .map_err(|_| Error::RollbackTransaction)? // this should not happen but prevents panic
            .to_string();

        diesel::update(user::table.find(user.id))
            .set(user)
            .execute(db)
    }

    fn update_multiple(users: Vec<Self>, db: &mut PgConnection) -> QueryResult<usize> {
        db.transaction(|db| {
            let len = users.len();

            for mut user in users {
                let salt = SaltString::generate(&mut OsRng);
                user.password = Argon2::default()
                    .hash_password(user.password.as_bytes(), &salt)
                    .map_err(|_| Error::RollbackTransaction)? // this should not happen but prevents panic
                    .to_string();

                diesel::update(user::table.find(user.id))
                    .set(user)
                    .execute(db)?;
            }

            Ok(len)
        })
    }
}

impl CheckUserId for User {
    type Id = UserId;

    fn check_user_id(id: Self::Id, user_id: UserId, db: &mut PgConnection) -> QueryResult<bool> {
        user::table
            .filter(user::columns::id.eq(id))
            .filter(user::columns::id.eq(user_id))
            .count()
            .get_result(db)
            .map(|count: i64| count == 1)
    }

    fn check_user_ids(
        _ids: &[Self::Id],
        _user_id: UserId,
        _db: &mut PgConnection,
    ) -> QueryResult<bool> {
        Ok(false) // it is not allowed to request data for multiple users
    }
}

impl User {
    pub fn auth(username: &str, password: &str, db: &mut PgConnection) -> QueryResult<UserId> {
        let (user_id, password_hash): (UserId, String) = user::table
            .filter(user::columns::username.eq(username))
            .select((user::columns::id, user::columns::password))
            .get_result(db)?;

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

    pub fn get_by_id_and_last_sync(
        user_id: UserId,
        last_sync: DateTime<Utc>,
        db: &mut PgConnection,
    ) -> QueryResult<Option<User>> {
        user::table
            .filter(user::columns::id.eq(user_id))
            .filter(user::columns::last_change.ge(last_sync))
            .get_result(db)
            .optional()
    }

    pub fn delete(user_id: UserId, db: &mut PgConnection) -> QueryResult<usize> {
        diesel::delete(user::table.find(user_id)).execute(db)
    }
}
