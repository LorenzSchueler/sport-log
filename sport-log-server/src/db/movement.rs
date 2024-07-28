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
    CheckOptionalUserId,
    VerifyForUserOrAPGetOptional,
    VerifyForUserOrAPUpdateOptional,
    VerifyForUserOrAPCreateOptional,
    VerifyForAdmin
)]
pub struct MovementDb;
