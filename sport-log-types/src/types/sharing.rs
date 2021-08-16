use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

#[cfg(feature = "full")]
use sport_log_types_derive::{
    Create, CreateMultiple, FromI64, FromSql, GetById, GetByIds, GetByUser, GetByUserSync, ToI64,
    ToSql, Update,
};

use crate::{
    from_str, to_str, CardioSessionId, DiaryId, MetconSessionId, StrengthSessionId, UserId,
};
#[cfg(feature = "full")]
use crate::{
    schema::{
        group, group_user, shared_cardio_session, shared_diary, shared_metcon_session,
        shared_strength_session,
    },
    CardioSession, Diary, MetconSession, StrengthSession, User,
};

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq)]
#[cfg_attr(
    feature = "full",
    derive(Hash, FromSqlRow, AsExpression, FromI64, ToI64, ToSql, FromSql)
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::BigInt")]
pub struct GroupId(pub i64);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(
        Insertable,
        Associations,
        Identifiable,
        Queryable,
        AsChangeset,
        Create,
        CreateMultiple,
        GetById,
        GetByIds,
        Update,
    )
)]
#[cfg_attr(feature = "full", table_name = "group")]
pub struct Group {
    #[serde(serialize_with = "to_str")]
    #[serde(deserialize_with = "from_str")]
    pub id: GroupId,
    pub name: String,
    #[serde(skip)]
    #[serde(default = "Utc::now")]
    pub last_change: DateTime<Utc>,
    pub deleted: bool,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq)]
#[cfg_attr(
    feature = "full",
    derive(Hash, FromSqlRow, AsExpression, FromI64, ToI64, ToSql, FromSql)
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::BigInt")]
pub struct GroupUserId(pub i64);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(
        Insertable,
        Associations,
        Identifiable,
        Queryable,
        AsChangeset,
        Create,
        CreateMultiple,
        GetById,
        GetByIds,
        GetByUser,
        GetByUserSync,
        Update,
    )
)]
#[cfg_attr(feature = "full", table_name = "group_user")]
#[cfg_attr(feature = "full", belongs_to(Group))]
#[cfg_attr(feature = "full", belongs_to(User))]
pub struct GroupUser {
    #[serde(serialize_with = "to_str")]
    #[serde(deserialize_with = "from_str")]
    pub id: GroupUserId,
    pub group_id: GroupId,
    pub user_id: UserId,
    #[serde(skip)]
    #[serde(default = "Utc::now")]
    pub last_change: DateTime<Utc>,
    pub deleted: bool,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq)]
#[cfg_attr(
    feature = "full",
    derive(Hash, FromSqlRow, AsExpression, FromI64, ToI64, ToSql, FromSql)
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::BigInt")]
pub struct SharedMetconSessionId(pub i64);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(
        Insertable,
        Associations,
        Identifiable,
        Queryable,
        AsChangeset,
        Create,
        CreateMultiple,
        GetById,
        GetByIds,
        Update,
    )
)]
#[cfg_attr(feature = "full", table_name = "shared_metcon_session")]
#[cfg_attr(feature = "full", belongs_to(Group))]
#[cfg_attr(feature = "full", belongs_to(MetconSession))]
pub struct SharedMetconSession {
    #[serde(serialize_with = "to_str")]
    #[serde(deserialize_with = "from_str")]
    pub id: GroupUserId,
    pub group_id: GroupId,
    pub metcon_session_id: MetconSessionId,
    #[serde(skip)]
    #[serde(default = "Utc::now")]
    pub last_change: DateTime<Utc>,
    pub deleted: bool,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq)]
#[cfg_attr(
    feature = "full",
    derive(Hash, FromSqlRow, AsExpression, FromI64, ToI64, ToSql, FromSql)
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::BigInt")]
pub struct SharedStrengthSessionId(pub i64);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(
        Insertable,
        Associations,
        Identifiable,
        Queryable,
        AsChangeset,
        Create,
        CreateMultiple,
        GetById,
        GetByIds,
        Update,
    )
)]
#[cfg_attr(feature = "full", table_name = "shared_strength_session")]
#[cfg_attr(feature = "full", belongs_to(Group))]
#[cfg_attr(feature = "full", belongs_to(StrengthSession))]
pub struct SharedStrengthSession {
    #[serde(serialize_with = "to_str")]
    #[serde(deserialize_with = "from_str")]
    pub id: GroupUserId,
    pub group_id: GroupId,
    pub strength_session_id: StrengthSessionId,
    #[serde(skip)]
    #[serde(default = "Utc::now")]
    pub last_change: DateTime<Utc>,
    pub deleted: bool,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq)]
#[cfg_attr(
    feature = "full",
    derive(Hash, FromSqlRow, AsExpression, FromI64, ToI64, ToSql, FromSql)
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::BigInt")]
pub struct SharedCardioSessionId(pub i64);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(
        Insertable,
        Associations,
        Identifiable,
        Queryable,
        AsChangeset,
        Create,
        CreateMultiple,
        GetById,
        GetByIds,
        Update,
    )
)]
#[cfg_attr(feature = "full", table_name = "shared_cardio_session")]
#[cfg_attr(feature = "full", belongs_to(Group))]
#[cfg_attr(feature = "full", belongs_to(CardioSession))]
pub struct SharedCardioSession {
    #[serde(serialize_with = "to_str")]
    #[serde(deserialize_with = "from_str")]
    pub id: GroupUserId,
    pub group_id: GroupId,
    pub cardio_session_id: CardioSessionId,
    #[serde(skip)]
    #[serde(default = "Utc::now")]
    pub last_change: DateTime<Utc>,
    pub deleted: bool,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq)]
#[cfg_attr(
    feature = "full",
    derive(Hash, FromSqlRow, AsExpression, FromI64, ToI64, ToSql, FromSql)
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::BigInt")]
pub struct SharedDiaryId(pub i64);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(
        Insertable,
        Associations,
        Identifiable,
        Queryable,
        AsChangeset,
        Create,
        CreateMultiple,
        GetById,
        GetByIds,
        Update,
    )
)]
#[cfg_attr(feature = "full", table_name = "shared_diary")]
#[cfg_attr(feature = "full", belongs_to(Group))]
#[cfg_attr(feature = "full", belongs_to(Diary))]
pub struct SharedDiary {
    #[serde(serialize_with = "to_str")]
    #[serde(deserialize_with = "from_str")]
    pub id: GroupUserId,
    pub group_id: GroupId,
    pub diary_id: DiaryId,
    #[serde(skip)]
    #[serde(default = "Utc::now")]
    pub last_change: DateTime<Utc>,
    pub deleted: bool,
}
