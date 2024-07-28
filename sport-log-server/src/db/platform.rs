use derive_deftly::Deftly;
use sport_log_derive::*;

#[derive(Db, ModifiableDb, Deftly)]
#[derive_deftly(
    VerifyForAdminGet,
    VerifyUncheckedGet,
    Create,
    GetAll,
    GetById,
    GetByEpoch,
    Update,
    VerifyForAdmin,
    VerifyUncheckedCreate
)]
pub struct PlatformDb;

#[derive(Db, ModifiableDb, DbWithUserId, Deftly)]
#[derive_deftly(
    VerifyForUserGet,
    Create,
    GetById,
    GetByUser,
    GetByUserAndEpoch,
    Update,
    CheckUserId,
    VerifyForUserUpdate,
    VerifyForUserCreate
)]
pub struct PlatformCredentialDb;
