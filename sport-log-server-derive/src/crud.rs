extern crate proc_macro;

use inflector::Inflector;
use proc_macro::TokenStream;
use proc_macro2::{Ident, Span};
use quote::quote;

pub fn get_identifiers(typename: &Ident) -> (Ident, Ident, Ident, Ident, Ident) {
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

pub fn impl_create(ast: &syn::DeriveInput) -> TokenStream {
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

pub fn impl_get_by_id(ast: &syn::DeriveInput) -> TokenStream {
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

pub fn impl_get_by_user(ast: &syn::DeriveInput) -> TokenStream {
    let typename = &ast.ident;
    let (_, _, _, _, tablename) = get_identifiers(typename);

    let gen = quote! {
        use diesel::prelude::*;

        impl #typename {
            pub fn get_by_user(user_id: crate::types::UserId, conn: &PgConnection) -> QueryResult<Vec<#typename>> {
                #tablename::table
                    .filter(#tablename::columns::user_id.eq(user_id))
                    .get_results(conn)
            }
        }
    };
    gen.into()
}

pub fn impl_get_all(ast: &syn::DeriveInput) -> TokenStream {
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

pub fn impl_update(ast: &syn::DeriveInput) -> TokenStream {
    let typename = &ast.ident;
    let (_, _, paramname, _, tablename) = get_identifiers(typename);

    let gen = quote! {
        use diesel::prelude::*;

        impl #typename {
            pub fn update(#paramname: #typename, conn: &PgConnection) -> QueryResult<#typename> {
                diesel::update(#tablename::table.find(#paramname.id))
                    .set(#paramname)
                    .get_result(conn)
            }
        }
    };
    gen.into()
}

pub fn impl_delete(ast: &syn::DeriveInput) -> TokenStream {
    let typename = &ast.ident;
    let (_, idtypename, _, idparamname, tablename) = get_identifiers(typename);

    let gen = quote! {
        use diesel::prelude::*;

        impl #typename {
            pub fn delete(#idparamname: #idtypename, conn: &PgConnection) -> QueryResult<usize> {
                diesel::delete(#tablename::table.find(#idparamname)).execute(conn)
            }
        }
    };
    gen.into()
}
