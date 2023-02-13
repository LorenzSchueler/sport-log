use sport_log_types_derive::*;

#[derive(Db, Create, GetById, GetByIds, Update, HardDelete)]
pub struct GroupDb;

#[derive(Db, Create, GetById, GetByIds, GetByUser, GetByUserSync, Update, HardDelete)]
pub struct GroupUserDb;

#[derive(Db, Create, GetById, GetByIds, Update, HardDelete)]
pub struct SharedMetconSessionDb;

#[derive(Db, Create, GetById, GetByIds, Update, HardDelete)]
pub struct SharedStrengthSessionDb;

#[derive(Db, Create, GetById, GetByIds, Update, HardDelete)]
pub struct SharedCardioSessionDb;

#[derive(Db, Create, GetById, GetByIds, Update, HardDelete)]
pub struct SharedDiaryDb;
