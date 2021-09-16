#[cfg(feature = "server")]
use chrono::{DateTime, Utc};
#[cfg(feature = "server")]
use diesel::{PgConnection, QueryResult};
#[cfg(feature = "server")]
use rocket::{
    data::{self, FromData},
    http::Status,
    outcome::Outcome,
    serde::json::{self, Json},
    Data, Request,
};
use serde::{de, Deserialize, Deserializer, Serializer};

mod account;
mod action;
mod activity;
mod admin;
#[cfg(feature = "server")]
mod auth;
mod cardio;
#[cfg(feature = "server")]
mod config;
#[cfg(feature = "server")]
mod db;
mod diary_wod;
mod metcon;
mod movement;
mod platform;
mod sharing;
mod strength;
mod user;

pub use account::*;
pub use action::*;
pub use activity::*;
pub use admin::*;
#[cfg(feature = "server")]
pub use auth::*;
pub use cardio::*;
#[cfg(feature = "server")]
pub use config::*;
#[cfg(feature = "server")]
pub use db::*;
pub use diary_wod::*;
pub use metcon::*;
pub use movement::*;
pub use platform::*;
pub use sharing::*;
pub use strength::*;
pub use user::*;

/// Wrapper around incoming json data for which the access permissions for the [AuthUserOrAP], [AuthAP] or [AuthAdmin] have not been checked.
///
/// The data can be retrieved by using the appropriate verification function.
#[cfg(feature = "server")]
#[derive(Debug)]
pub struct Unverified<T>(Json<T>);

#[cfg(feature = "server")]
#[rocket::async_trait]
impl<'r, T: Deserialize<'r>> FromData<'r> for Unverified<T> {
    type Error = json::Error<'r>;

    async fn from_data(req: &'r Request<'_>, data: Data<'r>) -> data::Outcome<'r, Self> {
        Json::<T>::from_data(req, data)
            .await
            .and_then(|data| Outcome::Success(Self(data)))
    }
}

/// Indicated that the type can be build from an [i64].
pub trait FromI64 {
    fn from_i64(value: i64) -> Self;
}

/// Indicated that the type can be converted into an [i64].
pub trait ToI64 {
    fn to_i64(&self) -> i64;
}

pub fn from_str<'de, T, D>(deserializer: D) -> Result<T, D::Error>
where
    T: FromI64,
    D: Deserializer<'de>,
{
    let s = String::deserialize(deserializer)?
        .parse()
        .map_err(de::Error::custom)?;
    Ok(T::from_i64(s))
}

pub fn to_str<T, S>(id: &T, serializer: S) -> Result<S::Ok, S::Error>
where
    T: ToI64,
    S: Serializer,
{
    serializer.serialize_str(&id.to_i64().to_string())
}

pub fn from_str_optional<'de, T, D>(deserializer: D) -> Result<Option<T>, D::Error>
where
    T: FromI64,
    D: Deserializer<'de>,
{
    let s = Option::<String>::deserialize(deserializer)?;
    Ok(match s {
        Some(string) => Some(T::from_i64(string.parse().map_err(de::Error::custom)?)),
        None => None,
    })
}

pub fn to_str_optional<T, S>(id: &Option<T>, serializer: S) -> Result<S::Ok, S::Error>
where
    T: ToI64,
    S: Serializer,
{
    match id {
        Some(t) => serializer.serialize_str(&t.to_i64().to_string()),
        None => serializer.serialize_none(),
    }
}

/// Wrapper around an incomming id for which the access permissions for the [AuthUserOrAP], [AuthAP] or [AuthAdmin] have not been checked.
///
/// The id can be retrieved by using the appropriate verification function.
#[cfg(feature = "server")]
#[derive(Debug, Clone)]
pub struct UnverifiedId<I>(I);

#[cfg(feature = "server")]
impl<'v, I: FromI64> rocket::request::FromParam<'v> for UnverifiedId<I> {
    type Error = &'v str;

    fn from_param(param: &'v str) -> Result<Self, Self::Error> {
        Ok(Self(I::from_i64(i64::from_param(param)?)))
    }
}

/// Wrapper around multiple incoming ids for which the access permissions for the [AuthUserOrAP], [AuthAP] or [AuthAdmin] have not been checked.
///
/// The ids type can be retrieved by using the appropriate verification function.
#[cfg(feature = "server")]
#[derive(Debug, Clone)]
pub struct UnverifiedIds<I>(Vec<I>);

#[cfg(feature = "server")]
#[rocket::async_trait]
impl<'r, I: FromI64 + Deserialize<'r>> FromData<'r> for UnverifiedIds<I> {
    type Error = json::Error<'r>;

    async fn from_data(req: &'r Request<'_>, data: Data<'r>) -> data::Outcome<'r, Self> {
        <rocket::serde::json::Json<Vec<i64>> as FromData>::from_data(req, data)
            .await
            .and_then(|ids_json| {
                Outcome::Success(Self(
                    ids_json.into_inner().into_iter().map(I::from_i64).collect(),
                ))
            })
    }
}

/// A type for which a new database entry can be created.
///
/// ### Deriving
///
/// This trait can be automatically derived by adding `#[derive(Create)]` to your struct.
///
/// For restrictions on the types for derive to work please see [sport_log_types_derive::Create].
#[cfg(feature = "server")]
pub trait Create {
    fn create(entity: Self, conn: &PgConnection) -> QueryResult<Self>
    where
        Self: Sized;
}

/// A type for which new database entries can be created.
///
/// ### Deriving
///
/// This trait can be automatically derived by adding `#[derive(CreateMultiple)]` to your struct.
///
/// For restrictions on the types for derive to work please see [sport_log_types_derive::CreateMultiple].
#[cfg(feature = "server")]
pub trait CreateMultiple {
    fn create_multiple(enteties: Vec<Self>, conn: &PgConnection) -> QueryResult<Vec<Self>>
    where
        Self: Sized;
}

/// A type for which an entry can be retrieved by id from the database.
///
/// ### Deriving
///
/// This trait can be automatically derived by adding `#[derive(GetById)]` to your struct.
///
/// For restrictions on the types for derive to work please see [sport_log_types_derive::GetById].
#[cfg(feature = "server")]
pub trait GetById {
    type Id;

    fn get_by_id(id: Self::Id, conn: &PgConnection) -> QueryResult<Self>
    where
        Self: Sized;
}

/// A type for which entries can be retrieved by id from the database.
///
/// ### Deriving
///
/// This trait can be automatically derived by adding `#[derive(GetByIds)]` to your struct.
///
/// For restrictions on the types for derive to work please see [sport_log_types_derive::GetByIds].
#[cfg(feature = "server")]
pub trait GetByIds {
    type Id;

    fn get_by_ids(ids: &[Self::Id], conn: &PgConnection) -> QueryResult<Vec<Self>>
    where
        Self: Sized;
}

/// A type for which entries can be retrieved by user from the database.
///
/// ### Deriving
///
/// This trait can be automatically derived by adding `#[derive(GetByUser)]` to your struct.
///
/// For restrictions on the types for derive to work please see [sport_log_types_derive::GetByUser].
#[cfg(feature = "server")]
pub trait GetByUser {
    fn get_by_user(user_id: UserId, conn: &PgConnection) -> QueryResult<Vec<Self>>
    where
        Self: Sized;
}

/// A type for which entries can be retrieved by user and the timestamp of the last synchonization from the database.
///
/// ### Deriving
///
/// This trait can be automatically derived by adding `#[derive(GetByUserSync)]` to your struct.
///
/// For restrictions on the types for derive to work please see [sport_log_types_derive::GetByUserSync].
#[cfg(feature = "server")]
pub trait GetByUserSync {
    fn get_by_user_and_last_sync(
        user_id: UserId,
        last_sync: DateTime<Utc>,
        conn: &PgConnection,
    ) -> QueryResult<Vec<Self>>
    where
        Self: Sized;
}

/// A type for which entries can be retrieved by the timestamp of the last synchonization from the database.
///
/// ### Deriving
///
/// This trait can be automatically derived by adding `#[derive(GetBySync)]` to your struct.
///
/// For restrictions on the types for derive to work please see [sport_log_types_derive::GetBySync].
#[cfg(feature = "server")]
pub trait GetBySync {
    fn get_by_last_sync(last_sync: DateTime<Utc>, conn: &PgConnection) -> QueryResult<Vec<Self>>
    where
        Self: Sized;
}

/// A type for which all entries can be retrieved from the database.
///
/// ### Deriving
///
/// This trait can be automatically derived by adding `#[derive(GetAll)]` to your struct.
///
/// For restrictions on the types for derive to work please see [sport_log_types_derive::GetAll].
#[cfg(feature = "server")]
pub trait GetAll {
    fn get_all(conn: &PgConnection) -> QueryResult<Vec<Self>>
    where
        Self: Sized;
}

/// A type which can be used to update an entry in the database.
///
/// ### Deriving
///
/// This trait can be automatically derived by adding `#[derive(Update)]` to your struct.
///
/// For restrictions on the types for derive to work please see [sport_log_types_derive::Update].
#[cfg(feature = "server")]
pub trait Update {
    fn update(entity: Self, conn: &PgConnection) -> QueryResult<Self>
    where
        Self: Sized;

    fn update_multiple(entities: Vec<Self>, conn: &PgConnection) -> QueryResult<Vec<Self>>
    where
        Self: Sized;
}

/// A type which can be checked if it belongs to a User.
///
/// ### Deriving
///
/// This trait can be automatically derived by adding `#[derive(CheckUserId)]` to your struct if the struct has a field `user_id` of type [UserId].
#[cfg(feature = "server")]
pub trait CheckUserId {
    type Id;

    /// Check if the entry with id `id` in the database belongs to the [User] with `user_id`.
    fn check_user_id(id: Self::Id, user_id: UserId, conn: &PgConnection) -> QueryResult<bool>;

    /// Check if the entries with an id in `ids` in the database belong to the [User] with `user_id`.
    fn check_user_ids(ids: &[Self::Id], user_id: UserId, conn: &PgConnection) -> QueryResult<bool>;
}

/// A type which can be checked if it belongs to a User or is public.
#[cfg(feature = "server")]
pub trait CheckOptionalUserId {
    type Id;

    /// Check if the entry with id `id` in the database belongs to the [User] with `user_id` or is public (`user_id` is None).
    fn check_optional_user_id(
        id: Self::Id,
        user_id: UserId,
        conn: &PgConnection,
    ) -> QueryResult<bool>;

    /// Check if the entries with an id in `ids` in the database belong to the [User] with `user_id` or are public (`user_id` is None).
    fn check_optional_user_ids(
        ids: &[Self::Id],
        user_id: UserId,
        conn: &PgConnection,
    ) -> QueryResult<bool>;
}

#[cfg(feature = "server")]
pub trait CheckAPId {
    type Id;

    fn check_ap_id(id: Self::Id, ap_id: ActionProviderId, conn: &PgConnection)
        -> QueryResult<bool>;

    fn check_ap_ids(
        ids: &[Self::Id],
        ap_id: ActionProviderId,
        conn: &PgConnection,
    ) -> QueryResult<bool>;
}

#[cfg(feature = "server")]
pub trait VerifyIdForUser {
    type Id;

    fn verify_user(self, auth: &AuthUser, conn: &PgConnection) -> Result<Self::Id, Status>;
}

#[cfg(feature = "server")]
pub trait VerifyIdsForUser {
    type Id;

    fn verify_user(self, auth: &AuthUser, conn: &PgConnection) -> Result<Vec<Self::Id>, Status>;
}

#[cfg(feature = "server")]
pub trait VerifyIdForUserOrAP {
    type Id;

    fn verify_user_ap(self, auth: &AuthUserOrAP, conn: &PgConnection) -> Result<Self::Id, Status>;
}

#[cfg(feature = "server")]
pub trait VerifyIdsForUserOrAP {
    type Id;

    fn verify_user_ap(
        self,
        auth: &AuthUserOrAP,
        conn: &PgConnection,
    ) -> Result<Vec<Self::Id>, Status>;
}

#[cfg(feature = "server")]
pub trait VerifyIdForActionProvider {
    type Id;

    fn verify_ap(self, auth: &AuthAP, conn: &PgConnection) -> Result<Self::Id, Status>;
}

#[cfg(feature = "server")]
pub trait VerifyIdsForActionProvider {
    type Id;

    fn verify_ap(self, auth: &AuthAP, conn: &PgConnection) -> Result<Vec<Self::Id>, Status>;
}

#[cfg(feature = "server")]
pub trait VerifyIdForAdmin {
    type Id;

    fn verify_adm(self, auth: &AuthAdmin) -> Result<Self::Id, Status>;
}

#[cfg(feature = "server")]
pub trait VerifyIdsForAdmin {
    type Id;

    fn verify_adm(self, auth: &AuthAdmin) -> Result<Vec<Self::Id>, Status>;
}

#[cfg(feature = "server")]
pub trait VerifyIdUnchecked {
    type Id;

    fn verify_unchecked(self) -> Result<Self::Id, Status>;
}

#[cfg(feature = "server")]
pub trait VerifyForUserWithDb {
    type Entity;

    fn verify_user(self, auth: &AuthUser, conn: &PgConnection) -> Result<Self::Entity, Status>;
}

#[cfg(feature = "server")]
pub trait VerifyMultipleForUserWithDb {
    type Entity;

    fn verify_user(self, auth: &AuthUser, conn: &PgConnection)
        -> Result<Vec<Self::Entity>, Status>;
}

#[cfg(feature = "server")]
pub trait VerifyForUserWithoutDb {
    type Entity;

    fn verify_user_without_db(self, auth: &AuthUser) -> Result<Self::Entity, Status>;
}

#[cfg(feature = "server")]
pub trait VerifyMultipleForUserWithoutDb {
    type Entity;

    fn verify_user_without_db(self, auth: &AuthUser) -> Result<Vec<Self::Entity>, Status>;
}

#[cfg(feature = "server")]
pub trait VerifyForUserOrAPWithDb {
    type Entity;

    fn verify_user_ap(
        self,
        auth: &AuthUserOrAP,
        conn: &PgConnection,
    ) -> Result<Self::Entity, Status>;
}

#[cfg(feature = "server")]
pub trait VerifyMultipleForUserOrAPWithDb {
    type Entity;

    fn verify_user_ap(
        self,
        auth: &AuthUserOrAP,
        conn: &PgConnection,
    ) -> Result<Vec<Self::Entity>, Status>;
}

#[cfg(feature = "server")]
pub trait VerifyForUserOrAPWithoutDb {
    type Entity;

    fn verify_user_ap_without_db(self, auth: &AuthUserOrAP) -> Result<Self::Entity, Status>;
}

#[cfg(feature = "server")]
pub trait VerifyMultipleForUserOrAPWithoutDb {
    type Entity;

    fn verify_user_ap_without_db(self, auth: &AuthUserOrAP) -> Result<Vec<Self::Entity>, Status>;
}

#[cfg(feature = "server")]
pub trait VerifyForActionProviderWithDb {
    type Entity;

    fn verify_ap(self, auth: &AuthAP, conn: &PgConnection) -> Result<Self::Entity, Status>;
}

#[cfg(feature = "server")]
pub trait VerifyForActionProviderWithoutDb {
    type Entity;

    fn verify_ap_without_db(self, auth: &AuthAP) -> Result<Self::Entity, Status>;
}

#[cfg(feature = "server")]
pub trait VerifyMultipleForActionProviderWithoutDb {
    type Entity;

    fn verify_ap_without_db(self, auth: &AuthAP) -> Result<Vec<Self::Entity>, Status>;
}

#[cfg(feature = "server")]
pub trait VerifyForAdminWithoutDb {
    type Entity;

    fn verify_adm(self, auth: &AuthAdmin) -> Result<Self::Entity, Status>;
}

#[cfg(feature = "server")]
pub trait VerifyMultipleForAdminWithoutDb {
    type Entity;

    fn verify_adm(self, auth: &AuthAdmin) -> Result<Vec<Self::Entity>, Status>;
}

#[cfg(feature = "server")]
pub trait VerifyUnchecked {
    type Entity;

    fn verify_unchecked(self) -> Result<Self::Entity, Status>;
}
