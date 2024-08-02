use derive_deftly::Deftly;
use sport_log_derive::*;

use crate::db::*;

#[derive(Db, DbWithUserId, ModifiableDb, Deftly)]
#[derive_deftly(
    VerifyForAdminGet,
    Create,
    GetById,
    GetByUserOptional,
    GetByUserAndEpochOptional,
    Update,
    GetEpochByUserOptional,
    CheckOptionalUserId,
    VerifyForUserOrAPGetOptional,
    VerifyForUserOrAPUpdateOptional,
    VerifyForUserOrAPCreateOptional,
    VerifyForAdmin
)]
pub struct MovementDb;
