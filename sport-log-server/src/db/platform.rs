use derive_deftly::Deftly;
use sport_log_derive::*;

#[derive(Db, ModifiableDb, Deftly)]
#[derive_deftly(
    VerifyIdForAdmin,
    VerifyIdUnchecked,
    Create,
    GetAll,
    GetById,
    GetBySync,
    Update,
    HardDelete,
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
    GetByUserSync,
    Update,
    HardDelete,
    CheckUserId,
    VerifyForUserWithDb,
    VerifyForUserWithoutDb
)]
pub struct PlatformCredentialDb;
