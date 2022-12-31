extern crate proc_macro;

use inflector::Inflector;
use proc_macro::TokenStream;
use proc_macro2::{Ident, Span};
use quote::quote;

pub fn get_identifiers(typename: &Ident) -> (Ident, Ident, Ident, Ident) {
    let id_type_name = Ident::new((typename.to_string() + "Id").as_ref(), Span::call_site());
    let id_param_name = Ident::new(
        id_type_name.to_string().to_snake_case().as_ref(),
        Span::call_site(),
    );
    let param_name = Ident::new(
        typename.to_string().to_snake_case().as_ref(),
        Span::call_site(),
    );
    (id_type_name, param_name.clone(), id_param_name, param_name)
}

pub fn impl_create(ast: &syn::DeriveInput) -> TokenStream {
    let typename = &ast.ident;
    let (_, param_name, _, tablename) = get_identifiers(typename);

    let gen = quote! {
        use diesel::prelude::*;

        impl crate::Create for #typename {
            fn create(#param_name: Self, db: &mut PgConnection) -> QueryResult<usize> {
                diesel::insert_into(#tablename::table)
                    .values(#param_name)
                    .execute(db)
            }

            fn create_multiple(#param_name: Vec<Self>, db: &mut PgConnection) -> QueryResult<usize> {
                diesel::insert_into(#tablename::table)
                    .values(&#param_name)
                    .execute(db)
            }
        }
    };
    gen.into()
}

pub fn impl_get_by_id(ast: &syn::DeriveInput) -> TokenStream {
    let typename = &ast.ident;
    let (id_type_name, _, id_param_name, tablename) = get_identifiers(typename);

    let gen = quote! {
        use diesel::prelude::*;

        impl crate::GetById for #typename {
            type Id = #id_type_name;

            fn get_by_id(#id_param_name: Self::Id, db: &mut PgConnection) -> QueryResult<Self> {
                #tablename::table.find(#id_param_name).get_result(db)
            }
        }
    };
    gen.into()
}

pub fn impl_get_by_ids(ast: &syn::DeriveInput) -> TokenStream {
    let typename = &ast.ident;
    let (id_type_name, _, _, tablename) = get_identifiers(typename);

    let gen = quote! {
        use diesel::prelude::*;

        impl crate::GetByIds for #typename {
            type Id = #id_type_name;

            fn get_by_ids(ids: &[Self::Id], db: &mut PgConnection) -> QueryResult<Vec<Self>> {
                #tablename::table.filter(#tablename::columns::id.eq_any(ids)).get_results(db)
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
            fn get_by_user(user_id: crate::UserId, db: &mut PgConnection) -> QueryResult<Vec<Self>> {
                #tablename::table
                    .filter(#tablename::columns::user_id.eq(user_id))
                    .get_results(db)
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
                db: &mut PgConnection
            ) -> QueryResult<Vec<Self>> {
                #tablename::table
                    .filter(#tablename::columns::user_id.eq(user_id))
                    .filter(#tablename::columns::last_change.ge(last_sync))
                    .get_results(db)
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
            fn get_by_last_sync(last_sync: DateTime<Utc>, db: &mut PgConnection) -> QueryResult<Vec<Self>> {
                #tablename::table
                    .filter(#tablename::columns::last_change.ge(last_sync))
                    .get_results(db)
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
            fn get_all(db: &mut PgConnection) -> QueryResult<Vec<Self>> {
                #tablename::table.load(db)
            }
        }
    };
    gen.into()
}

pub fn impl_update(ast: &syn::DeriveInput) -> TokenStream {
    let typename = &ast.ident;
    let (_, param_name, _, tablename) = get_identifiers(typename);

    let gen = quote! {
        use diesel::prelude::*;

        impl crate::Update for #typename {
            fn update(#param_name: #typename, db: &mut PgConnection) -> QueryResult<usize> {
                diesel::update(#tablename::table.find(#param_name.id))
                    .set(#param_name)
                    .execute(db)
            }

            fn update_multiple(#param_name: Vec<#typename>, db: &mut PgConnection) -> QueryResult<usize> {
                db.transaction(|db| {
                    let len = #param_name.len();
                    for entity in #param_name {
                        diesel::update(#tablename::table.find(entity.id))
                            .set(entity)
                            .execute(db)?;
                    }

                    Ok(len)
                })
            }
        }
    };
    gen.into()
}

pub fn impl_hard_delete(ast: &syn::DeriveInput) -> TokenStream {
    let typename = &ast.ident;
    let (_, _, _, tablename) = get_identifiers(typename);

    let gen = quote! {
        use diesel::prelude::*;

        impl crate::HardDelete for #typename {
            fn hard_delete(last_change: DateTime<Utc>, db: &mut PgConnection) -> QueryResult<usize> {
                diesel::delete(
                    #tablename::table
                        .filter(#tablename::columns::deleted.eq(true))
                        .filter(#tablename::columns::last_change.le(last_change))
                ).execute(db)
            }
        }
    };
    gen.into()
}

pub fn impl_check_user_id(ast: &syn::DeriveInput) -> TokenStream {
    let typename = &ast.ident;
    let (id_type_name, _, _, tablename) = get_identifiers(typename);

    let gen = quote! {
        use diesel::prelude::*;

        impl crate::CheckUserId for #typename {
            type Id = #id_type_name;

            fn check_user_id(id: Self::Id, user_id: UserId, db: &mut PgConnection) -> QueryResult<bool> {
                #tablename::table
                    .filter(#tablename::columns::id.eq(id))
                    .filter(#tablename::columns::user_id.eq(user_id))
                    .count()
                    .get_result(db)
                    .map(|count: i64| count == 1)
            }

            fn check_user_ids(
                ids: &[Self::Id],
                user_id: UserId,
                db: &mut PgConnection,
            ) -> QueryResult<bool> {
                #tablename::table
                    .filter(#tablename::columns::id.eq_any(ids))
                    .filter(#tablename::columns::user_id.eq(user_id))
                    .count()
                    .get_result(db)
                    .map(|count: i64| count == ids.len() as i64)
            }
        }
    };
    gen.into()
}

pub fn impl_check_ap_id(ast: &syn::DeriveInput) -> TokenStream {
    let typename = &ast.ident;
    let (id_type_name, _, _, tablename) = get_identifiers(typename);

    let gen = quote! {
        use diesel::prelude::*;

        impl crate::CheckAPId for #typename {
            type Id = #id_type_name;

            fn check_ap_id(id: Self::Id, ap_id: ActionProviderId, db: &mut PgConnection) -> QueryResult<bool> {
                #tablename::table
                    .filter(#tablename::columns::id.eq(id))
                    .filter(#tablename::columns::action_provider_id.eq(ap_id))
                    .count()
                    .get_result(db)
                    .map(|count: i64| count == 1)
            }

            fn check_ap_ids(
                ids: &[Self::Id],
                ap_id: ActionProviderId,
                db: &mut PgConnection,
            ) -> QueryResult<bool> {
                #tablename::table
                    .filter(#tablename::columns::id.eq_any(ids))
                    .filter(#tablename::columns::action_provider_id.eq(ap_id))
                    .count()
                    .get_result(db)
                    .map(|count: i64| count == ids.len() as i64)
            }
        }
    };
    gen.into()
}
