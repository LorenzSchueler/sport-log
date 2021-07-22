use std::fs;

use lazy_static::lazy_static;
use serde::Deserialize;

#[derive(Deserialize)]
pub struct Config {
    pub admin_username: String,
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
