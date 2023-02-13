#[cfg(feature = "db")]
#[macro_use]
extern crate diesel;

#[cfg(feature = "diesel")]
pub mod schema;
mod types;
pub use types::*;
