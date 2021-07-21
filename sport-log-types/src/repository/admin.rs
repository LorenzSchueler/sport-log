use argon2::{
    password_hash::{PasswordHash, PasswordVerifier},
    Argon2,
};
use diesel::{result::Error, PgConnection, QueryResult};

use crate::types::{Admin, CONFIG};

impl Admin {
    pub fn authenticate(username: &str, password: &str, _conn: &PgConnection) -> QueryResult<()> {
        let password_hash = PasswordHash::new(CONFIG.admin_password.as_str()).unwrap();
        if username == CONFIG.admin_username
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
