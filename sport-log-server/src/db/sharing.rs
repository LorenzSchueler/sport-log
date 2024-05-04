use sport_log_derive::*;

#[derive(Db, ModifiableDb, Create, GetById, Update, HardDelete)]
pub struct GroupDb;

#[derive(
    Db, DbWithUserId, ModifiableDb, Create, GetById, GetByUser, GetByUserSync, Update, HardDelete,
)]
pub struct GroupUserDb;

#[derive(Db, ModifiableDb, Create, GetById, Update, HardDelete)]
pub struct SharedMetconSessionDb;

#[derive(Db, ModifiableDb, Create, GetById, Update, HardDelete)]
pub struct SharedStrengthSessionDb;

#[derive(Db, ModifiableDb, Create, GetById, Update, HardDelete)]
pub struct SharedCardioSessionDb;

#[derive(Db, ModifiableDb, Create, GetById, Update, HardDelete)]
pub struct SharedDiaryDb;
