use std::fs;

use lazy_static::lazy_static;
use serde::Deserialize;

#[cfg_attr(feature = "full", derive(Deserialize))]
pub struct Config {
    pub admin_username: String,
    pub admin_password: String,
}

impl Config {
    pub fn get() -> Self {
        toml::from_str(&fs::read_to_string("config.toml").unwrap()).unwrap()
    }
}

lazy_static! {
    pub static ref CONFIG: Config = Config::get();
}
