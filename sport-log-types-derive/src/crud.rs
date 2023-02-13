use proc_macro::TokenStream;
use quote::quote;

use crate::Identifiers;

pub(crate) fn impl_create(
    Identifiers {
        db_type,
        entity_name,
        ..
    }: Identifiers,
) -> TokenStream {
    quote! {
        use diesel::prelude::*;

        impl crate::db::Create for crate::db::#db_type {
            fn create(#entity_name: &Self::Entity, db: &mut PgConnection) -> QueryResult<usize> {
                diesel::insert_into(sport_log_types::schema::#entity_name::table)
                    .values(#entity_name)
                    .execute(db)
            }

            fn create_multiple(#entity_name: &[Self::Entity], db: &mut PgConnection) -> QueryResult<usize> {
                diesel::insert_into(sport_log_types::schema::#entity_name::table)
                    .values(#entity_name)
                    .execute(db)
            }
        }
    }
    .into()
}

pub(crate) fn impl_get_by_id(
    Identifiers {
        db_type,
        id_name,
        entity_name,
        ..
    }: Identifiers,
) -> TokenStream {
    quote! {
        use diesel::prelude::*;

        impl crate::db::GetById for crate::db::#db_type {
            fn get_by_id(#id_name: Self::Id, db: &mut PgConnection) -> QueryResult<Self::Entity> {
                sport_log_types::schema::#entity_name::table
                    .find(#id_name)
                    .select(Self::Entity::as_select())
                    .get_result(db)
            }
        }
    }
    .into()
}

pub(crate) fn impl_get_by_ids(
    Identifiers {
        db_type,
        entity_name,
        ..
    }: Identifiers,
) -> TokenStream {
    quote! {
        use diesel::prelude::*;

        impl crate::db::GetByIds for crate::db::#db_type {
            fn get_by_ids(ids: &[Self::Id], db: &mut PgConnection) -> QueryResult<Vec<Self::Entity>> {
                sport_log_types::schema::#entity_name::table
                    .filter(sport_log_types::schema::#entity_name::columns::id.eq_any(ids))
                    .select(Self::Entity::as_select())
                    .get_results(db)
            }
        }
    }
    .into()
}

pub(crate) fn impl_get_by_user(
    Identifiers {
        db_type,
        entity_name,
        ..
    }: Identifiers,
) -> TokenStream {
    quote! {
        use diesel::prelude::*;

        impl crate::db::GetByUser for crate::db::#db_type {
            fn get_by_user(user_id: sport_log_types::UserId, db: &mut PgConnection) -> QueryResult<Vec<Self::Entity>> {
                sport_log_types::schema::#entity_name::table
                    .filter(sport_log_types::schema::#entity_name::columns::user_id.eq(user_id))
                    .select(Self::Entity::as_select())
                    .get_results(db)
            }
        }
    }
    .into()
}

pub(crate) fn impl_get_by_user_and_last_sync(
    Identifiers {
        db_type,
        entity_name,
        ..
    }: Identifiers,
) -> TokenStream {
    quote! {
        use diesel::prelude::*;

        impl crate::db::GetByUserSync for crate::db::#db_type {
            fn get_by_user_and_last_sync(
                user_id: sport_log_types::UserId,
                last_sync: chrono::DateTime<chrono::Utc>,
                db: &mut PgConnection
            ) -> QueryResult<Vec<Self::Entity>> {
                sport_log_types::schema::#entity_name::table
                    .filter(sport_log_types::schema::#entity_name::columns::user_id.eq(user_id))
                    .filter(sport_log_types::schema::#entity_name::columns::last_change.ge(last_sync))
                    .select(Self::Entity::as_select())
                    .get_results(db)
            }
        }
    }
    .into()
}

pub(crate) fn impl_get_by_last_sync(
    Identifiers {
        db_type,
        entity_name,
        ..
    }: Identifiers,
) -> TokenStream {
    quote! {
        use diesel::prelude::*;

        impl crate::db::GetBySync for crate::db::#db_type {
            fn get_by_last_sync(last_sync: chrono::DateTime<chrono::Utc>, db: &mut PgConnection) -> QueryResult<Vec<Self::Entity>> {
                sport_log_types::schema::#entity_name::table
                    .filter(sport_log_types::schema::#entity_name::columns::last_change.ge(last_sync))
                    .select(Self::Entity::as_select())
                    .get_results(db)
            }
        }
    }
    .into()
}

pub(crate) fn impl_get_all(
    Identifiers {
        db_type,
        entity_name,
        ..
    }: Identifiers,
) -> TokenStream {
    quote! {
        use diesel::prelude::*;

        impl crate::db::GetAll for crate::db::#db_type {
            fn get_all(db: &mut PgConnection) -> QueryResult<Vec<Self::Entity>> {
                sport_log_types::schema::#entity_name::table.select(Self::Entity::as_select()).load(db)
            }
        }
    }
    .into()
}

pub(crate) fn impl_update(
    Identifiers {
        db_type,
        entity_name,
        ..
    }: Identifiers,
) -> TokenStream {
    quote! {
        use diesel::prelude::*;

        impl crate::db::Update for crate::db::#db_type {
            fn update(#entity_name: &Self::Entity, db: &mut PgConnection) -> QueryResult<usize> {
                diesel::update(sport_log_types::schema::#entity_name::table.find(#entity_name.id))
                    .set(#entity_name)
                    .execute(db)
            }

            fn update_multiple(#entity_name: &[Self::Entity], db: &mut PgConnection) -> QueryResult<usize> {
                db.transaction(|db| {
                    let len = #entity_name.len();
                    for entity in #entity_name {
                        diesel::update(sport_log_types::schema::#entity_name::table.find(entity.id))
                            .set(entity)
                            .execute(db)?;
                    }

                    Ok(len)
                })
            }
        }
    }
    .into()
}

pub(crate) fn impl_hard_delete(
    Identifiers {
        db_type,
        entity_name,
        ..
    }: Identifiers,
) -> TokenStream {
    quote! {
        use diesel::prelude::*;

        impl crate::db::HardDelete for crate::db::#db_type {
            fn hard_delete(last_change: chrono::DateTime<chrono::Utc>, db: &mut PgConnection) -> QueryResult<usize> {
                diesel::delete(
                    sport_log_types::schema::#entity_name::table
                        .filter(sport_log_types::schema::#entity_name::columns::deleted.eq(true))
                        .filter(sport_log_types::schema::#entity_name::columns::last_change.le(last_change))
                ).execute(db)
            }
        }
    }
    .into()
}

pub(crate) fn impl_check_user_id(
    Identifiers {
        db_type,
        id_type,
        entity_name,
        ..
    }: Identifiers,
) -> TokenStream {
    quote! {
        use diesel::prelude::*;

        impl crate::db::CheckUserId for crate::db::#db_type {
            type Id = sport_log_types::#id_type;

            fn check_user_id(id: Self::Id, user_id: sport_log_types::UserId, db: &mut PgConnection) -> QueryResult<bool> {
                sport_log_types::schema::#entity_name::table
                    .filter(sport_log_types::schema::#entity_name::columns::id.eq(id))
                    .filter(sport_log_types::schema::#entity_name::columns::user_id.eq(user_id))
                    .count()
                    .get_result(db)
                    .map(|count: i64| count == 1)
            }

            fn check_user_ids(
                ids: &[Self::Id],
                user_id: sport_log_types::UserId,
                db: &mut PgConnection,
            ) -> QueryResult<bool> {
                sport_log_types::schema::#entity_name::table
                    .filter(sport_log_types::schema::#entity_name::columns::id.eq_any(ids))
                    .filter(sport_log_types::schema::#entity_name::columns::user_id.eq(user_id))
                    .count()
                    .get_result(db)
                    .map(|count: i64| count == ids.len() as i64)
            }
        }
    }
    .into()
}

pub(crate) fn impl_check_ap_id(
    Identifiers {
        db_type,
        id_type,
        entity_name,
        ..
    }: Identifiers,
) -> TokenStream {
    quote! {
        use diesel::prelude::*;

        impl crate::db::CheckAPId for crate::db::#db_type {
            type Id = sport_log_types::#id_type;

            fn check_ap_id(id: Self::Id, ap_id: ActionProviderId, db: &mut PgConnection) -> QueryResult<bool> {
                sport_log_types::schema::#entity_name::table
                    .filter(sport_log_types::schema::#entity_name::columns::id.eq(id))
                    .filter(sport_log_types::schema::#entity_name::columns::action_provider_id.eq(ap_id))
                    .count()
                    .get_result(db)
                    .map(|count: i64| count == 1)
            }

            fn check_ap_ids(
                ids: &[Self::Id],
                ap_id: ActionProviderId,
                db: &mut PgConnection,
            ) -> QueryResult<bool> {
                sport_log_types::schema::#entity_name::table
                    .filter(sport_log_types::schema::#entity_name::columns::id.eq_any(ids))
                    .filter(sport_log_types::schema::#entity_name::columns::action_provider_id.eq(ap_id))
                    .count()
                    .get_result(db)
                    .map(|count: i64| count == ids.len() as i64)
            }
        }
    }
    .into()
}
