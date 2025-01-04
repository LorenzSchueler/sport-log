use axum::{
    extract::{FromRef, FromRequestParts},
    http::{request::Parts, StatusCode},
};
use diesel_async::{
    pooled_connection::deadpool::{Object, Pool},
    AsyncPgConnection,
};

use crate::Config;

#[derive(Clone)]
pub struct AppState {
    pub db_pool: DbPool,
    pub config: &'static Config,
}

pub type DbPool = Pool<AsyncPgConnection>;
pub type DbConn = Object<AsyncPgConnection>;

impl FromRef<AppState> for &'static Config {
    fn from_ref(state: &AppState) -> Self {
        state.config
    }
}

impl FromRequestParts<AppState> for DbConn {
    type Rejection = StatusCode;

    async fn from_request_parts(
        _parts: &mut Parts,
        state: &AppState,
    ) -> Result<Self, Self::Rejection> {
        state
            .db_pool
            .get()
            .await
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)
    }
}
