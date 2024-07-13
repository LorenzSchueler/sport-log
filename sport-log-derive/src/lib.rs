//! Derive macros for `sport-log-types` and `sport-log-server`.

use inflector::Inflector;
use proc_macro::TokenStream;
use proc_macro2::Ident;
use quote::format_ident;

mod server;
use server::*;

struct Identifiers {
    db_type: Ident,
    value_type: Ident,
    id_type: Ident,
    value_name: Ident,
}

impl Identifiers {
    fn from_ast(ast: &syn::DeriveInput) -> Identifiers {
        let db_type = ast.ident.clone();
        let db_type_str = db_type.to_string();
        let entity_type = Ident::new(&db_type_str[..db_type_str.len() - 2], db_type.span());
        let id_type = format_ident!("{entity_type}Id");
        let entity_name = Ident::new(&entity_type.to_string().to_snake_case(), db_type.span());
        Identifiers {
            db_type,
            value_type: entity_type,
            id_type,
            value_name: entity_name,
        }
    }
}

/// Derives `Db`.
#[proc_macro_derive(Db)]
pub fn db(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_db(Identifiers::from_ast(&ast))
}

/// Derives `DbWithUserId`.
#[proc_macro_derive(DbWithUserId)]
pub fn db_with_user_id(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_db_with_user_id(Identifiers::from_ast(&ast))
}

/// Derives `DbWithApId`.
#[proc_macro_derive(DbWithApId)]
pub fn db_with_ap_id(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_db_with_ap_id(Identifiers::from_ast(&ast))
}

/// Derives `DbWithDateTime`.
#[proc_macro_derive(DbWithDateTime)]
pub fn db_with_datetime(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_db_with_datetime(Identifiers::from_ast(&ast))
}

/// Derives `ModifiableDd`.
#[proc_macro_derive(ModifiableDb)]
pub fn modifiable_db(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_modifiable_db(Identifiers::from_ast(&ast))
}
