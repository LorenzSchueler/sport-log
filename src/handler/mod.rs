use rocket::http::Status;
use rocket_contrib::json::Json;

use crate::{model::*, repository as repo, Db};

pub mod account;
