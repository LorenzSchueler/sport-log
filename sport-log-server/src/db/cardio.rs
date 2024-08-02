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
pub struct RouteDb;

#[derive(Db, DbWithUserId, DbWithDateTime, ModifiableDb, Deftly)]
#[derive_deftly(
    VerifyForUserOrAPGet,
    Create,
    GetById,
    GetByUser,
    GetByUserTimespan,
    GetByUserAndEpoch,
    Update,
    GetEpochByUser,
    CheckUserId,
    VerifyForUserOrAPUpdate,
    VerifyForUserOrAPCreate
)]
pub struct CardioSessionDb;
