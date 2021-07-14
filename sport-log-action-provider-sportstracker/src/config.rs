use std::fs;

use serde::Deserialize;

#[derive(Deserialize)]
pub struct Config {
    pub username: String,
    pub password: String,
    pub base_url: String,
}

impl Config {
    pub fn get() -> Self {
        toml::from_str(&fs::read_to_string("config.toml").unwrap()).unwrap()
    }
}
