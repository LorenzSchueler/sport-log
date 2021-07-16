use sport_log_server_derive::{
    InnerIntFromParam, VerifyIdForAdmin, VerifyIdForUser, VerifyIdForUserUnchecked,
};

#[derive(InnerIntFromParam, VerifyIdForAdmin, VerifyIdForUserUnchecked)]
pub struct UnverifiedPlatformId(i32);

#[derive(InnerIntFromParam, VerifyIdForUser)]
pub struct UnverifiedPlatformCredentialsId(i32);
