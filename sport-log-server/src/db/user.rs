use argon2::{
    password_hash::{PasswordHash, PasswordHasher, SaltString},
    PasswordVerifier,
};
use axum::http::StatusCode;
use chrono::{DateTime, Utc};
use diesel::{prelude::*, result::Error};
use rand_core::OsRng;
use sport_log_derive::*;
use sport_log_types::{schema::user, User, UserId};

use crate::{auth::AuthUser, db::*};

#[derive(Db, GetById, GetByIds, VerifyUnchecked, VerifyForAdminWithoutDb)]
pub struct UserDb;

/// Same as trait [`Create`] but with mutable references
impl UserDb {
    pub fn create(user: &mut <Self as Db>::Type, db: &mut PgConnection) -> QueryResult<usize> {
        let salt = SaltString::generate(&mut OsRng);
        user.password = build_hasher()
            .hash_password(user.password.as_bytes(), &salt)
            .map_err(|_| Error::RollbackTransaction)? // this should not happen but prevents panic
            .to_string();

        diesel::insert_into(user::table).values(&*user).execute(db)
    }

    pub fn create_multiple(
        users: &mut [<Self as Db>::Type],
        db: &mut PgConnection,
    ) -> QueryResult<usize> {
        for user in &mut *users {
            let salt = SaltString::generate(&mut OsRng);
            user.password = build_hasher()
                .hash_password(user.password.as_bytes(), &salt)
                .map_err(|_| Error::RollbackTransaction)? // this should not happen but prevents panic
                .to_string();
        }

        diesel::insert_into(user::table).values(&*users).execute(db)
    }
}

/// Same as trait [`Update`] but with mutable references
impl UserDb {
    pub fn update(user: &mut <Self as Db>::Type, db: &mut PgConnection) -> QueryResult<usize> {
        let salt = SaltString::generate(&mut OsRng);
        user.password = build_hasher()
            .hash_password(user.password.as_bytes(), &salt)
            .map_err(|_| Error::RollbackTransaction)? // this should not happen but prevents panic
            .to_string();

        diesel::update(user::table.find(user.id))
            .set(&*user)
            .execute(db)
    }
}

impl CheckUserId for UserDb {
    fn check_user_id(id: Self::Id, user_id: UserId, db: &mut PgConnection) -> QueryResult<bool> {
        user::table
            .filter(user::columns::id.eq(id))
            .select(user::columns::id.eq(user_id))
            .get_result(db)
            .optional()
            .map(|eq| eq.unwrap_or(false))
    }

    fn check_user_ids(
        _ids: &[Self::Id],
        _user_id: UserId,
        _db: &mut PgConnection,
    ) -> QueryResult<bool> {
        Ok(false) // it is not allowed to request data for multiple users
    }
}

impl UserDb {
    pub fn auth(username: &str, password: &str, db: &mut PgConnection) -> QueryResult<UserId> {
        let (user_id, password_hash): (UserId, String) = user::table
            .filter(user::columns::username.eq(username))
            .select((user::columns::id, user::columns::password))
            .get_result(db)?;

        let password_hash = PasswordHash::new(password_hash.as_str())
            .expect("invalid password hash stored in database");
        if build_hasher()
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
            .select(User::as_select())
            .get_result(db)
            .optional()
    }

    pub fn delete(user_id: UserId, db: &mut PgConnection) -> QueryResult<usize> {
        diesel::delete(user::table.find(user_id)).execute(db)
    }
}

impl VerifyForUserWithDb for Unverified<User> {
    type Type = User;

    fn verify_user(self, auth: AuthUser, db: &mut PgConnection) -> Result<Self::Type, StatusCode> {
        let user = self.0;
        if user.id == *auth
            && UserDb::check_user_id(user.id, *auth, db)
                .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(user)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}
