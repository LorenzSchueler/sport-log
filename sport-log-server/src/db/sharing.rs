use sport_log_types_derive::*;

#[derive(Db, ModifiableDb, Create, GetById, GetByIds, Update, HardDelete)]
pub struct GroupDb;

#[derive(
    Db,
    DbWithUserId,
    ModifiableDb,
    Create,
    GetById,
    GetByIds,
    GetByUser,
    GetByUserSync,
    Update,
    HardDelete,
)]
pub struct GroupUserDb;

#[derive(Db, ModifiableDb, Create, GetById, GetByIds, Update, HardDelete)]
pub struct SharedMetconSessionDb;

#[derive(Db, ModifiableDb, Create, GetById, GetByIds, Update, HardDelete)]
pub struct SharedStrengthSessionDb;

#[derive(Db, ModifiableDb, Create, GetById, GetByIds, Update, HardDelete)]
pub struct SharedCardioSessionDb;

#[derive(Db, ModifiableDb, Create, GetById, GetByIds, Update, HardDelete)]
pub struct SharedDiaryDb;
