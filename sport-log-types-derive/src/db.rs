use proc_macro::TokenStream;
use quote::quote;

use crate::Identifiers;

pub(crate) fn impl_db(
    Identifiers {
        db_type,
        entity_type,
        id_type,
        ..
    }: Identifiers,
) -> TokenStream {
    quote! {
        impl crate::db::Db for #db_type {
            type Id = sport_log_types::#id_type;
            type Entity = sport_log_types::#entity_type;
        }
    }
    .into()
}
