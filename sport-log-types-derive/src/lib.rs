//! Derive macros for `sport-log-types` and `sport-log-server`.

use inflector::Inflector;
use proc_macro::TokenStream;
use proc_macro2::{Ident, Span};

mod server;
mod types;
use server::*;
use types::*;

struct Identifiers {
    db_type: Ident,
    entity_type: Ident,
    id_type: Ident,
    id_name: Ident,
    entity_name: Ident,
}

impl Identifiers {
    fn from_ast(ast: &syn::DeriveInput) -> Identifiers {
        let db_type = ast.ident.clone();
        let db_type_str = db_type.to_string();
        let entity_type = Ident::new(&db_type_str[..db_type_str.len() - 2], Span::call_site());
        let id_type = Ident::new(&(entity_type.to_string() + "Id"), Span::call_site());
        let id_name = Ident::new(&id_type.to_string().to_snake_case(), Span::call_site());
        let entity_name = Ident::new(&entity_type.to_string().to_snake_case(), Span::call_site());
        Identifiers {
            db_type,
            entity_type,
            id_type,
            id_name,
            entity_name,
        }
    }
}

/// Derives `sport_log_types::Create`.
///
/// This macro only works if the following conditions are satisfied:
///
/// - the corresponding table has the same name like this type but in snake_case
/// - there is a type called `New[ThisTypeName]` that implements `diesel::prelude::Insertable` for this table
#[proc_macro_derive(Create)]
pub fn create_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_create(Identifiers::from_ast(&ast))
}

/// Derives `sport_log_types::GetById`.
///
/// This macro only works if the following conditions are satisfied:
/// - the corresponding table has the same name like this type but in snake_case
/// - there is a type called `[ThisTypeName]Id` which is the primary key of the table.
#[proc_macro_derive(GetById)]
pub fn get_by_id_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_get_by_id(Identifiers::from_ast(&ast))
}

/// Derives `sport_log_types::GetByIds`.
///
/// This macro only works if the following conditions are satisfied:
/// - the corresponding table has the same name like this type but in snake_case
/// - there is a type called `[ThisTypeName]Id` which is the primary key of the table.
#[proc_macro_derive(GetByIds)]
pub fn get_by_ids_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_get_by_ids(Identifiers::from_ast(&ast))
}

/// Derives `sport_log_types::GetByUser`.
///
/// This macro only works if the following conditions are satisfied:
/// - the corresponding table has the same name like this type but in snake_case
/// - the table has a column `user_id` which references the table `user`.
#[proc_macro_derive(GetByUser)]
pub fn get_by_user_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_get_by_user(Identifiers::from_ast(&ast))
}

/// Derives `sport_log_types::GetByUserSync`.
///
/// This macro only works if the following conditions are satisfied:
/// - the corresponding table has the same name like this type but in snake_case
/// - the table has a column `user_id` which references the table `user`.
/// - the table has a column `last_sync` with type `timestamptz`.
#[proc_macro_derive(GetByUserSync)]
pub fn get_by_user_and_last_sync_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_get_by_user_and_last_sync(Identifiers::from_ast(&ast))
}

/// Derives `sport_log_types::GetBySync`.
///
/// This macro only works if the following conditions are satisfied:
/// - the corresponding table has the same name like this type but in snake_case
/// - the table has a column `last_sync` with type `timestamptz`.
#[proc_macro_derive(GetBySync)]
pub fn get_by_last_sync_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_get_by_last_sync(Identifiers::from_ast(&ast))
}

/// Derives `sport_log_types::GetAll`.
///
/// This macro only works if the following condition is satisfied:
/// - the corresponding table has the same name like this type but in snake_case
#[proc_macro_derive(GetAll)]
pub fn get_all_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_get_all(Identifiers::from_ast(&ast))
}

/// Derives `sport_log_types::Update`.
///
/// This macro only works if the following conditions are satisfied:
/// - the corresponding table has the same name like this type but in snake_case
/// - this type implements `diesel::prelude::AsChangeset`
#[proc_macro_derive(Update)]
pub fn update_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_update(Identifiers::from_ast(&ast))
}

/// Derives `sport_log_types::HardDelete`.
///
/// This macro only works if the following conditions are satisfied:
/// - the corresponding table has the same name like this type but in snake_case
/// - the table has the columns `deleted` ([bool]) and `last_change` (chrono::DateTime)
#[proc_macro_derive(HardDelete)]
pub fn hard_delete_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_hard_delete(Identifiers::from_ast(&ast))
}

#[proc_macro_derive(CheckUserId)]
pub fn check_user_id_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_check_user_id(Identifiers::from_ast(&ast))
}

#[proc_macro_derive(CheckAPId)]
pub fn check_ap_id_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_check_ap_id(Identifiers::from_ast(&ast))
}

#[proc_macro_derive(VerifyIdForUser)]
pub fn verify_id_for_user_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_verify_id_for_user(Identifiers::from_ast(&ast))
}

#[proc_macro_derive(VerifyIdForUserOrAP)]
pub fn verify_id_for_user_or_ap_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_verify_id_for_user_or_ap(Identifiers::from_ast(&ast))
}

#[proc_macro_derive(VerifyIdForActionProvider)]
pub fn verify_id_for_action_provider_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_verify_id_for_action_provider(Identifiers::from_ast(&ast))
}

#[proc_macro_derive(VerifyIdForAdmin)]
pub fn verify_id_for_admin_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_verify_id_for_admin(Identifiers::from_ast(&ast))
}

#[proc_macro_derive(VerifyIdUnchecked)]
pub fn verify_id_unchecked_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_verify_id_unchecked(Identifiers::from_ast(&ast))
}

#[proc_macro_derive(VerifyForUserWithDb)]
pub fn verify_for_user_with_db_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_verify_for_user_with_db(Identifiers::from_ast(&ast))
}

#[proc_macro_derive(VerifyForUserWithoutDb)]
pub fn verify_for_user_without_db_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_verify_for_user_without_db(Identifiers::from_ast(&ast))
}

#[proc_macro_derive(VerifyForUserOrAPWithDb)]
pub fn verify_for_user_or_ap_with_db_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_verify_for_user_or_ap_with_db(Identifiers::from_ast(&ast))
}

#[proc_macro_derive(VerifyForUserOrAPWithoutDb)]
pub fn verify_for_user_or_ap_without_db_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_verify_for_user_or_ap_without_db(Identifiers::from_ast(&ast))
}

#[proc_macro_derive(VerifyForActionProviderWithDb)]
pub fn verify_for_action_provider_with_db_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_verify_for_action_provider_with_db(Identifiers::from_ast(&ast))
}

#[proc_macro_derive(VerifyForActionProviderWithoutDb)]
pub fn verify_for_action_provider_without_db_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_verify_for_action_provider_without_db(Identifiers::from_ast(&ast))
}

#[proc_macro_derive(VerifyForAdminWithoutDb)]
pub fn verify_for_admin_without_db_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_verify_for_admin_without_db(Identifiers::from_ast(&ast))
}

#[proc_macro_derive(VerifyUnchecked)]
pub fn verify_unchecked_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_verify_unchecked(Identifiers::from_ast(&ast))
}

/// Derives `diesel::types::ToSql<diesel::sql_types::BigInt, diesel::pg::Pg>`.
///
/// This macro only works if the type is a one tuple struct of i64.
#[proc_macro_derive(IdToSql)]
pub fn unverified_inner_int_to_sql(input: TokenStream) -> TokenStream {
    let ast: syn::DeriveInput = syn::parse(input).unwrap();
    impl_id_to_sql(&ast.ident)
}

/// Derives `diesel::types::IdFromSql<diesel::sql_types::BigInt, diesel::pg::Pg>`.
///
/// This macro only works if the type is a one tuple struct of i64.
#[proc_macro_derive(IdFromSql)]
pub fn unverified_inner_int_from_sql(input: TokenStream) -> TokenStream {
    let ast: syn::DeriveInput = syn::parse(input).unwrap();
    impl_id_from_sql(&ast.ident)
}

/// Derives `TryFrom<IdString>` and `Into<IdString>`.
///
/// This macro only works if the type is a one tuple struct of i64.
#[proc_macro_derive(IdString)]
pub fn unverified_id_string(input: TokenStream) -> TokenStream {
    let ast: syn::DeriveInput = syn::parse(input).unwrap();
    impl_id_string(&ast.ident)
}

/// Derives `Db`.
#[proc_macro_derive(Db)]
pub fn db(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_db(Identifiers::from_ast(&ast))
}
