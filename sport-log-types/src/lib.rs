#[cfg(feature = "full")]
#[macro_use]
extern crate diesel;

#[cfg(feature = "full")]
pub mod repository;
#[cfg(feature = "full")]
pub mod schema;
pub mod types;
