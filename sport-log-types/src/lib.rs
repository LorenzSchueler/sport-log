#[cfg(feature = "server")]
#[macro_use]
extern crate diesel;

#[cfg(feature = "server")]
pub mod repository;
#[cfg(feature = "server")]
pub mod schema;
mod types;
pub use types::*;
