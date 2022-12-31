//! Central server for **Sport Log**.
//!
//! **Sport Log Server** is a multi-user server backend which stores user data and provides synchronization.
//!
//! # Usage
//!
//! **Sport Log Server** should be started at system startup, preferably as a systemd service.
//! It is highly recommended to use an HTTP server like apache or nginx and configure it as a reverse proxy.
//! Make sure only connections via HTTPS are allowed, otherwise you data will be send in clear text.
//!
//! # Config
//!
//! The config must be deserializable to [Config](sport_log_types::Config).
//! The name of the config file is specified in [CONFIG_FILE].

use std::{env, sync::Arc};

#[macro_use]
extern crate diesel_migrations;

use axum::{Router, Server};
use diesel::{
    r2d2::{ConnectionManager, Pool},
    PgConnection,
};
use tokio::fs;
use tracing::{error, info};
use tracing_subscriber::EnvFilter;

use sport_log_types::{AppState, Config, DbPool};

mod handler;
mod router;
#[cfg(test)]
mod tests;

const CONFIG_FILE: &str = "sport-log-server.toml";

const VERSION: &str = "0.3";
const MIN_VERSION: &str = VERSION;
const MAX_VERSION: &str = VERSION;

fn tracing_setup() {
    if cfg!(test) {
        env::set_var("RUST_LOG", "info");
    } else if cfg!(debug_assertions) {
        env::set_var("RUST_LOG", "info,sport_log_server=debug");
    } else {
        env::set_var("RUST_LOG", "warn,sport_log_server=info");
    }

    tracing_subscriber::fmt()
        .with_writer(std::io::stderr)
        .with_env_filter(EnvFilter::from_default_env())
        .init();
}

async fn get_config() -> Result<Config, String> {
    let config_file = fs::read_to_string(CONFIG_FILE)
        .await
        .map_err(|err| format!("failed to read config file: {err}"))?;
    toml::from_str(&config_file).map_err(|err| format!("failed to parse config file: {err}"))
}

async fn get_db_pool(config: &Config) -> Result<DbPool, String> {
    let pool = Pool::new(ConnectionManager::<PgConnection>::new(&config.database_url))
        .map_err(|err| format!("failed to create database connection pool: {err}"))?;

    if !cfg!(test) {
        diesel_migrations::embed_migrations!();
        let db = pool.get().map_err(|err| {
            format!("failed to retrieve database connection from connection pool: {err}")
        })?;

        info!("running database migrations...");
        embedded_migrations::run(&db)
            .map_err(|err| format!("failed to run database migrations: {err}"))?;
        info!("database is up to date");
    }

    Ok(pool)
}

async fn run_server(router: Router, config: &Config) -> Result<(), String> {
    let address = if cfg!(debug_assertions) {
        &config.debug_address
    } else {
        &config.release_address
    };
    let server_builder = Server::try_bind(address)
        .map_err(|err| format! {"failed to create server builder: {err}"})?;

    info!("starting server at {address}");
    server_builder
        .serve(router.into_make_service())
        .await
        .map_err(|err| format! {"failed to start server: {err}"})
}

#[tokio::main]
async fn main() {
    tracing_setup();

    let config = match get_config().await {
        Ok(config) => config,
        Err(err) => {
            error!("{}", err);
            return;
        }
    };

    let db_pool = match get_db_pool(&config).await {
        Ok(config) => config,
        Err(err) => {
            error!("{}", err);
            return;
        }
    };

    let state = AppState {
        db_pool,
        config: Arc::new(config.clone()),
    };

    let router = router::get_router(state).await;

    if let Err(err) = run_server(router, &config).await {
        error!("{}", err);
    }
}
