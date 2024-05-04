use argon2::Argon2;
#[cfg(test)]
use argon2::{Algorithm, Params, Version};
use axum::http::StatusCode;
use chrono::{DateTime, Utc};
use diesel::{Column, PgConnection, QueryResult, Table};
use serde::Deserialize;
use sport_log_types::{ActionProviderId, UserId};

mod account;
mod action;
mod admin;
mod cardio;
mod diary_wod;
mod metcon;
mod movement;
mod platform;
mod sharing;
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
pub use sharing::*;
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
    type LastChangeColumn: Column;
    type DeletedColumn: Column;

    fn last_change_column() -> Self::LastChangeColumn;
    fn deleted_column() -> Self::DeletedColumn;
}

/// A type for which a new database entry can be created.
///
/// ### Deriving
///
/// This trait can be automatically derived by adding `#[derive(Create)]` to
/// your struct.
///
/// For restrictions on the types for derive to work please see
/// [`sport_log_derive::Create`].
pub trait Create: Db {
    fn create(value: &Self::Type, db: &mut PgConnection) -> QueryResult<usize>;

    fn create_multiple(values: &[Self::Type], db: &mut PgConnection) -> QueryResult<usize>;
}

/// A type for which an entry can be retrieved by id from the database.
///
/// ### Deriving
///
/// This trait can be automatically derived by adding `#[derive(GetById)]` to
/// your struct.
///
/// For restrictions on the types for derive to work please see
/// [`sport_log_derive::GetById`].
pub trait GetById: Db {
    fn get_by_id(id: Self::Id, db: &mut PgConnection) -> QueryResult<Self::Type>;
}

/// A type for which entries can be retrieved by user from the database.
///
/// ### Deriving
///
/// This trait can be automatically derived by adding `#[derive(GetByUser)]` to
/// your struct.
///
/// For restrictions on the types for derive to work please see
/// [`sport_log_derive::GetByUser`].
pub trait GetByUser: Db {
    fn get_by_user(user_id: UserId, db: &mut PgConnection) -> QueryResult<Vec<Self::Type>>;
}

/// A type for which entries can be retrieved by user and the timespan from the
/// database.
///
/// ### Deriving
///
/// This trait can be automatically derived by adding
/// `#[derive(GetByUserTimespan)]` to your struct.
///
/// For restrictions on the types for derive to work please see
/// [`sport_log_derive::GetByUserTimespan`].
pub trait GetByUserTimespan: Db {
    fn get_by_user_and_timespan(
        user_id: UserId,
        timespan: Timespan,
        db: &mut PgConnection,
    ) -> QueryResult<Vec<Self::Type>>;
}

/// A type for which entries can be retrieved by user and the timestamp of the
/// last synchronization from the database.
///
/// ### Deriving
///
/// This trait can be automatically derived by adding `#[derive(GetByUserSync)]`
/// to your struct.
///
/// For restrictions on the types for derive to work please see
/// [`sport_log_derive::GetByUserSync`].
pub trait GetByUserSync: Db {
    fn get_by_user_and_last_sync(
        user_id: UserId,
        last_sync: DateTime<Utc>,
        db: &mut PgConnection,
    ) -> QueryResult<Vec<Self::Type>>;
}

/// A type for which entries can be retrieved by the timestamp of the last
/// synchronization from the database.
///
/// ### Deriving
///
/// This trait can be automatically derived by adding `#[derive(GetBySync)]` to
/// your struct.
///
/// For restrictions on the types for derive to work please see
/// [`sport_log_derive::GetBySync`].
pub trait GetBySync: Db {
    fn get_by_last_sync(
        last_sync: DateTime<Utc>,
        db: &mut PgConnection,
    ) -> QueryResult<Vec<Self::Type>>;
}

/// A type for which all entries can be retrieved from the database.
///
/// ### Deriving
///
/// This trait can be automatically derived by adding `#[derive(GetAll)]` to
/// your struct.
///
/// For restrictions on the types for derive to work please see
/// [`sport_log_derive::GetAll`].
pub trait GetAll: Db {
    fn get_all(db: &mut PgConnection) -> QueryResult<Vec<Self::Type>>;
}

/// A type which can be used to update an entry in the database.
///
/// ### Deriving
///
/// This trait can be automatically derived by adding `#[derive(Update)]` to
/// your struct.
///
/// For restrictions on the types for derive to work please see
/// [`sport_log_derive::Update`].
pub trait Update: Db {
    fn update(value: &Self::Type, db: &mut PgConnection) -> QueryResult<usize>;

    fn update_multiple(values: &[Self::Type], db: &mut PgConnection) -> QueryResult<usize>;
}

/// A type for which all soft deleted entities can be hard deleted.
///
/// This is only intended for garbage collection triggered by
/// `sport_log_scheduler`.
///
/// The function [`hard_delete`](HardDelete::hard_delete) will permanently
/// delete all entities that are already soft deleted and which have not been
/// changed since `last_change`.
///
/// ### Deriving
///
/// This trait can be automatically derived by adding `#[derive(HardDelete)]` to
/// your struct.
///
/// For restrictions on the types for derive to work please see
/// [`sport_log_derive::HardDelete`].
pub trait HardDelete: Db {
    fn hard_delete(last_change: DateTime<Utc>, db: &mut PgConnection) -> QueryResult<usize>;
}

/// A type which can be checked if it belongs to a User.
///
/// ### Deriving
///
/// This trait can be automatically derived by adding `#[derive(CheckUserId)]`
/// to your struct if the struct has a field `user_id` of type [`UserId`].
pub trait CheckUserId: Db {
    /// Check if the entry with id `id` in the database belongs to the
    /// [`User`](sport_log_types::User) with `user_id`.
    fn check_user_id(id: Self::Id, user_id: UserId, db: &mut PgConnection) -> QueryResult<bool>;

    /// Check if the entries with an id in `ids` in the database belong to the
    /// [`User`](sport_log_types::User) with `user_id`.
    fn check_user_ids(
        ids: &[Self::Id],
        user_id: UserId,
        db: &mut PgConnection,
    ) -> QueryResult<bool>;
}

/// A type which can be checked if it belongs to a User or is public.
pub trait CheckOptionalUserId: Db {
    /// Check if the entry with id `id` in the database belongs to the
    /// [`User`](sport_log_types::User) with `user_id` or is public (`user_id`
    /// is None).
    fn check_optional_user_id(
        id: Self::Id,
        user_id: UserId,
        db: &mut PgConnection,
    ) -> QueryResult<bool>;
}

pub trait CheckAPId: Db {
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

pub trait VerifyIdForUser {
    type Id;

    fn verify_user(self, auth: AuthUser, db: &mut PgConnection) -> Result<Self::Id, StatusCode>;
}

pub trait VerifyIdForUserOrAP {
    type Id;

    fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Self::Id, StatusCode>;
}

pub trait VerifyIdForActionProvider {
    type Id;

    fn verify_ap(self, auth: AuthAP, db: &mut PgConnection) -> Result<Self::Id, StatusCode>;
}

pub trait VerifyIdsForActionProvider {
    type Id;

    fn verify_ap(self, auth: AuthAP, db: &mut PgConnection) -> Result<Vec<Self::Id>, StatusCode>;
}

pub trait VerifyIdForAdmin {
    type Id;

    fn verify_adm(self, auth: AuthAdmin) -> Result<Self::Id, StatusCode>;
}

pub trait VerifyIdsForAdmin {
    type Id;

    fn verify_adm(self, auth: AuthAdmin) -> Result<Vec<Self::Id>, StatusCode>;
}

pub trait VerifyIdUnchecked {
    type Id;

    fn verify_unchecked(self) -> Result<Self::Id, StatusCode>;
}

pub trait VerifyForUserWithDb {
    type Type;

    fn verify_user(self, auth: AuthUser, db: &mut PgConnection) -> Result<Self::Type, StatusCode>;
}

pub trait VerifyMultipleForUserWithDb {
    type Type;

    fn verify_user(
        self,
        auth: AuthUser,
        db: &mut PgConnection,
    ) -> Result<Vec<Self::Type>, StatusCode>;
}

pub trait VerifyForUserWithoutDb {
    type Type;

    fn verify_user_without_db(self, auth: AuthUser) -> Result<Self::Type, StatusCode>;
}

pub trait VerifyMultipleForUserWithoutDb {
    type Type;

    fn verify_user_without_db(self, auth: AuthUser) -> Result<Vec<Self::Type>, StatusCode>;
}

pub trait VerifyForUserOrAPWithDb {
    type Type;

    fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Self::Type, StatusCode>;
}

pub trait VerifyMultipleForUserOrAPWithDb {
    type Type;

    fn verify_user_ap(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Vec<Self::Type>, StatusCode>;
}

pub trait VerifyForUserOrAPCreate {
    type Type;

    fn verify_user_ap_create(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Self::Type, StatusCode>;
}

pub trait VerifyMultipleForUserOrAPCreate {
    type Type;

    fn verify_user_ap_create(
        self,
        auth: AuthUserOrAP,
        db: &mut PgConnection,
    ) -> Result<Vec<Self::Type>, StatusCode>;
}

pub trait VerifyForUserOrAPWithoutDb {
    type Type;

    fn verify_user_ap_without_db(self, auth: AuthUserOrAP) -> Result<Self::Type, StatusCode>;
}

pub trait VerifyMultipleForUserOrAPWithoutDb {
    type Type;

    fn verify_user_ap_without_db(self, auth: AuthUserOrAP) -> Result<Vec<Self::Type>, StatusCode>;
}

pub trait VerifyForActionProviderWithoutDb {
    type Type;

    fn verify_ap_without_db(self, auth: AuthAP) -> Result<Self::Type, StatusCode>;
}

pub trait VerifyMultipleForActionProviderWithoutDb {
    type Type;

    fn verify_ap_without_db(self, auth: AuthAP) -> Result<Vec<Self::Type>, StatusCode>;
}

pub trait VerifyForAdminWithoutDb {
    type Type;

    fn verify_adm(self, auth: AuthAdmin) -> Result<Self::Type, StatusCode>;
}

pub trait VerifyMultipleForAdminWithoutDb {
    type Type;

    fn verify_adm(self, auth: AuthAdmin) -> Result<Vec<Self::Type>, StatusCode>;
}

pub trait VerifyUnchecked {
    type Type;

    fn verify_unchecked(self) -> Result<Self::Type, StatusCode>;
}
