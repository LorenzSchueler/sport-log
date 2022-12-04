use serde::{Deserialize, Serialize};

/// Server configuration.
///
/// `admin_password` is the password for the admin endpoints.
///
/// `user_self_registration` determines if users can register themselves or if only the admin can create new users.
///
/// `ap_self_registration` determines if action providers can register themselves or if only the admin can create new action provider.
#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct Config {
    pub admin_password: String,
    pub user_self_registration: bool,
    pub ap_self_registration: bool,
}
