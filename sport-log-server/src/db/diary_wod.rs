use sport_log_types_derive::*;

#[derive(
    Db,
    VerifyIdForUserOrAP,
    Create,
    GetById,
    GetByIds,
    GetByUser,
    GetByUserSync,
    Update,
    HardDelete,
    CheckUserId,
    VerifyForUserOrAPWithDb,
    VerifyForUserOrAPWithoutDb,
)]
pub struct DiaryDb;

#[derive(
    Db,
    VerifyIdForUserOrAP,
    Create,
    GetById,
    GetByIds,
    GetByUser,
    GetByUserSync,
    Update,
    HardDelete,
    CheckUserId,
    VerifyForUserOrAPWithDb,
    VerifyForUserOrAPWithoutDb,
)]
pub struct WodDb;
