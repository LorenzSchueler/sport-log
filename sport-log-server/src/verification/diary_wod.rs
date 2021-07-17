use sport_log_server_derive::{
    InnerIntFromParam, VerifyIdForActionProvider, VerifyIdForAdmin, VerifyIdForUser,
    VerifyIdForUserUnchecked,
};

#[derive(InnerIntFromParam, VerifyIdForUser)]
pub struct UnverifiedWodId(i32);
