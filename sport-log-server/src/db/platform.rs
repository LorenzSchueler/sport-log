use sport_log_types_derive::*;

#[derive(
    Db,
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
    VerifyIdForUser,
    Create,
    GetById,
    GetByIds,
    GetByUser,
    GetByUserSync,
    Update,
    HardDelete,
    CheckUserId,
    VerifyForUserWithDb,
    VerifyForUserWithoutDb,
)]
pub struct PlatformCredentialDb;
