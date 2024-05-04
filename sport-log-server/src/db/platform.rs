use sport_log_derive::*;

#[derive(
    Db,
    ModifiableDb,
    VerifyIdForAdmin,
    VerifyIdUnchecked,
    Create,
    GetAll,
    GetById,
    GetBySync,
    Update,
    HardDelete,
    VerifyForAdminWithoutDb,
    VerifyUnchecked,
)]
pub struct PlatformDb;

#[derive(
    Db,
    ModifiableDb,
    DbWithUserId,
    VerifyIdForUser,
    Create,
    GetById,
    GetByUser,
    GetByUserSync,
    Update,
    HardDelete,
    CheckUserId,
    VerifyForUserWithDb,
    VerifyForUserWithoutDb,
)]
pub struct PlatformCredentialDb;
