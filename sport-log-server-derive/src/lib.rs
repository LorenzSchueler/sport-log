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

#[proc_macro_derive(UnverifiedFromParamToVerifiedForUser)]
pub fn unverfied_from_param_to_verified_for_user_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_unverfied_from_param_to_verified_for_user(&ast)
}

fn impl_unverfied_from_param_to_verified_for_user(ast: &syn::DeriveInput) -> TokenStream {
    let unverified_id_typename = &ast.ident;
    let unverified_id_typename_str = unverified_id_typename.to_string();
    let id_typename = Ident::new(&unverified_id_typename_str[10..], Span::call_site());
    let typename = Ident::new(
        &unverified_id_typename_str[10..unverified_id_typename_str.len() - 2],
        Span::call_site(),
    );

    let gen = quote! {
        impl #unverified_id_typename {
            pub fn verify(
                self,
                auth: AuthenticatedUser,
                conn: &PgConnection,
            ) -> Result<#id_typename, rocket::http::Status> {
                let entity = #typename::get_by_id(self.0, conn)
                    .map_err(|_| rocket::http::Status::Forbidden)?;
                if entity.user_id == *auth {
                    Ok(self.0)
                } else {
                    Err(rocket::http::Status::Forbidden)
                }
            }
        }
    };
    gen.into()
}

#[proc_macro_derive(FromParam)]
pub fn unverfied_from_param(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_unverfied_from_param(&ast)
}

fn impl_unverfied_from_param(ast: &syn::DeriveInput) -> TokenStream {
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
