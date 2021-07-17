use sport_log_server_derive::{InnerIntFromParam, VerifyIdForUser};

#[derive(InnerIntFromParam, VerifyIdForUser)]
pub struct UnverifiedWodId(i32);
