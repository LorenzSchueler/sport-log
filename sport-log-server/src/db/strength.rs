use derive_deftly::Deftly;
use sport_log_derive::*;

#[derive(Db, DbWithUserId, DbWithDateTime, ModifiableDb, Deftly)]
#[derive_deftly(
    VerifyForUserOrAPGet,
    Create,
    GetById,
    GetByUser,
    GetByUserTimespan,
    GetByUserAndEpoch,
    Update,
    CheckUserId,
    VerifyForUserOrAPUpdate,
    VerifyForUserOrAPCreate
)]
pub struct StrengthSessionDb;

#[derive(Db, DbWithUserId, ModifiableDb, Deftly)]
#[derive_deftly(
    VerifyForUserOrAPGet,
    Create,
    GetById,
    GetByUser,
    GetByUserAndEpoch,
    Update,
    CheckUserId,
    VerifyForUserOrAPUpdate,
    VerifyForUserOrAPCreate
)]
pub struct StrengthSetDb;

#[derive(Db, Deftly)]
#[derive_deftly(VerifyForAdminGet, GetById, GetAll)]
pub struct EormDb;
