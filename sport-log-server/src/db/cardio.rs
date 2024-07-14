use derive_deftly::Deftly;
use sport_log_derive::*;

#[derive(Db, DbWithUserId, ModifiableDb, Deftly)]
#[derive_deftly(
    VerifyIdForUserOrAP,
    Create,
    GetById,
    GetByUser,
    GetByUserAndEpoch,
    Update,
    HardDelete,
    CheckUserId,
    VerifyForUserOrAPWithDb,
    VerifyForUserOrAPWithoutDb
)]
pub struct RouteDb;

#[derive(Db, DbWithUserId, DbWithDateTime, ModifiableDb, Deftly)]
#[derive_deftly(
    VerifyIdForUserOrAP,
    Create,
    GetById,
    GetByUser,
    GetByUserTimespan,
    GetByUserAndEpoch,
    Update,
    HardDelete,
    CheckUserId,
    VerifyForUserOrAPWithDb,
    VerifyForUserOrAPWithoutDb
)]
pub struct CardioSessionDb;
