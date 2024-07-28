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
    VerifyForUserOrAPGetOptional,
    VerifyForUserOrAPUpdateOptional,
    VerifyForUserOrAPCreateOptional
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
    VerifyForUserOrAPGetOptional,
    VerifyForUserOrAPUpdateOptional,
    VerifyForUserOrAPCreateOptional
)]
pub struct MetconMovementDb;

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
pub struct MetconSessionDb;
