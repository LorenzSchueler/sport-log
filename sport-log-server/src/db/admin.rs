use argon2::{PasswordVerifier, password_hash::PasswordHash};
use diesel::{QueryResult, result::Error};
use sport_log_types::ADMIN_USERNAME;

use crate::db::build_hasher;

pub struct AdminDb;

impl AdminDb {
    pub fn auth(username: &str, password: &str, admin_password: &str) -> QueryResult<()> {
        let password_hash =
            PasswordHash::new(admin_password).map_err(|_| Error::RollbackTransaction)?; // this should not happen but prevents panic
        if username == ADMIN_USERNAME
            && build_hasher()
                .verify_password(password.as_bytes(), &password_hash)
                .is_ok()
        {
            Ok(())
        } else {
            Err(Error::NotFound)
        }
    }
}
