use proc_macro::TokenStream;
use proc_macro2::Ident;
use quote::quote;

use crate::Identifiers;

pub(crate) fn impl_db(
    Identifiers {
        db_type,
        value_type,
        id_type,
        value_name,
        ..
    }: Identifiers,
) -> TokenStream {
    quote! {
        impl crate::db::Db for #db_type {
            type Id = sport_log_types::#id_type;
            type Type = sport_log_types::#value_type;
            type Table = sport_log_types::schema::#value_name::table;

            fn table() -> Self::Table {
                sport_log_types::schema::#value_name::table
            }

            fn id_column() -> <Self::Table as Table>::PrimaryKey {
                sport_log_types::schema::#value_name::columns::id
            }
        }
    }
    .into()
}

pub(crate) fn impl_db_with_user_id(
    Identifiers {
        db_type,
        value_name,
        ..
    }: Identifiers,
) -> TokenStream {
    quote! {
        impl crate::db::DbWithUserId for #db_type {
            type UserIdColumn = sport_log_types::schema::#value_name::columns::user_id;

            fn user_id_column() -> Self::UserIdColumn {
                sport_log_types::schema::#value_name::columns::user_id
            }
        }
    }
    .into()
}

pub(crate) fn impl_db_with_ap_id(
    Identifiers {
        db_type,
        value_name,
        ..
    }: Identifiers,
) -> TokenStream {
    quote! {
        impl crate::db::DbWithApId for #db_type {
            type ApIdColumn = sport_log_types::schema::#value_name::columns::action_provider_id;

            fn ap_id_column() -> Self::ApIdColumn {
                sport_log_types::schema::#value_name::columns::action_provider_id
            }
        }
    }
    .into()
}

pub(crate) fn impl_db_with_datetime(
    Identifiers {
        db_type,
        value_name,
        ..
    }: Identifiers,
) -> TokenStream {
    quote! {
        impl crate::db::DbWithDateTime for #db_type {
            type DateTimeColumn = sport_log_types::schema::#value_name::columns::datetime;

            fn datetime_column() -> Self::DateTimeColumn {
                sport_log_types::schema::#value_name::columns::datetime
            }
        }
    }
    .into()
}

pub(crate) fn impl_modifiable_db(
    Identifiers {
        db_type,
        value_name,
        ..
    }: Identifiers,
) -> TokenStream {
    quote! {
        impl crate::db::ModifiableDb for #db_type {
            type LastChangeColumn = sport_log_types::schema::#value_name::columns::last_change;
            type DeletedColumn = sport_log_types::schema::#value_name::columns::deleted;

            fn last_change_column() -> Self::LastChangeColumn {
                sport_log_types::schema::#value_name::columns::last_change
            }

            fn deleted_column() -> Self::DeletedColumn {
                sport_log_types::schema::#value_name::columns::deleted
            }
        }
    }
    .into()
}

pub(crate) fn impl_create(db_type: &Ident) -> TokenStream {
    quote! {
        use diesel::prelude::*;

        impl crate::db::Create for crate::db::#db_type {
            fn create(value: &Self::Type, db: &mut PgConnection) -> QueryResult<usize> {
                use crate::db::Db;
                diesel::insert_into(Self::table())
                    .values(value)
                    .execute(db)
            }

            fn create_multiple(values: &[Self::Type], db: &mut PgConnection) -> QueryResult<usize> {
                use crate::db::Db;
                diesel::insert_into(Self::table())
                    .values(values)
                    .execute(db)
            }
        }
    }
    .into()
}

pub(crate) fn impl_get_by_id(db_type: &Ident) -> TokenStream {
    quote! {
        use diesel::prelude::*;

        impl crate::db::GetById for crate::db::#db_type {
            fn get_by_id(id: Self::Id, db: &mut PgConnection) -> QueryResult<Self::Type> {
                use crate::db::Db;
                Self::table()
                    .find(id)
                    .select(Self::Type::as_select())
                    .get_result(db)
            }
        }
    }
    .into()
}

pub(crate) fn impl_get_by_user(db_type: &Ident) -> TokenStream {
    quote! {
        use diesel::prelude::*;

        impl crate::db::GetByUser for crate::db::#db_type {
            fn get_by_user(user_id: sport_log_types::UserId, db: &mut PgConnection) -> QueryResult<Vec<Self::Type>> {
                use crate::db::{Db, DbWithUserId};
                Self::table()
                    .filter(Self::user_id_column().eq(user_id))
                    .select(Self::Type::as_select())
                    .get_results(db)
            }
        }
    }
    .into()
}

pub(crate) fn impl_get_by_user_and_timespan(db_type: &Ident) -> TokenStream {
    quote! {
        use diesel::prelude::*;

        impl crate::db::GetByUserTimespan for crate::db::#db_type {
            fn get_by_user_and_timespan(
                user_id: sport_log_types::UserId,
                timespan: crate::db::Timespan,
                db: &mut PgConnection
            ) -> QueryResult<Vec<Self::Type>> {
                use crate::db::{Db, DbWithUserId, DbWithDateTime};
                let filter_user = Self::table()
                    .filter(Self::user_id_column().eq(user_id));
                match timespan {
                    crate::db::Timespan::StartEnd(start, end) => {
                        filter_user
                            .filter(Self::datetime_column().between(start, end))
                            .select(Self::Type::as_select())
                            .get_results(db)
                    },
                    crate::db::Timespan::Start(start) => {
                        filter_user
                            .filter(Self::datetime_column().ge(start))
                            .select(Self::Type::as_select())
                            .get_results(db)
                    },
                    crate::db::Timespan::End(end) => {
                        filter_user
                            .filter(Self::datetime_column().le(end))
                            .select(Self::Type::as_select())
                            .get_results(db)
                    }
                    crate::db::Timespan::All => {
                        filter_user
                            .select(Self::Type::as_select())
                            .get_results(db)
                    }
                }
            }
        }
    }
    .into()
}

pub(crate) fn impl_get_by_user_and_last_sync(db_type: &Ident) -> TokenStream {
    quote! {
        use diesel::prelude::*;

        impl crate::db::GetByUserSync for crate::db::#db_type {
            fn get_by_user_and_last_sync(
                user_id: sport_log_types::UserId,
                last_sync: chrono::DateTime<chrono::Utc>,
                db: &mut PgConnection
            ) -> QueryResult<Vec<Self::Type>> {
                use crate::db::{Db, DbWithUserId, ModifiableDb};
                Self::table()
                    .filter(Self::user_id_column().eq(user_id))
                    .filter(Self::last_change_column().ge(last_sync))
                    .select(Self::Type::as_select())
                    .get_results(db)
            }
        }
    }
    .into()
}

pub(crate) fn impl_get_by_last_sync(db_type: &Ident) -> TokenStream {
    quote! {
        use diesel::prelude::*;

        impl crate::db::GetBySync for crate::db::#db_type {
            fn get_by_last_sync(last_sync: chrono::DateTime<chrono::Utc>, db: &mut PgConnection) -> QueryResult<Vec<Self::Type>> {
                use crate::db::{Db, ModifiableDb};
                Self::table()
                    .filter(Self::last_change_column().ge(last_sync))
                    .select(Self::Type::as_select())
                    .get_results(db)
            }
        }
    }
    .into()
}

pub(crate) fn impl_get_all(db_type: &Ident) -> TokenStream {
    quote! {
        use diesel::prelude::*;

        impl crate::db::GetAll for crate::db::#db_type {
            fn get_all(db: &mut PgConnection) -> QueryResult<Vec<Self::Type>> {
                use crate::db::Db;
                Self::table().select(Self::Type::as_select()).load(db)
            }
        }
    }
    .into()
}

pub(crate) fn impl_update(db_type: &Ident) -> TokenStream {
    quote! {
        use diesel::prelude::*;

        impl crate::db::Update for crate::db::#db_type {
            fn update(value: &Self::Type, db: &mut PgConnection) -> QueryResult<usize> {
                use crate::db::Db;
                diesel::update(Self::table().find(value.id))
                    .set(value)
                    .execute(db)
            }

            fn update_multiple(values: &[Self::Type], db: &mut PgConnection) -> QueryResult<usize> {
                use crate::db::Db;
                db.transaction(|db| {
                    let len = values.len();
                    for value in values {
                        diesel::update(Self::table().find(value.id))
                            .set(value)
                            .execute(db)?;
                    }

                    Ok(len)
                })
            }
        }
    }
    .into()
}

pub(crate) fn impl_hard_delete(db_type: &Ident) -> TokenStream {
    quote! {
        use diesel::prelude::*;

        impl crate::db::HardDelete for crate::db::#db_type {
            fn hard_delete(last_change: chrono::DateTime<chrono::Utc>, db: &mut PgConnection) -> QueryResult<usize> {
                use crate::db::{Db, ModifiableDb};
                diesel::delete(
                    Self::table()
                        .filter(Self::deleted_column().eq(true))
                        .filter(Self::last_change_column().le(last_change))
                ).execute(db)
            }
        }
    }
    .into()
}

pub(crate) fn impl_check_user_id(db_type: &Ident) -> TokenStream {
    quote! {
        use diesel::prelude::*;

        impl crate::db::CheckUserId for crate::db::#db_type {
            fn check_user_id(id: Self::Id, user_id: sport_log_types::UserId, db: &mut PgConnection) -> QueryResult<bool> {
                use crate::db::{Db, DbWithUserId};
                Self::table()
                    .filter(Self::id_column().eq(id))
                    .select(Self::user_id_column().eq(user_id))
                    .get_result(db)
                    .optional()
                    .map(|eq| eq.unwrap_or(false))
            }

            fn check_user_ids(
                ids: &[Self::Id],
                user_id: sport_log_types::UserId,
                db: &mut PgConnection,
            ) -> QueryResult<bool> {
                use crate::db::{Db, DbWithUserId};
                Self::table()
                    .filter(Self::id_column().eq_any(ids))
                    .select(Self::user_id_column().eq(user_id))
                    .get_results(db)
                    .map(|eqs: Vec<bool>| eqs.into_iter().all(|eq| eq))
            }
        }
    }
    .into()
}

pub(crate) fn impl_check_optional_user_id(db_type: &Ident) -> TokenStream {
    quote! {
        use diesel::prelude::*;

        impl crate::db::CheckOptionalUserId for crate::db::#db_type {
            fn check_optional_user_id(id: Self::Id, user_id: sport_log_types::UserId, db: &mut PgConnection) -> QueryResult<bool> {
                use crate::db::{Db, DbWithUserId};
                Self::table()
                    .filter(Self::id_column().eq(id))
                    .select(Self::user_id_column()
                        .is_not_distinct_from(user_id)
                        .or(Self::user_id_column().is_null())
                    )
                    .get_result(db)
                    .optional()
                    .map(|eq| eq.unwrap_or(false))
            }
        }

        impl crate::db::CheckUserId for crate::db::#db_type {
            fn check_user_id(id: Self::Id, user_id: sport_log_types::UserId, db: &mut PgConnection) -> QueryResult<bool> {
                use crate::db::Db;
                Self::table()
                    .filter(Self::id_column().eq(id))
                    .select(Self::user_id_column().is_not_distinct_from(user_id))
                    .get_result(db)
                    .optional()
                    .map(|eq| eq.unwrap_or(false))
            }

            fn check_user_ids(
                ids: &[Self::Id],
                user_id: sport_log_types::UserId,
                db: &mut PgConnection,
            ) -> QueryResult<bool> {
                use crate::db::Db;
                Self::table()
                    .filter(Self::id_column().eq_any(ids))
                    .select(Self::user_id_column().is_not_distinct_from(user_id))
                    .get_results(db)
                    .map(|eqs: Vec<bool>| eqs.into_iter().all(|eq| eq))
            }
        }
    }
    .into()
}

pub(crate) fn impl_check_ap_id(db_type: &Ident) -> TokenStream {
    quote! {
        use diesel::prelude::*;

        impl crate::db::CheckAPId for crate::db::#db_type {
            fn check_ap_id(id: Self::Id, ap_id: ActionProviderId, db: &mut PgConnection) -> QueryResult<bool> {
                use crate::db::{Db, DbWithApId};
                Self::table()
                    .filter(Self::id_column().eq(id))
                    .select(Self::ap_id_column().eq(ap_id))
                    .get_result(db)
                    .optional()
                    .map(|eq| eq.unwrap_or(false))
            }

            fn check_ap_ids(
                ids: &[Self::Id],
                ap_id: ActionProviderId,
                db: &mut PgConnection,
            ) -> QueryResult<bool> {
                use crate::db::Db;
                Self::table()
                    .filter(Self::id_column().eq_any(ids))
                    .select(Self::ap_id_column().eq(ap_id))
                    .get_results(db)
                    .map(|eqs: Vec<bool>| eqs.into_iter().all(|eq| eq))
            }
        }
    }
    .into()
}

pub(crate) fn impl_verify_id_for_user(db_type: &Ident) -> TokenStream {
    quote! {
        impl crate::db::VerifyIdForUser for crate::db::UnverifiedId<<#db_type as crate::db::Db>::Id> {
            type Id = <#db_type as crate::db::Db>::Id;

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
    }
    .into()
}

pub(crate) fn impl_verify_id_for_user_or_ap(db_type: &Ident) -> TokenStream {
    quote! {
        impl crate::db::VerifyIdForUserOrAP for crate::db::UnverifiedId<<#db_type as crate::db::Db>::Id> {
            type Id = <#db_type as crate::db::Db>::Id;
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
    }
    .into()
}

pub(crate) fn impl_verify_id_for_action_provider(db_type: &Ident) -> TokenStream {
    quote! {
        impl crate::db::VerifyIdForActionProvider for crate::db::UnverifiedId<<#db_type as crate::db::Db>::Id> {
            type Id = <#db_type as crate::db::Db>::Id;

            fn verify_ap(
                self,
                auth: crate::auth::AuthAP,
                db: &mut diesel::pg::PgConnection,
            ) -> Result<Self::Id, axum::http::StatusCode> {
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
    }
    .into()
}

pub(crate) fn impl_verify_ids_for_action_provider(db_type: &Ident) -> TokenStream {
    quote! {
        impl crate::db::VerifyIdsForActionProvider for crate::db::UnverifiedIds<<#db_type as crate::db::Db>::Id> {
            type Id = <#db_type as crate::db::Db>::Id;

            fn verify_ap(
                self,
                auth: crate::auth::AuthAP,
                db: &mut diesel::pg::PgConnection,
            ) -> Result<Vec<Self::Id>, axum::http::StatusCode> {
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

pub(crate) fn impl_verify_id_for_admin(db_type: &Ident) -> TokenStream {
    quote! {
        impl crate::db::VerifyIdForAdmin for crate::db::UnverifiedId<<#db_type as crate::db::Db>::Id> {
            type Id = <#db_type as crate::db::Db>::Id;

            fn verify_adm(
                self,
                auth: crate::auth::AuthAdmin,
            ) -> Result<Self::Id, axum::http::StatusCode> {
                Ok(self.0)
            }
        }
    }
    .into()
}

pub(crate) fn impl_verify_ids_for_admin(db_type: &Ident) -> TokenStream {
    quote! {
        impl crate::db::VerifyIdsForAdmin for crate::db::UnverifiedIds<<#db_type as crate::db::Db>::Id> {
            type Id = <#db_type as crate::db::Db>::Id;

            fn verify_adm(
                self,
                auth: crate::auth::AuthAdmin,
            ) -> Result<Vec<Self::Id>, axum::http::StatusCode> {
                Ok(self.0)
            }
        }
    }
    .into()
}

pub(crate) fn impl_verify_id_unchecked(db_type: &Ident) -> TokenStream {
    quote! {
        impl crate::db::VerifyIdUnchecked for crate::db::UnverifiedId<<#db_type as crate::db::Db>::Id> {
            type Id = <#db_type as crate::db::Db>::Id;

            fn verify_unchecked(
                self,
            ) -> Result<Self::Id, axum::http::StatusCode> {
                Ok(self.0)
            }
        }
    }
    .into()
}

pub(crate) fn impl_verify_for_user_with_db(db_type: &Ident) -> TokenStream {
    quote! {
        impl crate::db::VerifyForUserWithDb for crate::db::Unverified<<#db_type as crate::db::Db>::Type> {
            type Type = <#db_type as crate::db::Db>::Type;

            fn verify_user(
                self,
                auth: crate::auth::AuthUser,
                db: &mut diesel::pg::PgConnection,
            ) -> Result<Self::Type, axum::http::StatusCode> {
                use crate::db::CheckUserId;

                let value = self.0;
                if value.user_id == *auth
                    && crate::db::#db_type::check_user_id(value.id, *auth, db)
                    .map_err(|_| axum::http::StatusCode::INTERNAL_SERVER_ERROR)?
                {
                    Ok(value)
                } else {
                    Err(axum::http::StatusCode::FORBIDDEN)
                }
            }
        }

        impl crate::db::VerifyMultipleForUserWithDb for crate::db::Unverified<Vec<<#db_type as crate::db::Db>::Type>> {
            type Type = <#db_type as crate::db::Db>::Type;

            fn verify_user(
                self,
                auth: crate::auth::AuthUser,
                db: &mut diesel::pg::PgConnection,
            ) -> Result<Vec<Self::Type>, axum::http::StatusCode> {
                use crate::db::CheckUserId;

                let values = self.0;
                let ids: Vec<_> = values.iter().map(|value| value.id).collect();
                if values.iter().all(|value| value.user_id == *auth)
                    && crate::db::#db_type::check_user_ids(&ids, *auth, db)
                    .map_err(|_| axum::http::StatusCode::INTERNAL_SERVER_ERROR)?
                {
                    Ok(values)
                } else {
                    Err(axum::http::StatusCode::FORBIDDEN)
                }
            }
        }
    }
    .into()
}

pub(crate) fn impl_verify_for_user_or_ap_with_db(db_type: &Ident) -> TokenStream {
    quote! {
        impl crate::db::VerifyForUserOrAPWithDb for crate::db::Unverified<<#db_type as crate::db::Db>::Type> {
            type Type = <#db_type as crate::db::Db>::Type;

            fn verify_user_ap(
                self,
                auth: crate::auth::AuthUserOrAP,
                db: &mut diesel::pg::PgConnection,
            ) -> Result<Self::Type, axum::http::StatusCode> {
                use crate::db::CheckUserId;

                let value = self.0;
                if value.user_id == *auth
                    && crate::db::#db_type::check_user_id(value.id, *auth, db)
                    .map_err(|_| axum::http::StatusCode::INTERNAL_SERVER_ERROR)?
                {
                    Ok(value)
                } else {
                    Err(axum::http::StatusCode::FORBIDDEN)
                }
            }
        }

        impl crate::db::VerifyMultipleForUserOrAPWithDb for crate::db::Unverified<Vec<<#db_type as crate::db::Db>::Type>> {
            type Type = <#db_type as crate::db::Db>::Type;

            fn verify_user_ap(
                self,
                auth: crate::auth::AuthUserOrAP,
                db: &mut diesel::pg::PgConnection,
            ) -> Result<Vec<Self::Type>, axum::http::StatusCode> {
                use crate::db::CheckUserId;

                let values = self.0;
                let ids: Vec<_> = values.iter().map(|value| value.id).collect();
                if values.iter().all(|value| value.user_id == *auth)
                    && crate::db::#db_type::check_user_ids(&ids, *auth, db)
                    .map_err(|_| axum::http::StatusCode::INTERNAL_SERVER_ERROR)?
                {
                    Ok(values)
                } else {
                    Err(axum::http::StatusCode::FORBIDDEN)
                }
            }
        }
    }
    .into()
}

pub(crate) fn impl_verify_for_user_without_db(db_type: &Ident) -> TokenStream {
    quote! {
        impl crate::db::VerifyForUserWithoutDb for crate::db::Unverified<<#db_type as crate::db::Db>::Type> {
            type Type = <#db_type as crate::db::Db>::Type;

            fn verify_user_without_db(
                self,
                auth: crate::auth::AuthUser,
            ) -> Result<Self::Type, axum::http::StatusCode> {
                let value = self.0;
                if value.user_id == *auth {
                    Ok(value)
                } else {
                    Err(axum::http::StatusCode::FORBIDDEN)
                }
            }
        }

        impl crate::db::VerifyMultipleForUserWithoutDb for crate::db::Unverified<Vec<<#db_type as crate::db::Db>::Type>> {
            type Type = <#db_type as crate::db::Db>::Type;

            fn verify_user_without_db(
                self,
                auth: crate::auth::AuthUser,
            ) -> Result<Vec<Self::Type>, axum::http::StatusCode> {
                let values = self.0;
                if values.iter().all(|value| value.user_id == *auth) {
                    Ok(values)
                } else {
                    Err(axum::http::StatusCode::FORBIDDEN)
                }
            }
        }
    }
    .into()
}

pub(crate) fn impl_verify_for_user_or_ap_without_db(db_type: &Ident) -> TokenStream {
    quote! {
        impl crate::db::VerifyForUserOrAPWithoutDb for crate::db::Unverified<<#db_type as crate::db::Db>::Type> {
            type Type = <#db_type as crate::db::Db>::Type;

            fn verify_user_ap_without_db(
                self,
                auth: crate::auth::AuthUserOrAP,
            ) -> Result<Self::Type, axum::http::StatusCode> {
                let value = self.0;
                if value.user_id == *auth {
                    Ok(value)
                } else {
                    Err(axum::http::StatusCode::FORBIDDEN)
                }
            }
        }

        impl crate::db::VerifyMultipleForUserOrAPWithoutDb for crate::db::Unverified<Vec<<#db_type as crate::db::Db>::Type>> {
            type Type = <#db_type as crate::db::Db>::Type;

            fn verify_user_ap_without_db(
                self,
                auth: crate::auth::AuthUserOrAP,
            ) -> Result<Vec<Self::Type>, axum::http::StatusCode> {
                let values = self.0;
                if values.iter().all(|value| value.user_id == *auth) {
                    Ok(values)
                } else {
                    Err(axum::http::StatusCode::FORBIDDEN)
                }
            }
        }
    }
    .into()
}

pub(crate) fn impl_verify_for_action_provider_with_db(db_type: &Ident) -> TokenStream {
    quote! {
        impl crate::db::VerifyForActionProviderWithDb for crate::db::Unverified<<#db_type as crate::db::Db>::Type> {
            type Type = <#db_type as crate::db::Db>::Type;

            fn verify_ap(
                self,
                auth: crate::auth::AuthAP,
                db: &mut diesel::pg::PgConnection,
            ) -> Result<Self::Type, axum::http::StatusCode> {
                use crate::db::CheckAPId;

                let value = self.0;
                if value.action_provider_id == *auth
                    && crate::db::#db_type::check_ap_id(value.id, *auth, db)
                    .map_err(|_| axum::http::StatusCode::INTERNAL_SERVER_ERROR)?
                {
                    Ok(value)
                } else {
                    Err(axum::http::StatusCode::FORBIDDEN)
                }
            }
        }
    }
    .into()
}

pub(crate) fn impl_verify_for_action_provider_without_db(db_type: &Ident) -> TokenStream {
    quote! {
        impl crate::db::VerifyForActionProviderWithoutDb for crate::db::Unverified<<#db_type as crate::db::Db>::Type> {
            type Type = <#db_type as crate::db::Db>::Type;

            fn verify_ap_without_db(
                self,
                auth: crate::auth::AuthAP,
            ) -> Result<Self::Type, axum::http::StatusCode> {
                let value = self.0;
                if value.action_provider_id == *auth {
                    Ok(value)
                } else {
                    Err(axum::http::StatusCode::FORBIDDEN)
                }
            }
        }

        impl crate::db::VerifyMultipleForActionProviderWithoutDb for crate::db::Unverified<Vec<<#db_type as crate::db::Db>::Type>> {
            type Type = <#db_type as crate::db::Db>::Type;

            fn verify_ap_without_db(
                self,
                auth: crate::auth::AuthAP,
            ) -> Result<Vec<Self::Type>, axum::http::StatusCode> {
                let values = self.0;
                if values.iter().all(|value| value.action_provider_id == *auth) {
                    Ok(values)
                } else {
                    Err(axum::http::StatusCode::FORBIDDEN)
                }
            }
        }
    }
    .into()
}

pub(crate) fn impl_verify_for_admin_without_db(db_type: &Ident) -> TokenStream {
    quote! {
        impl crate::db::VerifyForAdminWithoutDb for crate::db::Unverified<<#db_type as crate::db::Db>::Type> {
            type Type = <#db_type as crate::db::Db>::Type;

            fn verify_adm(
                self,
                auth: crate::auth::AuthAdmin,
            ) -> Result<Self::Type, axum::http::StatusCode> {
                Ok(self.0)
            }
        }

        impl crate::db::VerifyMultipleForAdminWithoutDb for crate::db::Unverified<Vec<<#db_type as crate::db::Db>::Type>> {
            type Type = <#db_type as crate::db::Db>::Type;

            fn verify_adm(
                self,
                auth: crate::auth::AuthAdmin,
            ) -> Result<Vec<Self::Type>, axum::http::StatusCode> {
                Ok(self.0)
            }
        }
    }
    .into()
}

pub(crate) fn impl_verify_unchecked(db_type: &Ident) -> TokenStream {
    quote! {
        impl crate::db::VerifyUnchecked for crate::db::Unverified<<#db_type as crate::db::Db>::Type> {
            type Type = <#db_type as crate::db::Db>::Type;

            fn verify_unchecked(self) -> Result<Self::Type, axum::http::StatusCode> {

                Ok(self.0)
            }
        }
    }
    .into()
}
