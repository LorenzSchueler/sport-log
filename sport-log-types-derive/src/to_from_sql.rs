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
