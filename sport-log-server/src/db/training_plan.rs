use sport_log_types_derive::*;

#[derive(
    Db,
    DbWithUserId,
    ModifiableDb,
    VerifyIdForUserOrAP,
    Create,
    GetById,
    GetByIds,
    GetByUser,
    GetByUserSync,
    Update,
    HardDelete,
    VerifyForUserOrAPWithDb,
    VerifyForUserOrAPWithoutDb,
    CheckUserId,
)]
pub struct TrainingPlanDb;
