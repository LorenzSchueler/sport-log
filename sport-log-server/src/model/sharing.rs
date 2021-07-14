use serde::{Deserialize, Serialize};

use sport_log_server_derive::{Create, Delete, GetAll, GetById, Update};

use crate::{
    model::{CardioSessionId, DiaryId, MetconSessionId, StrengthSessionId, UserId},
    schema::{
        group, group_user, shared_cardio_session, shared_diary, shared_metcon_session,
        shared_strength_session,
    },
};

pub type GroupId = i32;

#[derive(
    Queryable, AsChangeset, Serialize, Deserialize, Debug, Create, GetById, GetAll, Update, Delete,
)]
#[table_name = "group"]
pub struct Group {
    pub id: GroupId,
    pub name: String,
}

#[derive(Insertable, Serialize, Deserialize)]
#[table_name = "group"]
pub struct NewGroup {
    pub name: String,
}

pub type GroupUserId = i32;

#[derive(
    Queryable, AsChangeset, Serialize, Deserialize, Debug, Create, GetById, GetAll, Update, Delete,
)]
#[table_name = "group_user"]
pub struct GroupUser {
    pub id: GroupUserId,
    pub group_id: GroupId,
    pub user_id: UserId,
}

#[derive(Insertable, Serialize, Deserialize)]
#[table_name = "group_user"]
pub struct NewGroupUser {
    pub group_id: GroupId,
    pub user_id: UserId,
}

pub type SharedMetconSessionId = i32;

#[derive(
    Queryable, AsChangeset, Serialize, Deserialize, Debug, Create, GetById, GetAll, Update, Delete,
)]
#[table_name = "shared_metcon_session"]
pub struct SharedMetconSession {
    pub id: GroupUserId,
    pub group_id: GroupId,
    pub metcon_session_id: MetconSessionId,
}

#[derive(Insertable, Serialize, Deserialize)]
#[table_name = "shared_metcon_session"]
pub struct NewSharedMetconSession {
    pub group_id: GroupId,
    pub metcon_session_id: MetconSessionId,
}

pub type SharedStrengthSessionId = i32;

#[derive(
    Queryable, AsChangeset, Serialize, Deserialize, Debug, Create, GetById, GetAll, Update, Delete,
)]
#[table_name = "shared_strength_session"]
pub struct SharedStrengthSession {
    pub id: GroupUserId,
    pub group_id: GroupId,
    pub strength_session_id: StrengthSessionId,
}

#[derive(Insertable, Serialize, Deserialize)]
#[table_name = "shared_strength_session"]
pub struct NewSharedStrengthSession {
    pub group_id: GroupId,
    pub strength_session_id: StrengthSessionId,
}

pub type SharedCardioSessionId = i32;

#[derive(
    Queryable, AsChangeset, Serialize, Deserialize, Debug, Create, GetById, GetAll, Update, Delete,
)]
#[table_name = "shared_cardio_session"]
pub struct SharedCardioSession {
    pub id: GroupUserId,
    pub group_id: GroupId,
    pub cardio_session_id: CardioSessionId,
}

#[derive(Insertable, Serialize, Deserialize)]
#[table_name = "shared_cardio_session"]
pub struct NewSharedCardioSession {
    pub group_id: GroupId,
    pub cardio_session_id: CardioSessionId,
}

pub type SharedDiaryId = i32;

#[derive(
    Queryable, AsChangeset, Serialize, Deserialize, Debug, Create, GetById, GetAll, Update, Delete,
)]
#[table_name = "shared_diary"]
pub struct SharedDiary {
    pub id: GroupUserId,
    pub group_id: GroupId,
    pub diary_id: DiaryId,
}

#[derive(Insertable, Serialize, Deserialize)]
#[table_name = "shared_diary"]
pub struct NewSharedDiary {
    pub group_id: GroupId,
    pub diary_id: DiaryId,
}
