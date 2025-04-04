use argon2::{
    PasswordVerifier,
    password_hash::{PasswordHash, PasswordHasher, SaltString},
};
use axum::http::StatusCode;
use derive_deftly::Deftly;
use diesel::{prelude::*, result::Error};
use diesel_async::{AsyncPgConnection, RunQueryDsl};
use rand::rngs::ThreadRng;
use sport_log_derive::*;
use sport_log_types::{Epoch, User, UserId, schema::user};

use crate::{auth::AuthUser, db::*};

#[derive(Db, ModifiableDb, Deftly)]
#[derive_deftly(GetById, VerifyUncheckedCreate, VerifyForAdmin)]
pub struct UserDb;

/// Same as trait [`Create`] but with mutable references
impl UserDb {
    pub async fn create(
        user: &mut <Self as Db>::Type,
        db: &mut AsyncPgConnection,
    ) -> QueryResult<usize> {
        let salt = SaltString::from_rng(&mut ThreadRng::default());
        user.password = build_hasher()
            .hash_password(user.password.as_bytes(), &salt)
            .map_err(|_| Error::RollbackTransaction)? // this should not happen but prevents panic
            .to_string();

        diesel::insert_into(user::table)
            .values(&*user)
            .execute(db)
            .await
    }

    pub async fn create_multiple(
        users: &mut [<Self as Db>::Type],
        db: &mut AsyncPgConnection,
    ) -> QueryResult<usize> {
        for user in &mut *users {
            let salt = SaltString::from_rng(&mut ThreadRng::default());
            user.password = build_hasher()
                .hash_password(user.password.as_bytes(), &salt)
                .map_err(|_| Error::RollbackTransaction)? // this should not happen but prevents panic
                .to_string();
        }

        diesel::insert_into(user::table)
            .values(&*users)
            .execute(db)
            .await
    }
}

/// Same as trait [`Update`] but with mutable references
#[allow(clippy::multiple_inherent_impl)]
impl UserDb {
    pub async fn update(
        user: &mut <Self as Db>::Type,
        db: &mut AsyncPgConnection,
    ) -> QueryResult<usize> {
        let salt = SaltString::from_rng(&mut ThreadRng::default());
        user.password = build_hasher()
            .hash_password(user.password.as_bytes(), &salt)
            .map_err(|_| Error::RollbackTransaction)? // this should not happen but prevents panic
            .to_string();

        diesel::update(user::table.find(user.id))
            .set(&*user)
            .execute(db)
            .await
    }
}

#[async_trait]
impl CheckUserId for UserDb {
    async fn check_user_id(
        id: Self::Id,
        user_id: UserId,
        db: &mut AsyncPgConnection,
    ) -> QueryResult<bool> {
        user::table
            .filter(user::columns::id.eq(id))
            .select(user::columns::id.eq(user_id))
            .get_result(db)
            .await
            .optional()
            .map(|eq| eq.unwrap_or(false))
    }

    async fn check_user_ids(
        _ids: &[Self::Id],
        _user_id: UserId,
        _db: &mut AsyncPgConnection,
    ) -> QueryResult<bool> {
        Ok(false) // it is not allowed to request data for multiple users
    }
}

#[async_trait::async_trait]
impl crate::db::GetEpochByUser for UserDb {
    async fn get_epoch_by_user(
        user_id: sport_log_types::UserId,
        db: &mut diesel_async::AsyncPgConnection,
    ) -> diesel::result::QueryResult<Epoch> {
        use diesel::prelude::*;
        use diesel_async::RunQueryDsl;

        use crate::db::{Db, ModifiableDb};

        Self::table()
            .filter(Self::id_column().eq(user_id))
            .select(diesel::dsl::max(Self::epoch_column()))
            .get_result(db)
            .await
            .map(|epoch: Option<Epoch>| epoch.unwrap_or(Epoch(0)))
    }
}

#[allow(clippy::multiple_inherent_impl)]
impl UserDb {
    pub async fn auth(
        username: &str,
        password: &str,
        db: &mut AsyncPgConnection,
    ) -> QueryResult<UserId> {
        let (user_id, password_hash): (UserId, String) = user::table
            .filter(user::columns::username.eq(username))
            .select((user::columns::id, user::columns::password))
            .get_result(db)
            .await?;

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

    pub async fn get_by_id_and_epoch(
        user_id: UserId,
        epoch: Epoch,
        db: &mut AsyncPgConnection,
    ) -> QueryResult<Option<User>> {
        user::table
            .filter(user::columns::id.eq(user_id))
            .filter(user::columns::epoch.gt(epoch))
            .select(User::as_select())
            .get_result(db)
            .await
            .optional()
    }

    pub async fn delete(user_id: UserId, db: &mut AsyncPgConnection) -> QueryResult<usize> {
        diesel::delete(user::table.find(user_id)).execute(db).await
    }
}

#[async_trait]
impl VerifyForUserUpdate for Unverified<User> {
    type Type = User;

    async fn verify_user_update(
        self,
        auth: AuthUser,
        db: &mut AsyncPgConnection,
    ) -> Result<Self::Type, StatusCode> {
        let user = self.0;
        if user.id == *auth
            && UserDb::check_user_id(user.id, *auth, db)
                .await
                .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            Ok(user)
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}
