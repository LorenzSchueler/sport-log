extern crate proc_macro;

use inflector::Inflector;
use proc_macro::TokenStream;
use proc_macro2::{Ident, Span};
use quote::quote;

fn get_identifiers(typename: &Ident) -> (Ident, Ident, Ident, Ident, Ident) {
    let newtypename = Ident::new(
        ("New".to_owned() + typename.to_string().as_ref()).as_ref(),
        Span::call_site(),
    );
    let idtypename = Ident::new((typename.to_string() + "Id").as_ref(), Span::call_site());
    let idparamname = Ident::new(
        idtypename.to_string().to_snake_case().as_ref(),
        Span::call_site(),
    );
    let paramname = Ident::new(
        typename.to_string().to_snake_case().as_ref(),
        Span::call_site(),
    );
    (
        newtypename,
        idtypename,
        paramname.clone(),
        idparamname,
        paramname,
    )
}

#[proc_macro_derive(Create)]
pub fn create_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_create(&ast)
}

fn impl_create(ast: &syn::DeriveInput) -> TokenStream {
    let typename = &ast.ident;
    let (newtypename, _, paramname, _, tablename) = get_identifiers(typename);

    let gen = quote! {
        use diesel::prelude::*;

        impl #typename {
            pub fn create(#paramname: #newtypename, conn: &PgConnection) -> QueryResult<#typename> {
                diesel::insert_into(#tablename::table)
                    .values(#paramname)
                    .get_result(conn)
            }
        }
    };
    gen.into()
}

#[proc_macro_derive(GetById)]
pub fn get_by_id_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_get_by_id(&ast)
}

fn impl_get_by_id(ast: &syn::DeriveInput) -> TokenStream {
    let typename = &ast.ident;
    let (_, idtypename, _, idparamname, tablename) = get_identifiers(typename);

    let gen = quote! {
        use diesel::prelude::*;

        impl #typename {
            pub fn get_by_id(#idparamname: #idtypename, conn: &PgConnection) -> QueryResult<#typename> {
                #tablename::table.find(#idparamname).get_result(conn)
            }
        }
    };
    gen.into()
}

#[proc_macro_derive(GetAll)]
pub fn get_all_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_get_all(&ast)
}

fn impl_get_all(ast: &syn::DeriveInput) -> TokenStream {
    let typename = &ast.ident;
    let (_, _, _, _, tablename) = get_identifiers(typename);

    let gen = quote! {
        use diesel::prelude::*;

        impl #typename {
            pub fn get_all(conn: &PgConnection) -> QueryResult<Vec<#typename>> {
                #tablename::table.load(conn)
            }
        }
    };
    gen.into()
}

#[proc_macro_derive(Update)]
pub fn update_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_update(&ast)
}

fn impl_update(ast: &syn::DeriveInput) -> TokenStream {
    let typename = &ast.ident;
    let (_, _, paramname, _, tablename) = get_identifiers(typename);

    let gen = quote! {
        use diesel::prelude::*;

        impl #typename {
            pub fn update(#paramname: #typename, conn: &PgConnection) -> QueryResult<#typename> {
                diesel::update(#tablename::table.find(#tablename.id))
                    .set(#paramname)
                    .get_result(conn)
            }
        }
    };
    gen.into()
}

#[proc_macro_derive(Delete)]
pub fn delete_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_delete(&ast)
}

fn impl_delete(ast: &syn::DeriveInput) -> TokenStream {
    let typename = &ast.ident;
    let (_, idtypename, paramname, _, tablename) = get_identifiers(typename);

    let gen = quote! {
        use diesel::prelude::*;

        impl #typename {
            pub fn delete(#paramname: #idtypename, conn: &PgConnection) -> QueryResult<usize> {
                diesel::delete(#tablename::table.find(#paramname)).execute(conn)
            }
        }
    };
    gen.into()
}

#[proc_macro_derive(VerifyForUser)]
pub fn verify_for_user_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_verify_for_user(&ast)
}

fn impl_verify_for_user(ast: &syn::DeriveInput) -> TokenStream {
    let unverified_id_typename = &ast.ident;
    let unverified_id_typename_str = unverified_id_typename.to_string();
    let typename = Ident::new(
        &unverified_id_typename_str[10..unverified_id_typename_str.len() - 2],
        Span::call_site(),
    );
    let id_typename = Ident::new(&unverified_id_typename_str[10..], Span::call_site());

    let gen = quote! {
        impl #unverified_id_typename {
            pub fn verify(
                self,
                auth: &crate::auth::AuthenticatedUser,
                conn: &diesel::pg::PgConnection,
            ) -> Result<crate::model::#id_typename, rocket::http::Status> {
                let entity = crate::model::#typename::get_by_id(crate::model::#id_typename(self.0), conn)
                    .map_err(|_| rocket::http::Status::Forbidden)?;
                if entity.user_id == **auth {
                    Ok(crate::model::#id_typename(self.0))
                } else {
                    Err(rocket::http::Status::Forbidden)
                }
            }
        }
    };
    gen.into()
}

#[proc_macro_derive(InnerIntFromParam)]
pub fn inner_int_from_param_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_inner_int_from_param(&ast)
}

fn impl_inner_int_from_param(ast: &syn::DeriveInput) -> TokenStream {
    let unverified_id_typename = &ast.ident;

    let gen = quote! {
        impl<'v> rocket::request::FromParam<'v> for #unverified_id_typename{
            type Error = &'v str;

            fn from_param(param: &'v str) -> Result<Self, Self::Error> {
                Ok(Self(i32::from_param(param)?))
            }
        }
    };
    gen.into()
}

#[proc_macro_derive(InnerIntToSql)]
pub fn unverfied_inner_int_to_sql(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_inner_int_to_sql(&ast)
}

fn impl_inner_int_to_sql(ast: &syn::DeriveInput) -> TokenStream {
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

#[proc_macro_derive(InnerIntFromSql)]
pub fn unverfied_inner_int_drom_sql(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_inner_int_from_sql(&ast)
}

fn impl_inner_int_from_sql(ast: &syn::DeriveInput) -> TokenStream {
    let typename = &ast.ident;

    let gen = quote! {
        impl  diesel::types::FromSql<diesel::sql_types::Integer, diesel::pg::Pg> for #typename {
            fn from_sql(bytes: Option<&[u8]>) -> diesel::deserialize::Result<Self> {
                let id = diesel::types::FromSql::<diesel::sql_types::Integer, diesel::pg::Pg>::from_sql(bytes)?;
                Ok(#typename(id))
            }
        }
    };
    gen.into()
}
