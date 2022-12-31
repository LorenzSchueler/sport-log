use argon2::{
    password_hash::{PasswordHash, PasswordVerifier},
    Argon2,
};
use diesel::{result::Error, QueryResult};

use crate::{Admin, ADMIN_USERNAME};

impl Admin {
    pub fn auth(username: &str, password: &str, admin_password: &str) -> QueryResult<()> {
        let password_hash =
            PasswordHash::new(admin_password).map_err(|_| Error::RollbackTransaction)?; // this should not happen but prevents panic
        if username == ADMIN_USERNAME
            && Argon2::default()
                .verify_password(password.as_bytes(), &password_hash)
                .is_ok()
        {
            Ok(())
        } else {
            Err(Error::NotFound)
        }
    }
}
