use derive_deftly::Deftly;
use sport_log_derive::*;

use crate::db::*;

#[derive(Db, DbWithUserId, ModifiableDb, Deftly)]
#[derive_deftly(
    Create,
    GetById,
    GetByUserOptional,
    GetByUserAndEpochOptional,
    Update,
    CheckOptionalUserId,
    VerifyIdForUserOrAPOptional,
    VerifyForUserOrAPWithDbOptional,
    VerifyForUserOrAPWithoutDbOptional
)]
pub struct MetconDb;

#[derive(Db, DbWithUserId, ModifiableDb, Deftly)]
#[derive_deftly(
    Create,
    GetById,
    GetByUserOptional,
    GetByUserAndEpochOptional,
    Update,
    CheckOptionalUserId,
    VerifyIdForUserOrAPOptional,
    VerifyForUserOrAPWithDbOptional,
    VerifyForUserOrAPWithoutDbOptional
)]
pub struct MetconMovementDb;

#[derive(Db, DbWithUserId, DbWithDateTime, ModifiableDb, Deftly)]
#[derive_deftly(
    VerifyIdForUserOrAP,
    Create,
    GetById,
    GetByUser,
    GetByUserTimespan,
    GetByUserAndEpoch,
    Update,
    CheckUserId,
    VerifyForUserOrAPWithDb,
    VerifyForUserOrAPWithoutDb
)]
pub struct MetconSessionDb;
