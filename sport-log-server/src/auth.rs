use std::ops::Deref;

use axum::{
    async_trait,
    extract::{FromRef, FromRequestParts, State},
    http::{request::Parts, StatusCode},
};
use axum_extra::{
    headers::{authorization::Basic, Authorization},
    TypedHeader,
};
use sport_log_types::{ActionProviderId, UserId, ID_HEADER};

use crate::{
    db::{ActionProviderDb, AdminDb, UserDb},
    error::HandlerError,
    AppState, Config,
};

/// [`AuthUser`] is used as a request guard to authenticate a user.
///
/// For the creation of an [`AuthUser`] the username and password have to be transmitted via HTTP basic auth.
///
/// The admin can also use endpoints with an [`AuthUser`] as request guard.
///
/// In order to do so, the username must be `admin`, the password must be the `admin_password` as configured in `sport-log-server.toml`
/// and a `id` header must be preset that is set to the id of the user the admin wants to authenticate as.
#[derive(Debug, Clone, Copy)]
pub struct AuthUser(UserId);

impl Deref for AuthUser {
    type Target = UserId;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

#[async_trait]
impl<S> FromRequestParts<S> for AuthUser
where
    S: Send + Sync,
    AppState: FromRef<S>,
{
    type Rejection = HandlerError;

    async fn from_request_parts(parts: &mut Parts, state: &S) -> Result<Self, Self::Rejection> {
        let TypedHeader(auth) =
            TypedHeader::<Authorization<Basic>>::from_request_parts(parts, state).await?;
        let username = auth.username();
        let password = auth.password();

        let State(AppState { config, db_pool }) =
            State::<AppState>::from_request_parts(parts, state).await?;

        let mut db = db_pool.get()?;

        if let Ok(id) = UserDb::auth(username, password, &mut db) {
            return Ok(Self(id));
        }

        let user_id = parse_id_header(parts, UserId)?;
        let admin_password = &config.admin_password;
        if AdminDb::auth(username, password, admin_password).is_ok() {
            return Ok(Self(user_id));
        }
        Err(StatusCode::UNAUTHORIZED.into())
    }
}

/// [`AuthUserOrAP`] is used as a request guard to authenticate a user.
///
/// For the creation of an [`AuthUserOrAP`] the username and password have to be transmitted via HTTP basic auth.
///
/// [`ActionProvider`](sport_log_types::ActionProvider) can also use endpoints with an [`AuthUserOrAP`] as request guard
/// if the user has an enabled [`ActionEvent`](sport_log_types::ActionEvent) for an [`Action`](sport_log_types::Action) of this [`ActionProvider`](sport_log_types::ActionProvider).
///
/// In order to do so, the username and password must the ones from the [`ActionProvider`](sport_log_types::ActionProvider).
/// and a `id` header must be preset that is set to the id of the user the action provider wants to authenticate as.
///
/// The admin can also use endpoints with an [`AuthUserOrAP`] as request guard.
///
/// In order to do so, the username must be `admin`, the password must be the `admin_password` as configured in `sport-log-server.toml`
/// and a `id` header must be preset that is set to the id of the user the admin wants to authenticate as.
#[derive(Debug, Clone, Copy)]
pub struct AuthUserOrAP(UserId);

impl Deref for AuthUserOrAP {
    type Target = UserId;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

#[async_trait]
impl<S> FromRequestParts<S> for AuthUserOrAP
where
    S: Send + Sync,
    AppState: FromRef<S>,
{
    type Rejection = HandlerError;

    async fn from_request_parts(parts: &mut Parts, state: &S) -> Result<Self, Self::Rejection> {
        let TypedHeader(auth) =
            TypedHeader::<Authorization<Basic>>::from_request_parts(parts, state).await?;
        let username = auth.username();
        let password = auth.password();

        let State(AppState { config, db_pool }) =
            State::<AppState>::from_request_parts(parts, state).await?;

        let mut db = db_pool.get()?;

        if let Ok(id) = UserDb::auth(username, password, &mut db) {
            return Ok(Self(id));
        }

        let user_id = parse_id_header(parts, UserId)?;
        if let Ok(auth) = ActionProviderDb::auth_as_user(username, password, user_id, &mut db) {
            match auth {
                AuthApForUser::Allowed(_) => return Ok(Self(user_id)),
                AuthApForUser::Forbidden => return Err(StatusCode::FORBIDDEN.into()),
            }
        }

        let admin_password = &config.admin_password;
        if AdminDb::auth(username, password, admin_password).is_ok() {
            return Ok(Self(user_id));
        }
        Err(StatusCode::UNAUTHORIZED.into())
    }
}

pub enum AuthApForUser {
    Allowed(ActionProviderId),
    Forbidden,
}

/// [`AuthAP`] is used as a request guard to authenticate an action provider.
///
/// For the creation of an [`AuthAP`] the username and password have to be transmitted via HTTP basic auth.
///
/// The admin can also use endpoints with an [`AuthAP`] as request guard.
///
/// In order to do so, the username must be `admin`, the password must be the `admin_password` as configured in `sport-log-server.toml`
/// and a `id` header must be preset that is set to the id of the action provider the admin wants to authenticate as.
#[derive(Debug, Clone, Copy)]
pub struct AuthAP(ActionProviderId);

impl Deref for AuthAP {
    type Target = ActionProviderId;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

#[async_trait]
impl<S> FromRequestParts<S> for AuthAP
where
    S: Send + Sync,
    AppState: FromRef<S>,
{
    type Rejection = HandlerError;

    async fn from_request_parts(parts: &mut Parts, state: &S) -> Result<Self, Self::Rejection> {
        let TypedHeader(auth) =
            TypedHeader::<Authorization<Basic>>::from_request_parts(parts, state).await?;
        let username = auth.username();
        let password = auth.password();

        let State(AppState { config, db_pool }) =
            State::<AppState>::from_request_parts(parts, state).await?;

        let mut db = db_pool.get()?;

        if let Ok(id) = ActionProviderDb::auth(username, password, &mut db) {
            return Ok(Self(id));
        }

        let ap_id = parse_id_header(parts, ActionProviderId)?;
        let admin_password = &config.admin_password;
        if AdminDb::auth(username, password, admin_password).is_ok() {
            return Ok(Self(ap_id));
        }
        Err(StatusCode::UNAUTHORIZED.into())
    }
}

/// [`AuthAdmin`] is used as a request guard to authenticate the admin.
///
/// For the creation of an [`AuthAdmin`] the username and password have to be transmitted via HTTP basic auth.
///
/// The username has to be set to `admin` and the password must be the `admin_password` as configured in `sport-log-server.toml`.
#[derive(Debug, Clone, Copy)]
pub struct AuthAdmin;

#[async_trait]
impl<S> FromRequestParts<S> for AuthAdmin
where
    S: Send + Sync,
    &'static Config: FromRef<S>,
{
    type Rejection = HandlerError;

    async fn from_request_parts(parts: &mut Parts, state: &S) -> Result<Self, Self::Rejection> {
        let TypedHeader(auth) =
            TypedHeader::<Authorization<Basic>>::from_request_parts(parts, state).await?;
        let username = auth.username();
        let password = auth.password();

        let State(config) = State::<&Config>::from_request_parts(parts, state).await?;

        let admin_password = &config.admin_password;

        match AdminDb::auth(username, password, admin_password) {
            Ok(_) => Ok(AuthAdmin),
            Err(_) => Err(StatusCode::UNAUTHORIZED.into()),
        }
    }
}

fn parse_id_header<T>(parts: &Parts, builder: fn(i64) -> T) -> Result<T, StatusCode> {
    parts
        .headers
        .get(ID_HEADER)
        .ok_or(StatusCode::UNAUTHORIZED)?
        .to_str()
        .map_err(|_| StatusCode::UNPROCESSABLE_ENTITY)?
        .parse()
        .map(builder)
        .map_err(|_| StatusCode::UNPROCESSABLE_ENTITY)
}
