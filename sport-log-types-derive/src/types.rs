use proc_macro::TokenStream;
use proc_macro2::Ident;
use quote::quote;

pub(crate) fn impl_id_to_sql(entity_type: &Ident) -> TokenStream {
    quote! {
        impl diesel::serialize::ToSql<diesel::sql_types::BigInt, diesel::pg::Pg> for #entity_type {
            fn to_sql<'b>(&'b self, out: &mut diesel::serialize::Output<'b, '_, diesel::pg::Pg>) -> diesel::serialize::Result {
                diesel::serialize::ToSql::<diesel::sql_types::BigInt, diesel::pg::Pg>::to_sql(&self.0, out)
            }
        }
    }
    .into()
}

pub(crate) fn impl_id_from_sql(entity_type: &Ident) -> TokenStream {
    quote! {
        impl diesel::deserialize::FromSql<diesel::sql_types::BigInt, diesel::pg::Pg> for #entity_type {
            fn from_sql(bytes: diesel::backend::RawValue<'_, diesel::pg::Pg>) -> diesel::deserialize::Result<Self> {
                let id = diesel::deserialize::FromSql::<diesel::sql_types::BigInt, diesel::pg::Pg>::from_sql(bytes)?;
                Ok(Self(id))
            }
        }
    }
    .into()
}

pub(crate) fn impl_id_string(entity_type: &Ident) -> TokenStream {
    quote! {
        impl TryFrom<crate::types::IdString> for #entity_type {
            type Error = <i64 as std::str::FromStr>::Err;

            fn try_from(id_string: IdString) -> Result<Self, Self::Error> {
                use std::str::FromStr;

                id_string.0.parse().map(Self)
            }
        }

        #[allow(clippy::from_over_into)]
        impl Into<crate::types::IdString> for #entity_type {
            fn into(self) -> crate::types::IdString {
                crate::types::IdString(self.0.to_string())
            }
        }
    }
    .into()
}
