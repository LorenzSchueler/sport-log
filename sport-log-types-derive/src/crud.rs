extern crate proc_macro;

use inflector::Inflector;
use proc_macro::TokenStream;
use proc_macro2::{Ident, Span};
use quote::quote;

pub fn get_identifiers(typename: &Ident) -> (Ident, Ident, Ident, Ident) {
    let idtypename = Ident::new((typename.to_string() + "Id").as_ref(), Span::call_site());
    let idparamname = Ident::new(
        idtypename.to_string().to_snake_case().as_ref(),
        Span::call_site(),
    );
    let paramname = Ident::new(
        typename.to_string().to_snake_case().as_ref(),
        Span::call_site(),
    );
    (idtypename, paramname.clone(), idparamname, paramname)
}

pub fn impl_create(ast: &syn::DeriveInput) -> TokenStream {
    let typename = &ast.ident;
    let (_, paramname, _, tablename) = get_identifiers(typename);

    let gen = quote! {
        use diesel::prelude::*;

        impl crate::Create for #typename {
            fn create(#paramname: Self, conn: &PgConnection) -> QueryResult<Self> {
                diesel::insert_into(#tablename::table)
                    .values(#paramname)
                    .get_result(conn)
            }
        }
    };
    gen.into()
}

pub fn impl_create_multiple(ast: &syn::DeriveInput) -> TokenStream {
    let typename = &ast.ident;
    let (_, paramname, _, tablename) = get_identifiers(typename);

    let gen = quote! {
        use diesel::prelude::*;

        impl crate::CreateMultiple for #typename {
            fn create_multiple(#paramname: Vec<Self>, conn: &PgConnection) -> QueryResult<Vec<Self>> {
                diesel::insert_into(#tablename::table)
                    .values(&#paramname)
                    .get_results(conn)
            }
        }
    };
    gen.into()
}

pub fn impl_get_by_id(ast: &syn::DeriveInput) -> TokenStream {
    let typename = &ast.ident;
    let (idtypename, _, idparamname, tablename) = get_identifiers(typename);

    let gen = quote! {
        use diesel::prelude::*;

        impl crate::GetById for #typename {
            type Id = #idtypename;

            fn get_by_id(#idparamname: Self::Id, conn: &PgConnection) -> QueryResult<Self> {
                #tablename::table.find(#idparamname).get_result(conn)
            }
        }
    };
    gen.into()
}

pub fn impl_get_by_ids(ast: &syn::DeriveInput) -> TokenStream {
    let typename = &ast.ident;
    let (idtypename, _, _, tablename) = get_identifiers(typename);

    let gen = quote! {
        use diesel::prelude::*;

        impl crate::GetByIds for #typename {
            type Id = #idtypename;

            fn get_by_ids(ids: &[Self::Id], conn: &PgConnection) -> QueryResult<Vec<Self>> {
                #tablename::table.filter(#tablename::columns::id.eq_any(ids)).get_results(conn)
            }
        }
    };
    gen.into()
}

pub fn impl_get_by_user(ast: &syn::DeriveInput) -> TokenStream {
    let typename = &ast.ident;
    let (_, _, _, tablename) = get_identifiers(typename);

    let gen = quote! {
        use diesel::prelude::*;

        impl crate::GetByUser for #typename {
            fn get_by_user(user_id: crate::UserId, conn: &PgConnection) -> QueryResult<Vec<Self>> {
                #tablename::table
                    .filter(#tablename::columns::user_id.eq(user_id))
                    .get_results(conn)
            }
        }
    };
    gen.into()
}

pub fn impl_get_by_user_and_last_sync(ast: &syn::DeriveInput) -> TokenStream {
    let typename = &ast.ident;
    let (_, _, _, tablename) = get_identifiers(typename);

    let gen = quote! {
        use diesel::prelude::*;

        impl crate::GetByUserSync for #typename {
            fn get_by_user_and_last_sync(
                user_id: crate::UserId,
                last_sync: DateTime<Utc>,
                conn: &PgConnection
            ) -> QueryResult<Vec<Self>> {
                #tablename::table
                    .filter(#tablename::columns::user_id.eq(user_id))
                    .filter(#tablename::columns::last_change.ge(last_sync))
                    .get_results(conn)
            }
        }
    };
    gen.into()
}

pub fn impl_get_by_last_sync(ast: &syn::DeriveInput) -> TokenStream {
    let typename = &ast.ident;
    let (_, _, _, tablename) = get_identifiers(typename);

    let gen = quote! {
        use diesel::prelude::*;

        impl crate::GetBySync for #typename {
            fn get_by_last_sync(last_sync: DateTime<Utc>, conn: &PgConnection) -> QueryResult<Vec<Self>> {
                #tablename::table
                    .filter(#tablename::columns::last_change.ge(last_sync))
                    .get_results(conn)
            }
        }
    };
    gen.into()
}

pub fn impl_get_all(ast: &syn::DeriveInput) -> TokenStream {
    let typename = &ast.ident;
    let (_, _, _, tablename) = get_identifiers(typename);

    let gen = quote! {
        use diesel::prelude::*;

        impl crate::GetAll for #typename {
            fn get_all(conn: &PgConnection) -> QueryResult<Vec<Self>> {
                #tablename::table.load(conn)
            }
        }
    };
    gen.into()
}

pub fn impl_update(ast: &syn::DeriveInput) -> TokenStream {
    let typename = &ast.ident;
    let (_, paramname, _, tablename) = get_identifiers(typename);

    let gen = quote! {
        use diesel::prelude::*;

        impl crate::Update for #typename {
            fn update(#paramname: #typename, conn: &PgConnection) -> QueryResult<Self> {
                diesel::update(#tablename::table.find(#paramname.id))
                    .set(#paramname)
                    .get_result(conn)
            }
        }
    };
    gen.into()
}

pub fn impl_check_user_id(ast: &syn::DeriveInput) -> TokenStream {
    let typename = &ast.ident;
    let (idtypename, _, _, tablename) = get_identifiers(typename);

    let gen = quote! {
        use diesel::prelude::*;

        impl crate::CheckUserId for #typename {
            type Id = #idtypename;

            fn check_user_id(id: Self::Id, user_id: UserId, conn: &PgConnection) -> QueryResult<bool> {
                #tablename::table
                    .filter(#tablename::columns::id.eq(id))
                    .filter(#tablename::columns::user_id.eq(user_id))
                    .count()
                    .get_result(conn)
                    .map(|count: i64| count == 1)
            }

            fn check_user_ids(
                ids: &Vec<Self::Id>,
                user_id: UserId,
                conn: &PgConnection,
            ) -> QueryResult<bool> {
                #tablename::table
                    .filter(#tablename::columns::id.eq_any(ids))
                    .filter(#tablename::columns::user_id.eq(user_id))
                    .count()
                    .get_result(conn)
                    .map(|count: i64| count == ids.len() as i64)
            }
        }
    };
    gen.into()
}

pub fn impl_check_ap_id(ast: &syn::DeriveInput) -> TokenStream {
    let typename = &ast.ident;
    let (idtypename, _, _, tablename) = get_identifiers(typename);

    let gen = quote! {
        use diesel::prelude::*;

        impl crate::CheckAPId for #typename {
            type Id = #idtypename;

            fn check_ap_id(id: Self::Id, ap_id: ActionProviderId, conn: &PgConnection) -> QueryResult<bool> {
                #tablename::table
                    .filter(#tablename::columns::id.eq(id))
                    .filter(#tablename::columns::action_provider_id.eq(ap_id))
                    .count()
                    .get_result(conn)
                    .map(|count: i64| count == 1)
            }

            fn check_ap_ids(
                ids: &Vec<Self::Id>,
                ap_id: ActionProviderId,
                conn: &PgConnection,
            ) -> QueryResult<bool> {
                #tablename::table
                    .filter(#tablename::columns::id.eq_any(ids))
                    .filter(#tablename::columns::action_provider_id.eq(ap_id))
                    .count()
                    .get_result(conn)
                    .map(|count: i64| count == ids.len() as i64)
            }
        }
    };
    gen.into()
}
