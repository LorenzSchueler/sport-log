use serde::{Deserialize, Serialize};

use sport_log_server_derive::{
    Create, Delete, GetAll, GetById, InnerIntFromSql, InnerIntToSql, Update,
};

use crate::{
    model::{CardioSessionId, DiaryId, MetconSessionId, StrengthSessionId, UserId},
    schema::{
        group, group_user, shared_cardio_session, shared_diary, shared_metcon_session,
        shared_strength_session,
    },
};

#[derive(
    FromSqlRow,
    AsExpression,
    Serialize,
    Deserialize,
    Debug,
    Clone,
    Copy,
    PartialEq,
    Eq,
    InnerIntToSql,
    InnerIntFromSql,
)]
#[sql_type = "diesel::sql_types::Integer"]
pub struct GroupId(pub i32);

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

#[derive(
    FromSqlRow,
    AsExpression,
    Serialize,
    Deserialize,
    Debug,
    Clone,
    Copy,
    PartialEq,
    Eq,
    InnerIntToSql,
    InnerIntFromSql,
)]
#[sql_type = "diesel::sql_types::Integer"]
pub struct GroupUserId(pub i32);

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

#[derive(
    FromSqlRow,
    AsExpression,
    Serialize,
    Deserialize,
    Debug,
    Clone,
    Copy,
    PartialEq,
    Eq,
    InnerIntToSql,
    InnerIntFromSql,
)]
#[sql_type = "diesel::sql_types::Integer"]
pub struct SharedMetconSessionId(pub i32);

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

#[derive(
    FromSqlRow,
    AsExpression,
    Serialize,
    Deserialize,
    Debug,
    Clone,
    Copy,
    PartialEq,
    Eq,
    InnerIntToSql,
    InnerIntFromSql,
)]
#[sql_type = "diesel::sql_types::Integer"]
pub struct SharedStrengthSessionId(pub i32);

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

#[derive(
    FromSqlRow,
    AsExpression,
    Serialize,
    Deserialize,
    Debug,
    Clone,
    Copy,
    PartialEq,
    Eq,
    InnerIntToSql,
    InnerIntFromSql,
)]
#[sql_type = "diesel::sql_types::Integer"]
pub struct SharedCardioSessionId(pub i32);

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

#[derive(
    FromSqlRow,
    AsExpression,
    Serialize,
    Deserialize,
    Debug,
    Clone,
    Copy,
    PartialEq,
    Eq,
    InnerIntToSql,
    InnerIntFromSql,
)]
#[sql_type = "diesel::sql_types::Integer"]
pub struct SharedDiaryId(pub i32);

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
