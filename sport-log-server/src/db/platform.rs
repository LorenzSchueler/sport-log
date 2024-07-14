use derive_deftly::Deftly;
use sport_log_derive::*;

#[derive(Db, ModifiableDb, Deftly)]
#[derive_deftly(
    VerifyIdForAdmin,
    VerifyIdUnchecked,
    Create,
    GetAll,
    GetById,
    GetByEpoch,
    Update,
    VerifyForAdminWithoutDb,
    VerifyUnchecked
)]
pub struct PlatformDb;

#[derive(Db, ModifiableDb, DbWithUserId, Deftly)]
#[derive_deftly(
    VerifyIdForUser,
    Create,
    GetById,
    GetByUser,
    GetByUserAndEpoch,
    Update,
    CheckUserId,
    VerifyForUserWithDb,
    VerifyForUserWithoutDb
)]
pub struct PlatformCredentialDb;
