use derive_deftly::Deftly;
use sport_log_derive::*;

#[derive(Db, DbWithUserId, ModifiableDb, Deftly)]
#[derive_deftly(
    VerifyForUserOrAPGet,
    Create,
    GetById,
    GetByUser,
    GetByUserAndEpoch,
    Update,
    GetEpochByUser,
    CheckUserId,
    VerifyForUserOrAPUpdate,
    VerifyForUserOrAPCreate
)]
pub struct DiaryDb;

#[derive(Db, DbWithUserId, ModifiableDb, Deftly)]
#[derive_deftly(
    VerifyForUserOrAPGet,
    Create,
    GetById,
    GetByUser,
    GetByUserAndEpoch,
    Update,
    GetEpochByUser,
    CheckUserId,
    VerifyForUserOrAPUpdate,
    VerifyForUserOrAPCreate
)]
pub struct WodDb;
