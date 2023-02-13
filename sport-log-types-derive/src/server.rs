use proc_macro::TokenStream;
use quote::quote;

use crate::Identifiers;

pub(crate) fn impl_db(
    Identifiers {
        db_type,
        entity_type,
        id_type,
        ..
    }: Identifiers,
) -> TokenStream {
    quote! {
        impl crate::db::Db for #db_type {
            type Id = sport_log_types::#id_type;
            type Entity = sport_log_types::#entity_type;
        }
    }
    .into()
}

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

pub(crate) fn impl_verify_id_for_user(
    Identifiers {
        db_type, id_type, ..
    }: Identifiers,
) -> TokenStream {
    quote! {
        impl crate::db::VerifyIdForUser for crate::db::UnverifiedId<sport_log_types::#id_type> {
            type Id = sport_log_types::#id_type;

            fn verify_user(
                self,
                auth: crate::auth::AuthUser,
                db: &mut diesel::pg::PgConnection,
            ) -> Result<Self::Id, axum::http::StatusCode> {
                use crate::db::CheckUserId;

                if crate::db::#db_type::check_user_id(self.0, *auth, db)
                    .map_err(|_| axum::http::StatusCode::INTERNAL_SERVER_ERROR)?
                {
                    Ok(self.0)
                } else {
                    Err(axum::http::StatusCode::FORBIDDEN)
                }
            }
        }

        impl crate::db::VerifyIdsForUser for crate::db::UnverifiedIds<sport_log_types::#id_type> {
            type Id = sport_log_types::#id_type;

            fn verify_user(
                self,
                auth: crate::auth::AuthUser,
                db: &mut diesel::pg::PgConnection,
            ) -> Result<Vec<Self::Id>, axum::http::StatusCode> {
                use crate::db::CheckUserId;

                if crate::db::#db_type::check_user_ids(&self.0, *auth, db)
                    .map_err(|_| axum::http::StatusCode::INTERNAL_SERVER_ERROR)?
                {
                    Ok(self.0)
                } else {
                    Err(axum::http::StatusCode::FORBIDDEN)
                }
            }
        }
    }
    .into()
}

pub(crate) fn impl_verify_id_for_user_or_ap(
    Identifiers {
        db_type, id_type, ..
    }: Identifiers,
) -> TokenStream {
    quote! {
        impl crate::db::VerifyIdForUserOrAP for crate::db::UnverifiedId<sport_log_types::#id_type> {
            type Id = sport_log_types::#id_type;

            fn verify_user_ap(
                self,
                auth: crate::auth::AuthUserOrAP,
                db: &mut diesel::pg::PgConnection,
            ) -> Result<Self::Id, axum::http::StatusCode> {
                use crate::db::CheckUserId;

                if crate::db::#db_type::check_user_id(self.0, *auth, db)
                    .map_err(|_| axum::http::StatusCode::INTERNAL_SERVER_ERROR)?
                {
                    Ok(self.0)
                } else {
                    Err(axum::http::StatusCode::FORBIDDEN)
                }
            }
        }

        impl crate::db::VerifyIdsForUserOrAP for crate::db::UnverifiedIds<sport_log_types::#id_type> {
            type Id = sport_log_types::#id_type;

            fn verify_user_ap(
                self,
                auth: crate::auth::AuthUserOrAP,
                db: &mut diesel::pg::PgConnection,
            ) -> Result<Vec<Self::Id>, axum::http::StatusCode> {
                use crate::db::CheckUserId;

                if crate::db::#db_type::check_user_ids(&self.0, *auth, db)
                    .map_err(|_| axum::http::StatusCode::INTERNAL_SERVER_ERROR)?
                {
                    Ok(self.0)
                } else {
                    Err(axum::http::StatusCode::FORBIDDEN)
                }
            }
        }
    }
    .into()
}

pub(crate) fn impl_verify_id_for_action_provider(
    Identifiers {
        db_type, id_type, ..
    }: Identifiers,
) -> TokenStream {
    quote! {
        impl crate::db::VerifyIdForActionProvider for crate::db::UnverifiedId<sport_log_types::#id_type> {
            type Id = sport_log_types::#id_type;

            fn verify_ap(
                self,
                auth: crate::auth::AuthAP,
                db: &mut diesel::pg::PgConnection,
            ) -> Result<sport_log_types::#id_type, axum::http::StatusCode> {
                use crate::db::CheckAPId;

                if crate::db::#db_type::check_ap_id(self.0, *auth, db)
                    .map_err(|_| axum::http::StatusCode::INTERNAL_SERVER_ERROR)?
                {
                    Ok(self.0)
                } else {
                    Err(axum::http::StatusCode::FORBIDDEN)
                }
            }
        }

        impl crate::db::VerifyIdsForActionProvider for crate::db::UnverifiedIds<sport_log_types::#id_type> {
            type Id = sport_log_types::#id_type;

            fn verify_ap(
                self,
                auth: crate::auth::AuthAP,
                db: &mut diesel::pg::PgConnection,
            ) -> Result<Vec<sport_log_types::#id_type>, axum::http::StatusCode> {
                use crate::db::CheckAPId;

                if crate::db::#db_type::check_ap_ids(&self.0, *auth, db)
                    .map_err(|_| axum::http::StatusCode::INTERNAL_SERVER_ERROR)?
                {
                    Ok(self.0)
                } else {
                    Err(axum::http::StatusCode::FORBIDDEN)
                }
            }
        }
    }
    .into()
}

pub(crate) fn impl_verify_id_for_admin(Identifiers { id_type, .. }: Identifiers) -> TokenStream {
    quote! {
        impl crate::db::VerifyIdForAdmin for crate::db::UnverifiedId<sport_log_types::#id_type> {
            type Id = sport_log_types::#id_type;

            fn verify_adm(
                self,
                auth: crate::auth::AuthAdmin,
            ) -> Result<sport_log_types::#id_type, axum::http::StatusCode> {
                Ok(self.0)
            }
        }

        impl crate::db::VerifyIdsForAdmin for crate::db::UnverifiedIds<sport_log_types::#id_type> {
            type Id = sport_log_types::#id_type;

            fn verify_adm(
                self,
                auth: crate::auth::AuthAdmin,
            ) -> Result<Vec<sport_log_types::#id_type>, axum::http::StatusCode> {
                Ok(self.0)
            }
        }
    }
    .into()
}

pub(crate) fn impl_verify_id_unchecked(Identifiers { id_type, .. }: Identifiers) -> TokenStream {
    quote! {
        impl crate::db::VerifyIdUnchecked for crate::db::UnverifiedId<sport_log_types::#id_type> {
            type Id = sport_log_types::#id_type;

            fn verify_unchecked(
                self,
            ) -> Result<sport_log_types::#id_type, axum::http::StatusCode> {
                Ok(self.0)
            }
        }
    }
    .into()
}

pub(crate) fn impl_verify_for_user_with_db(
    Identifiers {
        db_type,
        entity_type,
        ..
    }: Identifiers,
) -> TokenStream {
    quote! {
        impl crate::db::VerifyForUserWithDb for crate::db::Unverified<sport_log_types::#entity_type> {
            type Entity = sport_log_types::#entity_type;

            fn verify_user(
                self,
                auth: crate::auth::AuthUser,
                db: &mut diesel::pg::PgConnection,
            ) -> Result<Self::Entity, axum::http::StatusCode> {
                use crate::db::CheckUserId;

                let entity = self.0;
                if entity.user_id == *auth
                    && crate::db::#db_type::check_user_id(entity.id, *auth, db)
                    .map_err(|_| axum::http::StatusCode::INTERNAL_SERVER_ERROR)?
                {
                    Ok(entity)
                } else {
                    Err(axum::http::StatusCode::FORBIDDEN)
                }
            }
        }

        impl crate::db::VerifyMultipleForUserWithDb for crate::db::Unverified<Vec<sport_log_types::#entity_type>> {
            type Entity = sport_log_types::#entity_type;

            fn verify_user(
                self,
                auth: crate::auth::AuthUser,
                db: &mut diesel::pg::PgConnection,
            ) -> Result<Vec<Self::Entity>, axum::http::StatusCode> {
                use crate::db::CheckUserId;

                let entities = self.0;
                let ids: Vec<_> = entities.iter().map(|entity| entity.id).collect();
                if entities.iter().all(|entity| entity.user_id == *auth)
                    && crate::db::#db_type::check_user_ids(&ids, *auth, db)
                    .map_err(|_| axum::http::StatusCode::INTERNAL_SERVER_ERROR)?
                {
                    Ok(entities)
                } else {
                    Err(axum::http::StatusCode::FORBIDDEN)
                }
            }
        }
    }
    .into()
}

pub(crate) fn impl_verify_for_user_or_ap_with_db(
    Identifiers {
        db_type,
        entity_type,
        ..
    }: Identifiers,
) -> TokenStream {
    quote! {
        impl crate::db::VerifyForUserOrAPWithDb for crate::db::Unverified<sport_log_types::#entity_type> {
            type Entity = sport_log_types::#entity_type;

            fn verify_user_ap(
                self,
                auth: crate::auth::AuthUserOrAP,
                db: &mut diesel::pg::PgConnection,
            ) -> Result<Self::Entity, axum::http::StatusCode> {
                use crate::db::CheckUserId;

                let entity = self.0;
                if entity.user_id == *auth
                    && crate::db::#db_type::check_user_id(entity.id, *auth, db)
                    .map_err(|_| axum::http::StatusCode::INTERNAL_SERVER_ERROR)?
                {
                    Ok(entity)
                } else {
                    Err(axum::http::StatusCode::FORBIDDEN)
                }
            }
        }

        impl crate::db::VerifyMultipleForUserOrAPWithDb for crate::db::Unverified<Vec<sport_log_types::#entity_type>> {
            type Entity = sport_log_types::#entity_type;

            fn verify_user_ap(
                self,
                auth: crate::auth::AuthUserOrAP,
                db: &mut diesel::pg::PgConnection,
            ) -> Result<Vec<Self::Entity>, axum::http::StatusCode> {
                use crate::db::CheckUserId;

                let entities = self.0;
                let ids: Vec<_> = entities.iter().map(|entity| entity.id).collect();
                if entities.iter().all(|entity| entity.user_id == *auth)
                    && crate::db::#db_type::check_user_ids(&ids, *auth, db)
                    .map_err(|_| axum::http::StatusCode::INTERNAL_SERVER_ERROR)?
                {
                    Ok(entities)
                } else {
                    Err(axum::http::StatusCode::FORBIDDEN)
                }
            }
        }
    }
    .into()
}

pub(crate) fn impl_verify_for_user_without_db(
    Identifiers { entity_type, .. }: Identifiers,
) -> TokenStream {
    quote! {
        impl crate::db::VerifyForUserWithoutDb for crate::db::Unverified<sport_log_types::#entity_type> {
            type Entity = sport_log_types::#entity_type;

            fn verify_user_without_db(
                self,
                auth: crate::auth::AuthUser,
            ) -> Result<Self::Entity, axum::http::StatusCode> {
                let entity = self.0;
                if entity.user_id == *auth {
                    Ok(entity)
                } else {
                    Err(axum::http::StatusCode::FORBIDDEN)
                }
            }
        }

        impl crate::db::VerifyMultipleForUserWithoutDb for crate::db::Unverified<Vec<sport_log_types::#entity_type>> {
            type Entity = sport_log_types::#entity_type;

            fn verify_user_without_db(
                self,
                auth: crate::auth::AuthUser,
            ) -> Result<Vec<Self::Entity>, axum::http::StatusCode> {
                let entities = self.0;
                if entities.iter().all(|entity| entity.user_id == *auth) {
                    Ok(entities)
                } else {
                    Err(axum::http::StatusCode::FORBIDDEN)
                }
            }
        }
    }
    .into()
}

pub(crate) fn impl_verify_for_user_or_ap_without_db(
    Identifiers { entity_type, .. }: Identifiers,
) -> TokenStream {
    quote! {
        impl crate::db::VerifyForUserOrAPWithoutDb for crate::db::Unverified<sport_log_types::#entity_type> {
            type Entity = sport_log_types::#entity_type;

            fn verify_user_ap_without_db(
                self,
                auth: crate::auth::AuthUserOrAP,
            ) -> Result<Self::Entity, axum::http::StatusCode> {
                let entity = self.0;
                if entity.user_id == *auth {
                    Ok(entity)
                } else {
                    Err(axum::http::StatusCode::FORBIDDEN)
                }
            }
        }

        impl crate::db::VerifyMultipleForUserOrAPWithoutDb for crate::db::Unverified<Vec<sport_log_types::#entity_type>> {
            type Entity = sport_log_types::#entity_type;

            fn verify_user_ap_without_db(
                self,
                auth: crate::auth::AuthUserOrAP,
            ) -> Result<Vec<Self::Entity>, axum::http::StatusCode> {
                let entities = self.0;
                if entities.iter().all(|entity| entity.user_id == *auth) {
                    Ok(entities)
                } else {
                    Err(axum::http::StatusCode::FORBIDDEN)
                }
            }
        }
    }
    .into()
}

pub(crate) fn impl_verify_for_action_provider_with_db(
    Identifiers {
        db_type,
        entity_type,
        ..
    }: Identifiers,
) -> TokenStream {
    quote! {
        impl crate::db::VerifyForActionProviderWithDb for crate::db::Unverified<sport_log_types::#entity_type> {
            type Entity = sport_log_types::#entity_type;

            fn verify_ap(
                self,
                auth: crate::auth::AuthAP,
                db: &mut diesel::pg::PgConnection,
            ) -> Result<Self::Entity, axum::http::StatusCode> {
                use crate::db::CheckAPId;

                let entity = self.0;
                if entity.action_provider_id == *auth
                    && crate::db::#db_type::check_ap_id(entity.id, *auth, db)
                    .map_err(|_| axum::http::StatusCode::INTERNAL_SERVER_ERROR)?
                {
                    Ok(entity)
                } else {
                    Err(axum::http::StatusCode::FORBIDDEN)
                }
            }
        }
    }
    .into()
}

pub(crate) fn impl_verify_for_action_provider_without_db(
    Identifiers { entity_type, .. }: Identifiers,
) -> TokenStream {
    quote! {
        impl crate::db::VerifyForActionProviderWithoutDb for crate::db::Unverified<sport_log_types::#entity_type> {
            type Entity = sport_log_types::#entity_type;

            fn verify_ap_without_db(
                self,
                auth: crate::auth::AuthAP,
            ) -> Result<Self::Entity, axum::http::StatusCode> {
                let entity = self.0;
                if entity.action_provider_id == *auth {
                    Ok(entity)
                } else {
                    Err(axum::http::StatusCode::FORBIDDEN)
                }
            }
        }

        impl crate::db::VerifyMultipleForActionProviderWithoutDb for crate::db::Unverified<Vec<sport_log_types::#entity_type>> {
            type Entity = sport_log_types::#entity_type;

            fn verify_ap_without_db(
                self,
                auth: crate::auth::AuthAP,
            ) -> Result<Vec<Self::Entity>, axum::http::StatusCode> {
                let entities = self.0;
                if entities.iter().all(|entity| entity.action_provider_id == *auth) {
                    Ok(entities)
                } else {
                    Err(axum::http::StatusCode::FORBIDDEN)
                }
            }
        }
    }
    .into()
}

pub(crate) fn impl_verify_for_admin_without_db(
    Identifiers { entity_type, .. }: Identifiers,
) -> TokenStream {
    quote! {
        impl crate::db::VerifyForAdminWithoutDb for crate::db::Unverified<sport_log_types::#entity_type> {
            type Entity = sport_log_types::#entity_type;

            fn verify_adm(
                self,
                auth: crate::auth::AuthAdmin,
            ) -> Result<Self::Entity, axum::http::StatusCode> {
                Ok(self.0)
            }
        }

        impl crate::db::VerifyMultipleForAdminWithoutDb for crate::db::Unverified<Vec<sport_log_types::#entity_type>> {
            type Entity = sport_log_types::#entity_type;

            fn verify_adm(
                self,
                auth: crate::auth::AuthAdmin,
            ) -> Result<Vec<Self::Entity>, axum::http::StatusCode> {
                Ok(self.0)
            }
        }
    }
    .into()
}

pub(crate) fn impl_verify_unchecked(Identifiers { entity_type, .. }: Identifiers) -> TokenStream {
    quote! {
        impl crate::db::VerifyUnchecked for crate::db::Unverified<sport_log_types::#entity_type> {
            type Entity = sport_log_types::#entity_type;

            fn verify_unchecked(
                self,
            ) -> Result<Self::Entity, axum::http::StatusCode> {
                Ok(self.0)
            }
        }
    }
    .into()
}
