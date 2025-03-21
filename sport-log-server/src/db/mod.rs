use argon2::Argon2;
#[cfg(test)]
use argon2::{Algorithm, Params, Version};
use async_trait::async_trait;
use axum::http::StatusCode;
use chrono::{DateTime, Utc};
use diesel::{Column, QueryResult, Table};
use diesel_async::AsyncPgConnection;
use serde::Deserialize;
use sport_log_types::{ActionProviderId, Epoch, UserId};

mod account;
mod action;
mod admin;
mod cardio;
mod diary_wod;
mod metcon;
mod movement;
mod platform;
mod strength;
mod user;

pub use account::*;
pub use action::*;
pub use admin::*;
pub use cardio::*;
pub use diary_wod::*;
pub use metcon::*;
pub use movement::*;
pub use platform::*;
pub use strength::*;
pub use user::*;

use crate::auth::*;

pub fn build_hasher() -> Argon2<'static> {
    #[cfg(not(test))]
    return Argon2::default();

    // speed up hashing for tests
    #[cfg(test)]
    return Argon2::new(
        Algorithm::Argon2id,
        Version::V0x13,
        Params::new(
            Params::MIN_M_COST,
            Params::MIN_P_COST,
            Params::MIN_P_COST,
            None,
        )
        .unwrap_or_default(),
    );
}

/// Wrapper around incoming json data for which the access permissions for the
/// [`AuthUserOrAP`], [`AuthAP`] or [`AuthAdmin`] have not been checked.
///
/// The data can be retrieved by using the appropriate verification function.
#[derive(Debug, Deserialize)]
#[serde(transparent)]
pub struct Unverified<T>(pub(super) T);

/// Wrapper around an incoming id for which the access permissions for the
/// [`AuthUserOrAP`], [`AuthAP`] or [`AuthAdmin`] have not been checked.
///
/// The id can be retrieved by using the appropriate verification function.
#[derive(Debug, Clone, Deserialize)]
#[serde(transparent)]
pub struct UnverifiedId<I>(pub(super) I);

/// Wrapper around multiple incoming ids for which the access permissions for
/// the [`AuthUserOrAP`], [`AuthAP`] or [`AuthAdmin`] have not been checked.
///
/// The ids type can be retrieved by using the appropriate verification
/// function.
#[derive(Debug, Clone, Deserialize)]
#[serde(transparent)]
pub struct UnverifiedIds<I>(pub(super) Vec<I>);

#[derive(Debug, Clone, Deserialize)]
pub enum Timespan {
    StartEnd(DateTime<Utc>, DateTime<Utc>),
    Start(DateTime<Utc>),
    End(DateTime<Utc>),
    All,
}

pub trait Db {
    type Id;
    type Type;
    type Table: Table;

    fn table() -> Self::Table;
    fn id_column() -> <Self::Table as Table>::PrimaryKey;
}

pub trait DbWithUserId: Db {
    type UserIdColumn: Column;

    fn user_id_column() -> Self::UserIdColumn;
}

pub trait DbWithApId: Db {
    type ApIdColumn: Column;

    fn ap_id_column() -> Self::ApIdColumn;
}

pub trait DbWithDateTime: Db {
    type DateTimeColumn: Column;

    fn datetime_column() -> Self::DateTimeColumn;
}

pub trait ModifiableDb: Db {
    type EpochColumn: Column;

    fn epoch_column() -> Self::EpochColumn;
}

/// A type for which a new database entry can be created.
#[async_trait]
pub trait Create: Db {
    async fn create(value: &Self::Type, db: &mut AsyncPgConnection) -> QueryResult<usize>;

    async fn create_multiple(
        values: &[Self::Type],
        db: &mut AsyncPgConnection,
    ) -> QueryResult<usize>;
}

/// A type for which an entry can be retrieved by id from the database.
#[async_trait]
pub trait GetById: Db {
    async fn get_by_id(id: Self::Id, db: &mut AsyncPgConnection) -> QueryResult<Self::Type>;
}

/// A type for which entries can be retrieved by user from the database.
#[async_trait]
pub trait GetByUser: Db {
    async fn get_by_user(
        user_id: UserId,
        db: &mut AsyncPgConnection,
    ) -> QueryResult<Vec<Self::Type>>;
}

/// A type for which entries can be retrieved by user and the timespan from the
/// database.
#[async_trait]
pub trait GetByUserTimespan: Db {
    async fn get_by_user_and_timespan(
        user_id: UserId,
        timespan: Timespan,
        db: &mut AsyncPgConnection,
    ) -> QueryResult<Vec<Self::Type>>;
}

/// A type for which entries can be retrieved by user and the epoch of the
/// last synchronization from the database.
#[async_trait]
pub trait GetByUserAndEpoch: Db {
    async fn get_by_user_and_epoch(
        user_id: UserId,
        epoch: Epoch,
        db: &mut AsyncPgConnection,
    ) -> QueryResult<Vec<Self::Type>>;
}

/// A type for which entries can be retrieved by the epoch of the last
/// synchronization from the database.
#[async_trait]
pub trait GetByEpoch: Db {
    async fn get_by_epoch(epoch: Epoch, db: &mut AsyncPgConnection)
    -> QueryResult<Vec<Self::Type>>;
}

/// A type for which all entries can be retrieved from the database.
#[async_trait]
pub trait GetAll: Db {
    async fn get_all(db: &mut AsyncPgConnection) -> QueryResult<Vec<Self::Type>>;
}

/// A type which can be used to update an entry in the database.
#[async_trait]
pub trait Update: Db {
    async fn update(value: &Self::Type, db: &mut AsyncPgConnection) -> QueryResult<usize>;

    async fn update_multiple(
        values: &[Self::Type],
        db: &mut AsyncPgConnection,
    ) -> QueryResult<usize>;
}

/// A type for which the maximum epoch of a user can be retrieved.
#[async_trait]
pub trait GetEpochByUser: ModifiableDb {
    async fn get_epoch_by_user(user_id: UserId, db: &mut AsyncPgConnection) -> QueryResult<Epoch>;
}

/// A type for which the maximum epoch of a user can be retrieved.
#[async_trait]
pub trait GetEpochByUserOptional: ModifiableDb {
    async fn get_epoch_by_user_optional(
        user_id: UserId,
        db: &mut AsyncPgConnection,
    ) -> QueryResult<Epoch>;
}

/// A type for which the maximum epoch of a user can be retrieved.
#[async_trait]
pub trait GetEpoch: ModifiableDb {
    async fn get_epoch(db: &mut AsyncPgConnection) -> QueryResult<Epoch>;
}

/// A type which can be checked if it belongs to a User.
#[async_trait]
pub trait CheckUserId: Db {
    /// Check if the entry with id `id` in the database belongs to the
    /// [`User`](sport_log_types::User) with `user_id`.
    async fn check_user_id(
        id: Self::Id,
        user_id: UserId,
        db: &mut AsyncPgConnection,
    ) -> QueryResult<bool>;

    /// Check if the entries with an id in `ids` in the database belong to the
    /// [`User`](sport_log_types::User) with `user_id`.
    async fn check_user_ids(
        ids: &[Self::Id],
        user_id: UserId,
        db: &mut AsyncPgConnection,
    ) -> QueryResult<bool>;
}

/// A type which can be checked if it belongs to a User or is public.
#[async_trait]
pub trait CheckOptionalUserId: Db {
    /// Check if the entry with id `id` in the database belongs to the
    /// [`User`](sport_log_types::User) with `user_id` or is public (`user_id`
    /// is None).
    async fn check_optional_user_id(
        id: Self::Id,
        user_id: UserId,
        db: &mut AsyncPgConnection,
    ) -> QueryResult<bool>;
}

/// A type which can be checked if it belongs to an ActionProvider.
#[async_trait]
pub trait CheckAPId: Db {
    /// Check if the entry with id `id` in the database belongs to the
    /// [`ActionProvider`](sport_log_types::ActionProvider) with `ap_id`.
    async fn check_ap_id(
        id: Self::Id,
        ap_id: ActionProviderId,
        db: &mut AsyncPgConnection,
    ) -> QueryResult<bool>;

    /// Check if the entries with an id in `ids` in the database belong to the
    /// [`ActionProvider`](sport_log_types::ActionProvider) with `ap_id`.
    async fn check_ap_ids(
        ids: &[Self::Id],
        ap_id: ActionProviderId,
        db: &mut AsyncPgConnection,
    ) -> QueryResult<bool>;
}

#[async_trait]
pub trait VerifyForUserGet {
    type Id;

    async fn verify_user_get(
        self,
        auth: AuthUser,
        db: &mut AsyncPgConnection,
    ) -> Result<Self::Id, StatusCode>;
}

#[async_trait]
pub trait VerifyForUserOrAPGet {
    type Id;

    async fn verify_user_ap_get(
        self,
        auth: AuthUserOrAP,
        db: &mut AsyncPgConnection,
    ) -> Result<Self::Id, StatusCode>;
}

#[async_trait]
pub trait VerifyForActionProviderGet {
    type Id;

    async fn verify_ap_get(
        self,
        auth: AuthAP,
        db: &mut AsyncPgConnection,
    ) -> Result<Self::Id, StatusCode>;
}

#[async_trait]
pub trait VerifyForActionProviderDisable {
    type Id;

    async fn verify_ap_disable(
        self,
        auth: AuthAP,
        db: &mut AsyncPgConnection,
    ) -> Result<Vec<Self::Id>, StatusCode>;
}

pub trait VerifyForAdminGet {
    type Id;

    fn verify_adm_get(self, auth: AuthAdmin) -> Result<Self::Id, StatusCode>;
}

pub trait VerifyForAdminDelete {
    type Id;

    fn verify_adm_delete(self, auth: AuthAdmin) -> Result<Vec<Self::Id>, StatusCode>;
}

pub trait VerifyUncheckedGet {
    type Id;

    fn verify_unchecked_get(self) -> Result<Self::Id, StatusCode>;
}

#[async_trait]
pub trait VerifyForUserUpdate {
    type Type;

    async fn verify_user_update(
        self,
        auth: AuthUser,
        db: &mut AsyncPgConnection,
    ) -> Result<Self::Type, StatusCode>;
}

#[async_trait]
pub trait VerifyMultipleForUserUpdate {
    type Type;

    async fn verify_user_update(
        self,
        auth: AuthUser,
        db: &mut AsyncPgConnection,
    ) -> Result<Vec<Self::Type>, StatusCode>;
}

pub trait VerifyForUserCreate {
    type Type;

    fn verify_user_create(self, auth: AuthUser) -> Result<Self::Type, StatusCode>;
}

pub trait VerifyMultipleForUserCreate {
    type Type;

    fn verify_user_create(self, auth: AuthUser) -> Result<Vec<Self::Type>, StatusCode>;
}

#[async_trait]
pub trait VerifyForUserOrAPUpdate {
    type Type;

    async fn verify_user_ap_update(
        self,
        auth: AuthUserOrAP,
        db: &mut AsyncPgConnection,
    ) -> Result<Self::Type, StatusCode>;
}

#[async_trait]
pub trait VerifyMultipleForUserOrAPUpdate {
    type Type;

    async fn verify_user_ap_update(
        self,
        auth: AuthUserOrAP,
        db: &mut AsyncPgConnection,
    ) -> Result<Vec<Self::Type>, StatusCode>;
}

pub trait VerifyForUserOrAPCreate {
    type Type;

    fn verify_user_ap_create(self, auth: AuthUserOrAP) -> Result<Self::Type, StatusCode>;
}

pub trait VerifyMultipleForUserOrAPCreate {
    type Type;

    fn verify_user_ap_create(self, auth: AuthUserOrAP) -> Result<Vec<Self::Type>, StatusCode>;
}

#[async_trait]
pub trait VerifyForActionProviderUpdate {
    type Type;

    async fn verify_ap_update(
        self,
        auth: AuthAP,
        db: &mut AsyncPgConnection,
    ) -> Result<Self::Type, StatusCode>;
}

#[async_trait]
pub trait VerifyMultipleForActionProviderUpdate {
    type Type;

    async fn verify_ap_update(
        self,
        auth: AuthAP,
        db: &mut AsyncPgConnection,
    ) -> Result<Vec<Self::Type>, StatusCode>;
}

pub trait VerifyForActionProviderCreate {
    type Type;

    fn verify_ap_create(self, auth: AuthAP) -> Result<Self::Type, StatusCode>;
}

pub trait VerifyMultipleForActionProviderCreate {
    type Type;

    fn verify_ap_create(self, auth: AuthAP) -> Result<Vec<Self::Type>, StatusCode>;
}

pub trait VerifyForAdmin {
    type Type;

    fn verify_adm(self, auth: AuthAdmin) -> Result<Self::Type, StatusCode>;
}

pub trait VerifyMultipleForAdmin {
    type Type;

    fn verify_adm(self, auth: AuthAdmin) -> Result<Vec<Self::Type>, StatusCode>;
}

pub trait VerifyUncheckedCreate {
    type Type;

    fn verify_unchecked_create(self) -> Result<Self::Type, StatusCode>;
}
