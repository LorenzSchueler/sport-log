use std::{fs, process};

use lazy_static::lazy_static;
use serde::{Deserialize, Serialize};
use tracing::error;

/// Server configuration.
///
/// `admin_password` is the password for the admin endpoints.
///
/// `user_self_registration` determines if users can register themself or if only the admin can create new users.
///
/// `ap_self_registration` determines if action providers can register themself or if only the admin can create new action provider.
#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct Config {
    pub admin_password: String,
    pub user_self_registration: bool,
    pub ap_self_registration: bool,
}

const CONFIG_FILE: &str = "config.toml";

lazy_static! {
    pub static ref CONFIG: Config = match fs::read_to_string(CONFIG_FILE) {
        Ok(file) => match toml::from_str(&file) {
            Ok(config) => config,
            Err(error) => {
                error!("Failed to parse config.toml: {}", error);
                process::exit(1);
            }
        },
        Err(error) => {
            error!("Failed to read config.toml: {}", error);
            process::exit(1);
        }
    };
}
