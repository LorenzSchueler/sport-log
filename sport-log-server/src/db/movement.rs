use derive_deftly::Deftly;
use sport_log_derive::*;

use crate::db::*;

#[derive(Db, DbWithUserId, ModifiableDb, Deftly)]
#[derive_deftly(
    VerifyIdForAdmin,
    VerifyIdUnchecked,
    Create,
    GetById,
    GetByUserOptional,
    GetByUserAndEpochOptional,
    Update,
    HardDelete,
    CheckOptionalUserId,
    VerifyIdForUserOrAPOptional,
    VerifyForUserOrAPWithDbOptional,
    VerifyForUserOrAPWithoutDbOptional,
    VerifyForAdminWithoutDb
)]
pub struct MovementDb;
