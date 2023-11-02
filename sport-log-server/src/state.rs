use axum::{
    async_trait,
    extract::{FromRef, FromRequestParts},
    http::{request::Parts, StatusCode},
};
use diesel::{
    r2d2::{ConnectionManager, Pool, PooledConnection},
    PgConnection,
};

use crate::Config;

#[derive(Clone)]
pub struct AppState {
    pub db_pool: DbPool,
    pub config: &'static Config,
}

pub type DbPool = Pool<ConnectionManager<PgConnection>>;
pub type DbConn = PooledConnection<ConnectionManager<PgConnection>>;

impl FromRef<AppState> for &'static Config {
    fn from_ref(state: &AppState) -> Self {
        state.config
    }
}

#[async_trait]
impl FromRequestParts<AppState> for DbConn {
    type Rejection = StatusCode;

    async fn from_request_parts(
        _parts: &mut Parts,
        state: &AppState,
    ) -> Result<Self, Self::Rejection> {
        state
            .db_pool
            .get()
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)
    }
}
