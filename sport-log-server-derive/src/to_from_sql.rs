use proc_macro::TokenStream;
use quote::quote;

pub fn impl_to_sql(ast: &syn::DeriveInput) -> TokenStream {
    let typename = &ast.ident;

    let gen = quote! {
        impl diesel::types::ToSql<diesel::sql_types::Integer, diesel::pg::Pg> for #typename {
            fn to_sql<W: std::io::Write>(&self, out: &mut diesel::serialize::Output<W, diesel::pg::Pg>) -> diesel::serialize::Result {
                diesel::types::ToSql::<diesel::sql_types::Integer, diesel::pg::Pg>::to_sql(&self.0, out)
            }
        }
    };
    gen.into()
}

pub fn impl_from_sql(ast: &syn::DeriveInput) -> TokenStream {
    let typename = &ast.ident;

    let gen = quote! {
        impl diesel::types::FromSql<diesel::sql_types::Integer, diesel::pg::Pg> for #typename {
            fn from_sql(bytes: Option<&[u8]>) -> diesel::deserialize::Result<Self> {
                let id = diesel::types::FromSql::<diesel::sql_types::Integer, diesel::pg::Pg>::from_sql(bytes)?;
                Ok(#typename(id))
            }
        }
    };
    gen.into()
}
