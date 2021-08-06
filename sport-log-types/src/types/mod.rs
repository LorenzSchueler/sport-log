#[cfg(feature = "full")]
use diesel::{PgConnection, QueryResult};
#[cfg(feature = "full")]
use rocket::{
    data::{self, FromData},
    http::Status,
    outcome::Outcome,
    serde::json::{self, Json},
    Data, Request,
};
#[cfg(feature = "full")]
use serde::Deserialize;

mod account;
mod action;
mod activity;
#[cfg(feature = "full")]
mod admin;
#[cfg(feature = "full")]
mod auth;
mod cardio;
#[cfg(feature = "full")]
mod config;
#[cfg(feature = "full")]
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
#[cfg(feature = "full")]
pub use admin::*;
#[cfg(feature = "full")]
pub use auth::*;
pub use cardio::*;
#[cfg(feature = "full")]
pub use config::*;
#[cfg(feature = "full")]
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
#[cfg(feature = "full")]
#[derive(Debug)]
pub struct Unverified<T>(Json<T>);

#[cfg(feature = "full")]
#[rocket::async_trait]
impl<'r, T: Deserialize<'r>> FromData<'r> for Unverified<T> {
    type Error = json::Error<'r>;

    async fn from_data(req: &'r Request<'_>, data: Data<'r>) -> data::Outcome<'r, Self> {
        Json::<T>::from_data(req, data)
            .await
            .and_then(|data| Outcome::Success(Self(data)))
    }
}

/// Indicated that the type can be build from an [i32].
pub trait FromI32 {
    fn from_i32(value: i32) -> Self;
}

/// Wrapper around Id types for which the access permissions for the [AuthUserOrAP], [AuthAP] or [AuthAdmin] have not been checked.
///
/// The Id type can be retrieved by using the appropriate verification function.
#[cfg(feature = "full")]
#[derive(Debug, Clone)]
pub struct UnverifiedId<I>(I);

#[cfg(feature = "full")]
impl<'v, I: FromI32> rocket::request::FromParam<'v> for UnverifiedId<I> {
    type Error = &'v str;

    fn from_param(param: &'v str) -> Result<Self, Self::Error> {
        Ok(Self(I::from_i32(i32::from_param(param)?)))
    }
}

/// Wrapper around Id types for which the access permissions for the [AuthUserOrAP], [AuthAP] or [AuthAdmin] have not been checked.
///
/// The Id type can be retrieved by using the appropriate verification function.
#[cfg(feature = "full")]
#[derive(Debug, Clone)]
pub struct UnverifiedIds<I>(Vec<I>);

#[cfg(feature = "full")]
#[rocket::async_trait]
impl<'r, I: FromI32 + Deserialize<'r>> FromData<'r> for UnverifiedIds<I> {
    type Error = json::Error<'r>;

    async fn from_data(req: &'r Request<'_>, data: Data<'r>) -> data::Outcome<'r, Self> {
        <rocket::serde::json::Json<Vec<i32>> as FromData>::from_data(req, data)
            .await
            .and_then(|ids_json| {
                Outcome::Success(Self(
                    ids_json.into_inner().into_iter().map(I::from_i32).collect(),
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
#[cfg(feature = "full")]
pub trait Create {
    type New;

    fn create(entity: Self::New, conn: &PgConnection) -> QueryResult<Self>
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
#[cfg(feature = "full")]
pub trait CreateMultiple {
    type New;

    fn create_multiple(enteties: Vec<Self::New>, conn: &PgConnection) -> QueryResult<Vec<Self>>
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
#[cfg(feature = "full")]
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
#[cfg(feature = "full")]
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
#[cfg(feature = "full")]
pub trait GetByUser {
    fn get_by_user(user_id: UserId, conn: &PgConnection) -> QueryResult<Vec<Self>>
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
#[cfg(feature = "full")]
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
#[cfg(feature = "full")]
pub trait Update {
    fn update(entity: Self, conn: &PgConnection) -> QueryResult<Self>
    where
        Self: Sized;
}

/// A type for which an entry can be deleted by id from the database.
///
/// ### Deriving
///
/// This trait can be automatically derived by adding `#[derive(Delete)]` to your struct.
///
/// For restrictions on the types for derive to work please see [sport_log_types_derive::Delete].
#[cfg(feature = "full")]
pub trait Delete {
    type Id;

    fn delete(id: Self::Id, conn: &PgConnection) -> QueryResult<usize>;
}

/// A type for which entries can be deleted by id from the database.
///
/// ### Deriving
///
/// This trait can be automatically derived by adding `#[derive(DeleteMultiple)]` to your struct.
///
/// For restrictions on the types for derive to work please see [sport_log_types_derive::DeleteMultiple].
#[cfg(feature = "full")]
pub trait DeleteMultiple {
    type Id;

    fn delete_multiple(ids: Vec<Self::Id>, conn: &PgConnection) -> QueryResult<usize>;
}

#[cfg(feature = "full")]
pub trait VerifyIdForUser {
    type Id;

    fn verify(self, auth: &AuthUser, conn: &PgConnection) -> Result<Self::Id, Status>;
}

#[cfg(feature = "full")]
pub trait VerifyIdsForUser {
    type Id;

    fn verify(self, auth: &AuthUser, conn: &PgConnection) -> Result<Vec<Self::Id>, Status>;
}

#[cfg(feature = "full")]
pub trait VerifyIdForUserUnchecked {
    type Id;

    fn verify_unchecked(self, auth: &AuthUser) -> Result<Self::Id, Status>;
}

#[cfg(feature = "full")]
pub trait VerifyIdForUserOrAP {
    type Id;

    fn verify(self, auth: &AuthUserOrAP, conn: &PgConnection) -> Result<Self::Id, Status>;
}

#[cfg(feature = "full")]
pub trait VerifyIdsForUserOrAP {
    type Id;

    fn verify(self, auth: &AuthUserOrAP, conn: &PgConnection) -> Result<Vec<Self::Id>, Status>;
}

#[cfg(feature = "full")]
pub trait VerifyIdForUserOrAPUnchecked {
    type Id;

    fn verify_unchecked(self, auth: &AuthUserOrAP) -> Result<Self::Id, Status>;
}

#[cfg(feature = "full")]
pub trait VerifyIdForActionProvider {
    type Id;

    fn verify_ap(self, auth: &AuthAP, conn: &PgConnection) -> Result<Self::Id, Status>;
}

#[cfg(feature = "full")]
pub trait VerifyMultipleIdForActionProvider {
    type Id;

    fn verify_ap(self, auth: &AuthAP, conn: &PgConnection) -> Result<Vec<Self::Id>, Status>;
}

#[cfg(feature = "full")]
pub trait VerifyIdForAdmin {
    type Id;

    fn verify_adm(self, auth: &AuthAdmin) -> Result<Self::Id, Status>;
}

#[cfg(feature = "full")]
pub trait VerifyMultipleIdForAdmin {
    type Id;

    fn verify_adm(self, auth: &AuthAdmin) -> Result<Vec<Self::Id>, Status>;
}

#[cfg(feature = "full")]
pub trait VerifyForUserWithDb {
    type Entity;

    fn verify(self, auth: &AuthUser, conn: &PgConnection) -> Result<Self::Entity, Status>;
}

#[cfg(feature = "full")]
pub trait VerifyMultipleForUserWithDb {
    type Entity;

    fn verify(self, auth: &AuthUser, conn: &PgConnection) -> Result<Vec<Self::Entity>, Status>;
}

#[cfg(feature = "full")]
pub trait VerifyForUserWithoutDb {
    type Entity;

    fn verify(self, auth: &AuthUser) -> Result<Self::Entity, Status>;
}

#[cfg(feature = "full")]
pub trait VerifyMultipleForUserWithoutDb {
    type Entity;

    fn verify(self, auth: &AuthUser) -> Result<Vec<Self::Entity>, Status>;
}

#[cfg(feature = "full")]
pub trait VerifyForUserUnchecked {
    type Entity;

    fn verify_unchecked(self) -> Result<Self::Entity, Status>;
}

#[cfg(feature = "full")]
pub trait VerifyForUserOrAPWithDb {
    type Entity;

    fn verify(self, auth: &AuthUserOrAP, conn: &PgConnection) -> Result<Self::Entity, Status>;
}

#[cfg(feature = "full")]
pub trait VerifyMultipleForUserOrAPWithDb {
    type Entity;

    fn verify(self, auth: &AuthUserOrAP, conn: &PgConnection) -> Result<Vec<Self::Entity>, Status>;
}

#[cfg(feature = "full")]
pub trait VerifyForUserOrAPWithoutDb {
    type Entity;

    fn verify(self, auth: &AuthUserOrAP) -> Result<Self::Entity, Status>;
}

#[cfg(feature = "full")]
pub trait VerifyMultipleForUserOrAPWithoutDb {
    type Entity;

    fn verify(self, auth: &AuthUserOrAP) -> Result<Vec<Self::Entity>, Status>;
}

#[cfg(feature = "full")]
pub trait VerifyForActionProviderWithDb {
    type Entity;

    fn verify_ap(self, auth: &AuthAP, conn: &PgConnection) -> Result<Self::Entity, Status>;
}

#[cfg(feature = "full")]
pub trait VerifyForActionProviderWithoutDb {
    type Entity;

    fn verify_ap(self, auth: &AuthAP) -> Result<Self::Entity, Status>;
}

#[cfg(feature = "full")]
pub trait VerifyForActionProviderUnchecked {
    type Entity;

    fn verify_ap_unchecked(self) -> Result<Self::Entity, Status>;
}

#[cfg(feature = "full")]
pub trait VerifyForAdminWithoutDb {
    type Entity;

    fn verify_adm(self, auth: &AuthAdmin) -> Result<Self::Entity, Status>;
}

#[cfg(feature = "full")]
pub trait VerifyMultipleForAdminWithoutDb {
    type Entity;

    fn verify_adm(self, auth: &AuthAdmin) -> Result<Vec<Self::Entity>, Status>;
}
