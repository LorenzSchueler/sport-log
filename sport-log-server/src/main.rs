//! Central server for **Sport Log**.
//!
//! **Sport Log Server** is a multi-user server backend which stores user data and provides
//! synchronization.
//!
//! # Usage
//!
//! **Sport Log Server** should be started at system startup, preferably as a systemd service.
//! It is highly recommended to use an HTTP server like apache or nginx and configure it as a
//! reverse proxy. Make sure only connections via HTTPS are allowed, otherwise you data will be send
//! in clear text.
//!
//! # Config
//!
//! The config must be deserializable to [`Config`].
//! The name of the config file is specified in [`CONFIG_FILE`].

use std::{env, process::ExitCode};

use axum::Router;
use diesel::Connection;
use diesel_async::{
    async_connection_wrapper::AsyncConnectionWrapper,
    pooled_connection::{deadpool::Pool, AsyncDieselConnectionManager},
    AsyncPgConnection,
};
use diesel_migrations::{EmbeddedMigrations, HarnessWithOutput, MigrationHarness};
use tokio::fs;
use tracing::{error, info};
use tracing_subscriber::EnvFilter;

use crate::{
    config::Config,
    state::{AppState, DbPool},
};

mod auth;
mod config;
mod db;
mod error;
mod handler;
mod router;
mod state;
#[cfg(test)]
mod tests;

const CONFIG_FILE: &str = "sport-log-server.toml";

const MIGRATIONS: EmbeddedMigrations = diesel_migrations::embed_migrations!();

fn tracing_setup() {
    if env::var("RUST_LOG").is_err() {
        if cfg!(debug_assertions) {
            env::set_var("RUST_LOG", "info,sport_log_server=debug");
        } else {
            env::set_var("RUST_LOG", "warn,sport_log_server=info");
        }
    }

    tracing_subscriber::fmt()
        .with_writer(std::io::stderr)
        .with_env_filter(EnvFilter::from_default_env())
        .init();
}

async fn get_config() -> Result<Config, String> {
    let config_file = fs::read_to_string(CONFIG_FILE)
        .await
        .map_err(|err| format!("failed to read {CONFIG_FILE}: {err}"))?;
    toml::from_str(&config_file).map_err(|err| format!("failed to parse {CONFIG_FILE}: {err}"))
}

async fn get_db_pool(config: &Config) -> Result<DbPool, String> {
    let db_config = AsyncDieselConnectionManager::<AsyncPgConnection>::new(&config.database_url);
    let pool = Pool::builder(db_config)
        .build()
        .map_err(|err| format!("failed to create database connection pool: {err}"))?;

    info!("running database migrations...");
    let db_url = config.database_url.clone();
    tokio::task::spawn_blocking(move || {
        let mut conn = AsyncConnectionWrapper::<AsyncPgConnection>::establish(&db_url)
            .map_err(|err| format!("failed to create migration database connection: {err}"))?;

        HarnessWithOutput::new(&mut conn, std::io::stderr())
            .run_pending_migrations(MIGRATIONS)
            .map_err(|err| format!("failed to run database migrations: {err}"))?;

        Result::<(), String>::Ok(())
    })
    .await
    .map_err(|err| format!("failed to run database migrations: {err}"))??;

    info!("database is up to date");

    Ok(pool)
}

async fn run_server(router: Router, config: &Config) -> Result<(), String> {
    let address = if cfg!(debug_assertions) {
        &config.debug_address
    } else {
        &config.release_address
    };

    let listener = tokio::net::TcpListener::bind(address)
        .await
        .map_err(|err| format!("failed to bind to {address}: {err}"))?;

    info!("starting server at {address}");
    axum::serve(listener, router)
        .await
        .map_err(|err| format! {"failed to start server: {err}"})
}

#[tokio::main]
async fn main() -> ExitCode {
    tracing_setup();

    let config = match get_config().await {
        Ok(config) => Box::leak(Box::new(config)),
        Err(error) => {
            error!("{error}");
            return ExitCode::FAILURE;
        }
    };

    let db_pool = match get_db_pool(config).await {
        Ok(db_pool) => db_pool,
        Err(error) => {
            error!("{error}");
            return ExitCode::FAILURE;
        }
    };

    let state = AppState { db_pool, config };

    let router = router::get_router(state);

    if let Err(error) = run_server(router, config).await {
        error!("{error}");
        return ExitCode::FAILURE;
    }

    ExitCode::SUCCESS
}
