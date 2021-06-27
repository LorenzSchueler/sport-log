#![allow(proc_macro_derive_resolution_fallback)]
use diesel::prelude::*;

use crate::model::{Account, NewAccount};
use crate::schema::account::dsl::*;

pub mod account;
