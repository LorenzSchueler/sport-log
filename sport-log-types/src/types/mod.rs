#[cfg(feature = "server")]
use axum::http::StatusCode;
#[cfg(feature = "server")]
use chrono::{DateTime, Utc};
#[cfg(feature = "server")]
use diesel::{PgConnection, QueryResult};
use serde::{Deserialize, Serialize};

mod account;
mod action;
mod activity;
mod admin;
#[cfg(feature = "server")]
mod auth;
mod cardio;
#[cfg(feature = "server")]
mod config;
mod diary_wod;
#[cfg(feature = "server")]
pub mod error;
mod metcon;
mod movement;
mod platform;
mod sharing;
#[cfg(feature = "server")]
mod state;
mod strength;
mod training_plan;
pub mod uri;
mod user;
mod version;

pub use account::*;
pub use action::*;
pub use activity::*;
pub use admin::*;
#[cfg(feature = "server")]
pub use auth::*;
pub use cardio::*;
#[cfg(feature = "server")]
pub use config::*;
pub use diary_wod::*;
pub use metcon::*;
pub use movement::*;
pub use platform::*;
pub use sharing::*;
#[cfg(feature = "server")]
pub use state::*;
pub use strength::*;
pub use training_plan::*;
pub use user::*;
pub use version::*;

#[derive(Serialize, Deserialize, Debug, Clone)]
#[serde(transparent)]
struct IdString(String);

/// Wrapper around incoming json data for which the access permissions for the [AuthUserOrAP], [AuthAP] or [AuthAdmin] have not been checked.
///
/// The data can be retrieved by using the appropriate verification function.
#[cfg(feature = "server")]
#[derive(Debug, Deserialize)]
#[serde(transparent)]
pub struct Unverified<T>(T);

/// Wrapper around an incoming id for which the access permissions for the [AuthUserOrAP], [AuthAP] or [AuthAdmin] have not been checked.
///
/// The id can be retrieved by using the appropriate verification function.
#[cfg(feature = "server")]
#[derive(Debug, Clone, Deserialize)]
#[serde(transparent)]
pub struct UnverifiedId<I>(I);

/// Wrapper around multiple incoming ids for which the access permissions for the [AuthUserOrAP], [AuthAP] or [AuthAdmin] have not been checked.
///
/// The ids type can be retrieved by using the appropriate verification function.
#[cfg(feature = "server")]
#[derive(Debug, Clone, Deserialize)]
#[serde(transparent)]
pub struct UnverifiedIds<I>(Vec<I>);

/// A type for which a new database entry can be created.
///
/// ### Deriving
///
/// This trait can be automatically derived by adding `#[derive(Create)]` to your struct.
///
/// For restrictions on the types for derive to work please see [sport_log_types_derive::Create].
#[cfg(feature = "server")]
pub trait Create {
    fn create(entity: Self, db: &mut PgConnection) -> QueryResult<usize>
    where
        Self: Sized;

    fn create_multiple(entities: Vec<Self>, db: &mut PgConnection) -> QueryResult<usize>
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

    fn get_by_id(id: Self::Id, db: &mut PgConnection) -> QueryResult<Self>
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

    fn get_by_ids(ids: &[Self::Id], db: &mut PgConnection) -> QueryResult<Vec<Self>>
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
    fn get_by_user(user_id: UserId, db: &mut PgConnection) -> QueryResult<Vec<Self>>
    where
        Self: Sized;
}

/// A type for which entries can be retrieved by user and the timestamp of the last synchronization from the database.
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
        db: &mut PgConnection,
    ) -> QueryResult<Vec<Self>>
    where
        Self: Sized;
}

/// A type for which entries can be retrieved by the timestamp of the last synchronization from the database.
///
/// ### Deriving
///
/// This trait can be automatically derived by adding `#[derive(GetBySync)]` to your struct.
///
/// For restrictions on the types for derive to work please see [sport_log_types_derive::GetBySync].
#[cfg(feature = "server")]
pub trait GetBySync {
    fn get_by_last_sync(last_sync: DateTime<Utc>, db: &mut PgConnection) -> QueryResult<Vec<Self>>
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
    fn get_all(db: &mut PgConnection) -> QueryResult<Vec<Self>>
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
    fn update(entity: Self, db: &mut PgConnection) -> QueryResult<usize>
    where
        Self: Sized;

    fn update_multiple(entities: Vec<Self>, db: &mut PgConnection) -> QueryResult<usize>
    where
        Self: Sized;
}

/// A type for which all soft deleted entities can be hard deleted.
///
/// This is only intended for garbage collection triggered by `sport_log_scheduler`.
///
/// The function [hard_delete](HardDelete::hard_delete) will permanently delete all entities that are already soft deleted and which have not been changed since `last_change`.
///
/// ### Deriving
///
/// This trait can be automatically derived by adding `#[derive(HardDelete)]` to your struct.
///
/// For restrictions on the types for derive to work please see [sport_log_types_derive::HardDelete].
#[cfg(feature = "server")]
pub trait HardDelete {
    fn hard_delete(last_change: DateTime<Utc>, db: &mut PgConnection) -> QueryResult<usize>;
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
    fn check_user_id(id: Self::Id, user_id: UserId, db: &mut PgConnection) -> QueryResult<bool>;

    /// Check if the entries with an id in `ids` in the database belong to the [User] with `user_id`.
    fn check_user_ids(
        ids: &[Self::Id],
        user_id: UserId,
        db: &mut PgConnection,
    ) -> QueryResult<bool>;
}

/// A type which can be checked if it belongs to a User or is public.
#[cfg(feature = "server")]
pub trait CheckOptionalUserId {
    type Id;

    /// Check if the entry with id `id` in the database belongs to the [User] with `user_id` or is public (`user_id` is None).
    fn check_optional_user_id(
        id: Self::Id,
        user_id: UserId,
        db: &mut PgConnection,
    ) -> QueryResult<bool>;

    /// Check if the entries with an id in `ids` in the database belong to the [User] with `user_id` or are public (`user_id` is None).
    fn check_optional_user_ids(
        ids: &[Self::Id],
        user_id: UserId,
        db: &mut PgConnection,
    ) -> QueryResult<bool>;
}

#[cfg(feature = "server")]
pub trait CheckAPId {
    type Id;

    fn check_ap_id(
        id: Self::Id,
        ap_id: ActionProviderId,
        db: &mut PgConnection,
    ) -> QueryResult<bool>;

    fn check_ap_ids(
        ids: &[Self::Id],
        ap_id: ActionProviderId,
        db: &mut PgConnection,
    ) -> QueryResult<bool>;
}

#[cfg(feature = "server")]
pub trait VerifyIdForUser {
    type Id;

    fn verify_user(self, auth: AuthUser, db: &mut PgConnection) -> Result<Self::Id, StatusCode>;
}

#[cfg(feature = "server")]
pub trait VerifyIdsForUser {
    type Id;

    fn verify_user(
        self,
        auth: AuthUser,
        db: &mut PgConnection,
    ) -> Result<Vec<Self::Id>, StatusCode>;
}

#[cfg(feature = "server")]
pub trait VerifyIdForUserOrAP {
    type Id;

    fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Self::Id, StatusCode>;
}

#[cfg(feature = "server")]
pub trait VerifyIdsForUserOrAP {
    type Id;

    fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Vec<Self::Id>, StatusCode>;
}

#[cfg(feature = "server")]
pub trait VerifyIdForActionProvider {
    type Id;

    fn verify_ap(self, auth: AuthAP, db: &mut PgConnection) -> Result<Self::Id, StatusCode>;
}

#[cfg(feature = "server")]
pub trait VerifyIdsForActionProvider {
    type Id;

    fn verify_ap(self, auth: AuthAP, db: &mut PgConnection) -> Result<Vec<Self::Id>, StatusCode>;
}

#[cfg(feature = "server")]
pub trait VerifyIdForAdmin {
    type Id;

    fn verify_adm(self, auth: AuthAdmin) -> Result<Self::Id, StatusCode>;
}

#[cfg(feature = "server")]
pub trait VerifyIdsForAdmin {
    type Id;

    fn verify_adm(self, auth: AuthAdmin) -> Result<Vec<Self::Id>, StatusCode>;
}

#[cfg(feature = "server")]
pub trait VerifyIdUnchecked {
    type Id;

    fn verify_unchecked(self) -> Result<Self::Id, StatusCode>;
}

#[cfg(feature = "server")]
pub trait VerifyForUserWithDb {
    type Entity;

    fn verify_user(self, auth: AuthUser, db: &mut PgConnection)
        -> Result<Self::Entity, StatusCode>;
}

#[cfg(feature = "server")]
pub trait VerifyMultipleForUserWithDb {
    type Entity;

    fn verify_user(
        self,
        auth: AuthUser,
        db: &mut PgConnection,
    ) -> Result<Vec<Self::Entity>, StatusCode>;
}

#[cfg(feature = "server")]
pub trait VerifyForUserWithoutDb {
    type Entity;

    fn verify_user_without_db(self, auth: AuthUser) -> Result<Self::Entity, StatusCode>;
}

#[cfg(feature = "server")]
pub trait VerifyMultipleForUserWithoutDb {
    type Entity;

    fn verify_user_without_db(self, auth: AuthUser) -> Result<Vec<Self::Entity>, StatusCode>;
}

#[cfg(feature = "server")]
pub trait VerifyForUserOrAPWithDb {
    type Entity;

    fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Self::Entity, StatusCode>;
}

#[cfg(feature = "server")]
pub trait VerifyMultipleForUserOrAPWithDb {
    type Entity;

    fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Vec<Self::Entity>, StatusCode>;
}

#[cfg(feature = "server")]
pub trait VerifyForUserOrAPCreate {
    type Entity;

    fn verify_user_ap_create(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Self::Entity, StatusCode>;
}

#[cfg(feature = "server")]
pub trait VerifyMultipleForUserOrAPCreate {
    type Entity;

    fn verify_user_ap_create(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Vec<Self::Entity>, StatusCode>;
}

#[cfg(feature = "server")]
pub trait VerifyForUserOrAPWithoutDb {
    type Entity;

    fn verify_user_ap_without_db(self, auth: AuthUserOrAP) -> Result<Self::Entity, StatusCode>;
}

#[cfg(feature = "server")]
pub trait VerifyMultipleForUserOrAPWithoutDb {
    type Entity;

    fn verify_user_ap_without_db(self, auth: AuthUserOrAP)
        -> Result<Vec<Self::Entity>, StatusCode>;
}

#[cfg(feature = "server")]
pub trait VerifyForActionProviderWithDb {
    type Entity;

    fn verify_ap(self, auth: AuthAP, db: &mut PgConnection) -> Result<Self::Entity, StatusCode>;
}

#[cfg(feature = "server")]
pub trait VerifyForActionProviderWithoutDb {
    type Entity;

    fn verify_ap_without_db(self, auth: AuthAP) -> Result<Self::Entity, StatusCode>;
}

#[cfg(feature = "server")]
pub trait VerifyMultipleForActionProviderWithoutDb {
    type Entity;

    fn verify_ap_without_db(self, auth: AuthAP) -> Result<Vec<Self::Entity>, StatusCode>;
}

#[cfg(feature = "server")]
pub trait VerifyForAdminWithoutDb {
    type Entity;

    fn verify_adm(self, auth: AuthAdmin) -> Result<Self::Entity, StatusCode>;
}

#[cfg(feature = "server")]
pub trait VerifyMultipleForAdminWithoutDb {
    type Entity;

    fn verify_adm(self, auth: AuthAdmin) -> Result<Vec<Self::Entity>, StatusCode>;
}

#[cfg(feature = "server")]
pub trait VerifyUnchecked {
    type Entity;

    fn verify_unchecked(self) -> Result<Self::Entity, StatusCode>;
}
