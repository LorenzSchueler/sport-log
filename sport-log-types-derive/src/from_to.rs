use proc_macro::TokenStream;
use quote::quote;

pub fn impl_id_to_sql(ast: &syn::DeriveInput) -> TokenStream {
    let typename = &ast.ident;

    let gen = quote! {
        impl diesel::serialize::ToSql<diesel::sql_types::BigInt, diesel::pg::Pg> for #typename {
            fn to_sql<'b>(&'b self, out: &mut diesel::serialize::Output<'b, '_, diesel::pg::Pg>) -> diesel::serialize::Result {
                diesel::serialize::ToSql::<diesel::sql_types::BigInt, diesel::pg::Pg>::to_sql(&self.0, out)
            }
        }
    };
    gen.into()
}

pub fn impl_id_from_sql(ast: &syn::DeriveInput) -> TokenStream {
    let typename = &ast.ident;

    let gen = quote! {
        impl diesel::deserialize::FromSql<diesel::sql_types::BigInt, diesel::pg::Pg> for #typename {
            fn from_sql(bytes: diesel::backend::RawValue<'_, diesel::pg::Pg>) -> diesel::deserialize::Result<Self> {
                let id = diesel::deserialize::FromSql::<diesel::sql_types::BigInt, diesel::pg::Pg>::from_sql(bytes)?;
                Ok(Self(id))
            }
        }
    };
    gen.into()
}

pub fn impl_id_string(ast: &syn::DeriveInput) -> TokenStream {
    let typename = &ast.ident;

    let gen = quote! {
        impl TryFrom<crate::types::IdString> for #typename {
            type Error = <i64 as std::str::FromStr>::Err;

            fn try_from(id_string: IdString) -> Result<Self, Self::Error> {
                use std::str::FromStr;

                id_string.0.parse().map(Self)
            }
        }

        #[allow(clippy::from_over_into)]
        impl Into<crate::types::IdString> for #typename {
            fn into(self) -> crate::types::IdString {
                crate::types::IdString(self.0.to_string())
            }
        }
    };
    gen.into()
}
