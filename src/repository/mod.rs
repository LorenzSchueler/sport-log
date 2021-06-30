#![allow(proc_macro_derive_resolution_fallback)]
use diesel::prelude::*;

use crate::model::*;

pub mod account;
pub mod action;
pub mod platform_credentials;
