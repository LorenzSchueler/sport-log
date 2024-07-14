use proc_macro::TokenStream;
use quote::quote;

use crate::Identifiers;

pub(crate) fn impl_db(
    Identifiers {
        db_type,
        value_type,
        id_type,
        value_name,
        ..
    }: Identifiers,
) -> TokenStream {
    quote! {
        impl crate::db::Db for #db_type {
            type Id = sport_log_types::#id_type;
            type Type = sport_log_types::#value_type;
            type Table = sport_log_types::schema::#value_name::table;

            fn table() -> Self::Table {
                sport_log_types::schema::#value_name::table
            }

            fn id_column() -> <Self::Table as diesel::query_source::Table>::PrimaryKey {
                sport_log_types::schema::#value_name::columns::id
            }
        }
    }
    .into()
}

pub(crate) fn impl_db_with_user_id(
    Identifiers {
        db_type,
        value_name,
        ..
    }: Identifiers,
) -> TokenStream {
    quote! {
        impl crate::db::DbWithUserId for #db_type {
            type UserIdColumn = sport_log_types::schema::#value_name::columns::user_id;

            fn user_id_column() -> Self::UserIdColumn {
                sport_log_types::schema::#value_name::columns::user_id
            }
        }
    }
    .into()
}

pub(crate) fn impl_db_with_ap_id(
    Identifiers {
        db_type,
        value_name,
        ..
    }: Identifiers,
) -> TokenStream {
    quote! {
        impl crate::db::DbWithApId for #db_type {
            type ApIdColumn = sport_log_types::schema::#value_name::columns::action_provider_id;

            fn ap_id_column() -> Self::ApIdColumn {
                sport_log_types::schema::#value_name::columns::action_provider_id
            }
        }
    }
    .into()
}

pub(crate) fn impl_db_with_datetime(
    Identifiers {
        db_type,
        value_name,
        ..
    }: Identifiers,
) -> TokenStream {
    quote! {
        impl crate::db::DbWithDateTime for #db_type {
            type DateTimeColumn = sport_log_types::schema::#value_name::columns::datetime;

            fn datetime_column() -> Self::DateTimeColumn {
                sport_log_types::schema::#value_name::columns::datetime
            }
        }
    }
    .into()
}

pub(crate) fn impl_modifiable_db(
    Identifiers {
        db_type,
        value_name,
        ..
    }: Identifiers,
) -> TokenStream {
    quote! {
        impl crate::db::ModifiableDb for #db_type {
            type EpochColumn = sport_log_types::schema::#value_name::columns::epoch;

            fn epoch_column() -> Self::EpochColumn {
                sport_log_types::schema::#value_name::columns::epoch
            }
        }
    }
    .into()
}
