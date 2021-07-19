use serde::{Deserialize, Serialize};

use sport_log_server_derive::{
    Create, Delete, GetAll, GetById, InnerIntFromSql, InnerIntToSql, Update,
};

#[cfg(feature = "full")]
use crate::schema::{
    group, group_user, shared_cardio_session, shared_diary, shared_metcon_session,
    shared_strength_session,
};
use crate::types::{CardioSessionId, DiaryId, MetconSessionId, StrengthSessionId, UserId};

#[cfg_attr(
    feature = "full",
    derive(
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
    )
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::Integer")]
pub struct GroupId(pub i32);

#[cfg_attr(
    feature = "full",
    derive(
        Queryable,
        AsChangeset,
        Serialize,
        Deserialize,
        Debug,
        Create,
        GetById,
        GetAll,
        Update,
        Delete,
    )
)]
#[cfg_attr(feature = "full", table_name = "group")]
pub struct Group {
    pub id: GroupId,
    pub name: String,
}

#[cfg_attr(feature = "full", derive(Insertable, Serialize, Deserialize))]
#[cfg_attr(feature = "full", table_name = "group")]
pub struct NewGroup {
    pub name: String,
}

#[cfg_attr(
    feature = "full",
    derive(
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
    )
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::Integer")]
pub struct GroupUserId(pub i32);

#[cfg_attr(
    feature = "full",
    derive(
        Queryable,
        AsChangeset,
        Serialize,
        Deserialize,
        Debug,
        Create,
        GetById,
        GetAll,
        Update,
        Delete,
    )
)]
#[cfg_attr(feature = "full", table_name = "group_user")]
pub struct GroupUser {
    pub id: GroupUserId,
    pub group_id: GroupId,
    pub user_id: UserId,
}

#[cfg_attr(feature = "full", derive(Insertable, Serialize, Deserialize))]
#[cfg_attr(feature = "full", table_name = "group_user")]
pub struct NewGroupUser {
    pub group_id: GroupId,
    pub user_id: UserId,
}

#[cfg_attr(
    feature = "full",
    derive(
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
    )
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::Integer")]
pub struct SharedMetconSessionId(pub i32);

#[cfg_attr(
    feature = "full",
    derive(
        Queryable,
        AsChangeset,
        Serialize,
        Deserialize,
        Debug,
        Create,
        GetById,
        GetAll,
        Update,
        Delete,
    )
)]
#[cfg_attr(feature = "full", table_name = "shared_metcon_session")]
pub struct SharedMetconSession {
    pub id: GroupUserId,
    pub group_id: GroupId,
    pub metcon_session_id: MetconSessionId,
}

#[cfg_attr(feature = "full", derive(Insertable, Serialize, Deserialize))]
#[cfg_attr(feature = "full", table_name = "shared_metcon_session")]
pub struct NewSharedMetconSession {
    pub group_id: GroupId,
    pub metcon_session_id: MetconSessionId,
}

#[cfg_attr(
    feature = "full",
    derive(
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
    )
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::Integer")]
pub struct SharedStrengthSessionId(pub i32);

#[cfg_attr(
    feature = "full",
    derive(
        Queryable,
        AsChangeset,
        Serialize,
        Deserialize,
        Debug,
        Create,
        GetById,
        GetAll,
        Update,
        Delete,
    )
)]
#[cfg_attr(feature = "full", table_name = "shared_strength_session")]
pub struct SharedStrengthSession {
    pub id: GroupUserId,
    pub group_id: GroupId,
    pub strength_session_id: StrengthSessionId,
}

#[cfg_attr(feature = "full", derive(Insertable, Serialize, Deserialize))]
#[cfg_attr(feature = "full", table_name = "shared_strength_session")]
pub struct NewSharedStrengthSession {
    pub group_id: GroupId,
    pub strength_session_id: StrengthSessionId,
}

#[cfg_attr(
    feature = "full",
    derive(
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
    )
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::Integer")]
pub struct SharedCardioSessionId(pub i32);

#[cfg_attr(
    feature = "full",
    derive(
        Queryable,
        AsChangeset,
        Serialize,
        Deserialize,
        Debug,
        Create,
        GetById,
        GetAll,
        Update,
        Delete,
    )
)]
#[cfg_attr(feature = "full", table_name = "shared_cardio_session")]
pub struct SharedCardioSession {
    pub id: GroupUserId,
    pub group_id: GroupId,
    pub cardio_session_id: CardioSessionId,
}

#[cfg_attr(feature = "full", derive(Insertable, Serialize, Deserialize))]
#[cfg_attr(feature = "full", table_name = "shared_cardio_session")]
pub struct NewSharedCardioSession {
    pub group_id: GroupId,
    pub cardio_session_id: CardioSessionId,
}

#[cfg_attr(
    feature = "full",
    derive(
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
    )
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::Integer")]
pub struct SharedDiaryId(pub i32);

#[cfg_attr(
    feature = "full",
    derive(
        Queryable,
        AsChangeset,
        Serialize,
        Deserialize,
        Debug,
        Create,
        GetById,
        GetAll,
        Update,
        Delete,
    )
)]
#[cfg_attr(feature = "full", table_name = "shared_diary")]
pub struct SharedDiary {
    pub id: GroupUserId,
    pub group_id: GroupId,
    pub diary_id: DiaryId,
}

#[cfg_attr(feature = "full", derive(Insertable, Serialize, Deserialize))]
#[cfg_attr(feature = "full", table_name = "shared_diary")]
pub struct NewSharedDiary {
    pub group_id: GroupId,
    pub diary_id: DiaryId,
}
