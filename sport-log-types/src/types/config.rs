use std::fs;

use lazy_static::lazy_static;
use serde::{Deserialize, Serialize};

/// Server configuration.
///
/// `admin_username` and `admin_password` are the credentials for the admin endpoints.
///
/// `self_registration` determines if users can register themself or if only the admin can create new users.
#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct Config {
    pub admin_password: String,
    pub self_registration: bool,
}

impl Config {
    pub fn get() -> Self {
        toml::from_str(&fs::read_to_string("config.toml").expect("config.toml not found"))
            .expect("config.toml is not valid TOML")
    }
}

lazy_static! {
    pub static ref CONFIG: Config = Config::get();
}
