use std::ops::Deref;

use axum::{
    async_trait,
    extract::{FromRef, FromRequestParts, State},
    headers::{authorization::Basic, Authorization},
    http::{request::Parts, StatusCode},
    TypedHeader,
};
use sport_log_types::{ActionProviderId, UserId};

use crate::{
    db::{ActionProviderDb, AdminDb, UserDb},
    error::HandlerError,
    AppState, Config,
};

/// [AuthUser] is used as a request guard to authenticate a user.
///
/// For the creation of an [AuthUser] the username and password have to be transmitted via HTTP basic auth.
///
/// The admin can also use endpoints with an [AuthUser] as request guard.
///
/// In order to do so, the username has to be set to `admin$id$<user_id>`
/// and the password must be the `admin_password` as configured in `sport-log-server.toml`.
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

        let admin_password = &config.admin_password;

        match UserDb::auth(username, password, &mut db) {
            Ok(id) => Ok(AuthUser(id)),
            Err(_) => {
                if let Some((name, Ok(user_id))) = username
                    .split_once("$id$")
                    .map(|(name, id)| (name, id.parse().map(UserId)))
                {
                    if AdminDb::auth(name, password, admin_password).is_ok() {
                        return Ok(AuthUser(user_id));
                    }
                };
                Err(StatusCode::UNAUTHORIZED.into())
            }
        }
    }
}

/// [AuthUserOrAP] is used as a request guard to authenticate a user.
///
/// For the creation of an [AuthUserOrAP] the username and password have to be transmitted via HTTP basic auth.
///
/// [ActionProvider](sport_log_types::ActionProvider) can also use endpoints with an [AuthUserOrAP] as request guard
/// if the user has an enabled [ActionEvent](sport_log_types::ActionEvent) for an [Action](sport_log_types::Action) of this [ActionProvider](sport_log_types::ActionProvider).
///
/// In this case the username has to be set to `<ap_name>$id$<user_id>` and the password is the password of the [ActionProvider](sport_log_types::ActionProvider).
///
/// The admin can also use endpoints with an [AuthUserOrAP] as request guard.
///
/// In order to do so, the username has to be set to `admin$id$<user_id>`
/// and the password must be the `admin_password` as configured in `sport-log-server.toml`.
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

        let admin_password = &config.admin_password;

        match UserDb::auth(username, password, &mut db) {
            Ok(id) => Ok(AuthUserOrAP(id)),
            Err(_) => {
                if let Some((name, Ok(user_id))) = username
                    .split_once("$id$")
                    .map(|(name, id)| (name, id.parse().map(UserId)))
                {
                    match ActionProviderDb::auth_as_user(name, password, user_id, &mut db) {
                        Ok(AuthApForUser::Allowed(_)) => Ok(AuthUserOrAP(user_id)),
                        Ok(AuthApForUser::Forbidden) => Err(StatusCode::FORBIDDEN.into()),
                        Err(_) => match AdminDb::auth(name, password, admin_password) {
                            Ok(()) => Ok(AuthUserOrAP(user_id)),
                            Err(_) => Err(StatusCode::UNAUTHORIZED.into()),
                        },
                    }
                } else {
                    Err(StatusCode::UNAUTHORIZED.into())
                }
            }
        }
    }
}

pub enum AuthApForUser {
    Allowed(ActionProviderId),
    Forbidden,
}

/// [AuthAP] is used as a request guard to authenticate an action provider.
///
/// For the creation of an [AuthAP] the username and password have to be transmitted via HTTP basic auth.
///
/// The admin can also use endpoints with an [AuthAP] as request guard.
///
/// In order to do so, the username has to be set to `admin$id$<action_provider_id>`
/// and the password must be the `admin_password` as configured in `sport-log-server.toml`.
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

        let admin_password = &config.admin_password;

        match ActionProviderDb::auth(username, password, &mut db) {
            Ok(id) => Ok(AuthAP(id)),
            Err(_) => {
                if let Some((name, Ok(id))) = username
                    .split_once("$id$")
                    .map(|(name, id)| (name, id.parse()))
                {
                    if AdminDb::auth(name, password, admin_password).is_ok() {
                        return Ok(AuthAP(ActionProviderId(id)));
                    }
                };
                Err(StatusCode::UNAUTHORIZED.into())
            }
        }
    }
}

/// [AuthAdmin] is used as a request guard to authenticate the admin.
///
/// For the creation of an [AuthAdmin] the username and password have to be transmitted via HTTP basic auth.
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
