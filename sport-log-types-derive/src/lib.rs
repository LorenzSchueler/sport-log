//! Derive macros for `sport-log-types`.

use proc_macro::TokenStream;

mod crud;
mod to_from_sql;
mod verification;
use crud::*;
use to_from_sql::*;
use verification::*;

/// Derives `sport_log_types::Create`.
///
/// This macro only works if the following conditions are satisfied:
///
/// - the corresponding table has the same name like this type but in snake_case
/// - there is a type called `New[ThisTypeName]` that implements `diesel::prelude::Insertable` for this table
#[proc_macro_derive(Create)]
pub fn create_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_create(&ast)
}

/// Derives `sport_log_types::GetById`.
///
/// This macro only works if the following conditions are satisfied:
/// - the corresponding table has the same name like this type but in snake_case
/// - there is a type called `[ThisTypeName]Id` which is the primary key of the table.
#[proc_macro_derive(GetById)]
pub fn get_by_id_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_get_by_id(&ast)
}

/// Derives `sport_log_types::GetByUser`.
///
/// This macro only works if the following conditions are satisfied:
/// - the corresponding table has the same name like this type but in snake_case
/// - the table has a column `user_id` which references the table `user`.
#[proc_macro_derive(GetByUser)]
pub fn get_by_user_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_get_by_user(&ast)
}

/// Derives `sport_log_types::GetAll`.
///
/// This macro only works if the following condition is satisfied:
/// - the corresponding table has the same name like this type but in snake_case
#[proc_macro_derive(GetAll)]
pub fn get_all_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_get_all(&ast)
}

/// Derives `sport_log_types::Update`.
///
/// This macro only works if the following conditions are satisfied:
/// - the corresponding table has the same name like this type but in snake_case
/// - this type implements `diesel::prelude::AsChangeset`
#[proc_macro_derive(Update)]
pub fn update_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_update(&ast)
}

/// Derives `sport_log_types::Delete`.
///
/// This macro only works if the following conditions are satisfied:
/// - the corresponding table has the same name like this type but in snake_case
/// - there is a type called `[ThisTypeName]Id` which is the primary key of the table.
#[proc_macro_derive(Delete)]
pub fn delete_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_delete(&ast)
}

#[proc_macro_derive(VerifyIdForUser)]
pub fn verify_id_for_user_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_verify_id_for_user(&ast)
}

#[proc_macro_derive(VerifyIdForUserUnchecked)]
pub fn verify_it_for_user_unchecked_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_verify_id_for_user_unchecked(&ast)
}

#[proc_macro_derive(VerifyIdForActionProvider)]
pub fn verify_id_for_action_provider_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_verify_id_for_action_provider(&ast)
}

#[proc_macro_derive(VerifyIdForAdmin)]
pub fn verify_id_for_admin_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_verify_id_for_admin(&ast)
}

#[proc_macro_derive(VerifyForUserWithDb)]
pub fn verify_for_user_with_db_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_verify_for_user_with_db(&ast)
}

#[proc_macro_derive(VerifyForUserWithoutDb)]
pub fn verify_for_user_without_db_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_verify_for_user_without_db(&ast)
}

#[proc_macro_derive(VerifyForActionProviderWithDb)]
pub fn verify_for_action_provider_with_db_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_verify_for_action_provider_with_db(&ast)
}

#[proc_macro_derive(VerifyForActionProviderWithoutDb)]
pub fn verify_for_action_provider_without_db_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_verify_for_action_provider_without_db(&ast)
}

#[proc_macro_derive(VerifyForActionProviderUnchecked)]
pub fn verify_for_admin_unchecked_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_verify_for_action_provider_unchecked(&ast)
}

#[proc_macro_derive(VerifyForAdminWithoutDb)]
pub fn verify_for_admin_without_db_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_verify_for_admin_without_db(&ast)
}

/// Derives `sport_log_types::FromI32`.
///
/// This macro only works if the type is a one tuple struct of i32.
#[proc_macro_derive(FromI32)]
pub fn form_i32_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_from_i32(&ast)
}

/// Derives `diesel::types::ToSql<diesel::sql_types::Integer, diesel::pg::Pg>`.
///
/// This macro only works if the type implements `sport_log_types::FromI32` which can also be derived using [FromI32].
#[proc_macro_derive(ToSql)]
pub fn unverified_inner_int_to_sql(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_to_sql(&ast)
}

/// Derives `diesel::types::FromSql<diesel::sql_types::Integer, diesel::pg::Pg>`.
///
/// This macro only works if the type implements `sport_log_types::FromI32` which can also be derived using [FromI32].
#[proc_macro_derive(FromSql)]
pub fn unverified_inner_int_drom_sql(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_from_sql(&ast)
}