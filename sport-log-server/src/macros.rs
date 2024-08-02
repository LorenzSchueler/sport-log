use derive_deftly::define_derive_deftly;

define_derive_deftly! {
    Create:

    #[async_trait::async_trait]
    impl crate::db::Create for crate::db::$ttype {
        async fn create(value: &Self::Type, db: &mut diesel_async::AsyncPgConnection) -> diesel::result::QueryResult<usize> {
            use crate::db::Db;
            use diesel_async::RunQueryDsl;

            diesel::insert_into(Self::table())
                .values(value)
                .execute(db)
                .await
        }

        async fn create_multiple(values: &[Self::Type], db: &mut diesel_async::AsyncPgConnection) -> diesel::result::QueryResult<usize> {
            use crate::db::Db;
            use diesel_async::RunQueryDsl;

            diesel::insert_into(Self::table())
                .values(values)
                .execute(db)
                .await
        }
    }
}

define_derive_deftly! {
    GetById:

    #[async_trait::async_trait]
    impl crate::db::GetById for crate::db::$ttype {
        async fn get_by_id(id: Self::Id, db: &mut diesel_async::AsyncPgConnection) -> diesel::result::QueryResult<Self::Type> {
            use crate::db::Db;
            use diesel_async::RunQueryDsl;
            use diesel::prelude::*;

            Self::table()
                .find(id)
                .select(Self::Type::as_select())
                .get_result(db)
                .await
        }
    }
}

define_derive_deftly! {
    GetByUser:

    #[async_trait::async_trait]
    impl crate::db::GetByUser for crate::db::$ttype {
        async fn get_by_user(
            user_id: sport_log_types::UserId,
            db: &mut diesel_async::AsyncPgConnection
        ) -> diesel::result::QueryResult<Vec<Self::Type>> {
            use crate::db::{Db, DbWithUserId};
            use diesel_async::RunQueryDsl;
            use diesel::prelude::*;

            Self::table()
                .filter(Self::user_id_column().eq(user_id))
                .select(Self::Type::as_select())
                .get_results(db)
                .await
        }
    }
}

define_derive_deftly! {
    GetByUserOptional:

    #[async_trait::async_trait]
    impl crate::db::GetByUser for crate::db::$ttype {
        async fn get_by_user(
            user_id: sport_log_types::UserId,
            db: &mut diesel_async::AsyncPgConnection
        ) -> diesel::result::QueryResult<Vec<Self::Type>> {
            use crate::db::{Db, DbWithUserId};
            use diesel_async::RunQueryDsl;
            use diesel::prelude::*;

            Self::table()
                .filter(Self::user_id_column().eq(user_id).or(Self::user_id_column().is_null()))
                .select(Self::Type::as_select())
                .get_results(db)
                .await
        }
    }
}

define_derive_deftly! {
    GetByUserTimespan:

    #[async_trait::async_trait]
    impl crate::db::GetByUserTimespan for crate::db::$ttype {
        async fn get_by_user_and_timespan(
            user_id: sport_log_types::UserId,
            timespan: crate::db::Timespan,
            db: &mut diesel_async::AsyncPgConnection
        ) -> diesel::result::QueryResult<Vec<Self::Type>> {
            use crate::db::{Db, DbWithUserId, DbWithDateTime};
            use diesel_async::RunQueryDsl;
            use diesel::prelude::*;

            let filter_user = Self::table()
                .filter(Self::user_id_column().eq(user_id));
            match timespan {
                crate::db::Timespan::StartEnd(start, end) => {
                    filter_user
                        .filter(Self::datetime_column().between(start, end))
                        .select(Self::Type::as_select())
                        .get_results(db)
                        .await
                },
                crate::db::Timespan::Start(start) => {
                    filter_user
                        .filter(Self::datetime_column().ge(start))
                        .select(Self::Type::as_select())
                        .get_results(db)
                        .await
                },
                crate::db::Timespan::End(end) => {
                    filter_user
                        .filter(Self::datetime_column().le(end))
                        .select(Self::Type::as_select())
                        .get_results(db)
                        .await
                }
                crate::db::Timespan::All => {
                    filter_user
                        .select(Self::Type::as_select())
                        .get_results(db)
                        .await
                }
            }
        }
    }
}

define_derive_deftly! {
    GetByUserAndEpoch:

    #[async_trait::async_trait]
    impl crate::db::GetByUserAndEpoch for crate::db::$ttype {
        async fn get_by_user_and_epoch(
            user_id: sport_log_types::UserId,
            epoch: i64,
            db: &mut diesel_async::AsyncPgConnection
        ) -> diesel::result::QueryResult<Vec<Self::Type>> {
            use crate::db::{Db, DbWithUserId, ModifiableDb};
            use diesel_async::RunQueryDsl;
            use diesel::prelude::*;

            Self::table()
                .filter(Self::user_id_column().eq(user_id))
                .filter(Self::epoch_column().gt(epoch))
                .select(Self::Type::as_select())
                .get_results(db)
                .await
        }
    }
}

define_derive_deftly! {
    GetByUserAndEpochOptional:

    #[async_trait::async_trait]
    impl crate::db::GetByUserAndEpoch for crate::db::$ttype {
        async fn get_by_user_and_epoch(
            user_id: sport_log_types::UserId,
            epoch: i64,
            db: &mut diesel_async::AsyncPgConnection
        ) -> diesel::result::QueryResult<Vec<Self::Type>> {
            use crate::db::{Db, DbWithUserId, ModifiableDb};
            use diesel_async::RunQueryDsl;
            use diesel::prelude::*;

            Self::table()
                .filter(Self::user_id_column().eq(user_id).or(Self::user_id_column().is_null()))
                .filter(Self::epoch_column().gt(epoch))
                .select(Self::Type::as_select())
                .get_results(db)
                .await
        }
    }
}

define_derive_deftly! {
    GetByEpoch:

    #[async_trait::async_trait]
    impl crate::db::GetByEpoch for crate::db::$ttype {
        async fn get_by_epoch(
            epoch: i64,
            db: &mut diesel_async::AsyncPgConnection
        ) -> diesel::result::QueryResult<Vec<Self::Type>> {
            use crate::db::{Db, ModifiableDb};
            use diesel_async::RunQueryDsl;
            use diesel::prelude::*;

            Self::table()
                .filter(Self::epoch_column().gt(epoch))
                .select(Self::Type::as_select())
                .get_results(db)
                .await
        }
    }
}

define_derive_deftly! {
    GetAll:

    #[async_trait::async_trait]
    impl crate::db::GetAll for crate::db::$ttype {
        async fn get_all(db: &mut diesel_async::AsyncPgConnection) -> diesel::result::QueryResult<Vec<Self::Type>> {
            use crate::db::Db;
            use diesel_async::RunQueryDsl;
            use diesel::prelude::*;

            Self::table().select(Self::Type::as_select()).load(db).await
        }
    }
}

define_derive_deftly! {
    Update:

    #[async_trait::async_trait]
    impl crate::db::Update for crate::db::$ttype {
        async fn update(value: &Self::Type, db: &mut diesel_async::AsyncPgConnection) -> diesel::result::QueryResult<usize> {
            use crate::db::Db;
            use diesel_async::RunQueryDsl;
            use diesel::prelude::*;

            diesel::update(Self::table().find(value.id))
                .set(value)
                .execute(db)
                .await
        }

        async fn update_multiple(values: &[Self::Type], db: &mut diesel_async::AsyncPgConnection) -> diesel::result::QueryResult<usize> {
            use crate::db::Db;
            use diesel_async::{RunQueryDsl, AsyncConnection, scoped_futures::ScopedFutureExt};
            use diesel::prelude::*;

            let len = values.len();
            db.transaction(|db| async move {
                for value in values {
                    diesel::update(Self::table().find(value.id))
                        .set(value)
                        .execute(db)
                        .await?;
                }

                Ok(len)
            }.scope_boxed()).await
        }
    }
}

define_derive_deftly! {
    GetEpochByUser:

    #[async_trait::async_trait]
    impl crate::db::GetEpochByUser for crate::db::$ttype {
        async fn get_epoch_by_user(
            user_id: sport_log_types::UserId,
            db: &mut diesel_async::AsyncPgConnection
        ) -> diesel::result::QueryResult<sport_log_types::Epoch> {
            use crate::db::{Db, DbWithUserId, ModifiableDb};
            use diesel_async::RunQueryDsl;
            use diesel::prelude::*;

            Self::table()
                .filter(Self::user_id_column().eq(user_id))
                .select(diesel::dsl::max(Self::epoch_column()))
                .get_result(db)
                .await
                .map(|epoch: Option<sport_log_types::Epoch>| epoch.unwrap_or(sport_log_types::Epoch(0)))
        }
    }
}

define_derive_deftly! {
    GetEpochByUserOptional:

    #[async_trait::async_trait]
    impl crate::db::GetEpochByUserOptional for crate::db::$ttype {
        async fn get_epoch_by_user_optional(
            user_id: sport_log_types::UserId,
            db: &mut diesel_async::AsyncPgConnection
        ) -> diesel::result::QueryResult<sport_log_types::Epoch> {
            use crate::db::{Db, DbWithUserId, ModifiableDb};
            use diesel_async::RunQueryDsl;
            use diesel::prelude::*;

            Self::table()
                .filter(Self::user_id_column()
                        .eq(user_id)
                        .or(Self::user_id_column().is_null()),
                )
                .select(diesel::dsl::max(Self::epoch_column()))
                .get_result(db)
                .await
                .map(|epoch: Option<sport_log_types::Epoch>| epoch.unwrap_or(sport_log_types::Epoch(0)))
        }
    }
}

define_derive_deftly! {
    GetEpoch:

    #[async_trait::async_trait]
    impl crate::db::GetEpoch for crate::db::$ttype {
        async fn get_epoch(
            db: &mut diesel_async::AsyncPgConnection
        ) -> diesel::result::QueryResult<sport_log_types::Epoch> {
            use crate::db::{Db, ModifiableDb};
            use diesel_async::RunQueryDsl;
            use diesel::prelude::*;

            Self::table()
                .select(diesel::dsl::max(Self::epoch_column()))
                .get_result(db)
                .await
                .map(|epoch: Option<sport_log_types::Epoch>| epoch.unwrap_or(sport_log_types::Epoch(0)))
        }
    }
}

define_derive_deftly! {
    CheckUserId:

    #[async_trait::async_trait]
    impl crate::db::CheckUserId for crate::db::$ttype {
        async fn check_user_id(id: Self::Id, user_id: sport_log_types::UserId, db: &mut diesel_async::AsyncPgConnection) -> diesel::result::QueryResult<bool> {
            use crate::db::{Db, DbWithUserId};
            use diesel_async::RunQueryDsl;
            use diesel::prelude::*;

            Self::table()
                .filter(Self::id_column().eq(id))
                .select(Self::user_id_column().eq(user_id))
                .get_result(db)
                .await
                .optional()
                .map(|eq| eq.unwrap_or(false))
        }

        async fn check_user_ids(
            ids: &[Self::Id],
            user_id: sport_log_types::UserId,
            db: &mut diesel_async::AsyncPgConnection,
        ) -> diesel::result::QueryResult<bool> {
            use crate::db::{Db, DbWithUserId};
            use diesel_async::RunQueryDsl;
            use diesel::prelude::*;

            Self::table()
                .filter(Self::id_column().eq_any(ids))
                .select(Self::user_id_column().eq(user_id))
                .get_results(db)
                .await
                .map(|eqs: Vec<bool>| eqs.into_iter().all(|eq| eq))
        }
    }
}

define_derive_deftly! {
    CheckOptionalUserId:

    #[async_trait::async_trait]
    impl crate::db::CheckOptionalUserId for crate::db::$ttype {
        async fn check_optional_user_id(id: Self::Id, user_id: sport_log_types::UserId, db: &mut diesel_async::AsyncPgConnection) -> diesel::result::QueryResult<bool> {
            use crate::db::{Db, DbWithUserId};
            use diesel_async::RunQueryDsl;
            use diesel::prelude::*;

            Self::table()
                .filter(Self::id_column().eq(id))
                .select(Self::user_id_column()
                    .is_not_distinct_from(user_id)
                    .or(Self::user_id_column().is_null())
                )
                .get_result(db)
                .await
                .optional()
                .map(|eq| eq.unwrap_or(false))
        }
    }

    #[async_trait::async_trait]
    impl crate::db::CheckUserId for crate::db::$ttype {
        async fn check_user_id(id: Self::Id, user_id: sport_log_types::UserId, db: &mut diesel_async::AsyncPgConnection) -> diesel::result::QueryResult<bool> {
            use crate::db::Db;
            use diesel_async::RunQueryDsl;
            use diesel::prelude::*;

            Self::table()
                .filter(Self::id_column().eq(id))
                .select(Self::user_id_column().is_not_distinct_from(user_id))
                .get_result(db)
                .await
                .optional()
                .map(|eq| eq.unwrap_or(false))
        }

        async fn check_user_ids(
            ids: &[Self::Id],
            user_id: sport_log_types::UserId,
            db: &mut diesel_async::AsyncPgConnection,
        ) -> diesel::result::QueryResult<bool> {
            use crate::db::Db;
            use diesel_async::RunQueryDsl;
            use diesel::prelude::*;

            Self::table()
                .filter(Self::id_column().eq_any(ids))
                .select(Self::user_id_column().is_not_distinct_from(user_id))
                .get_results(db)
                .await
                .map(|eqs: Vec<bool>| eqs.into_iter().all(|eq| eq))
        }
    }
}

define_derive_deftly! {
    CheckAPId:

    #[async_trait::async_trait]
    impl crate::db::CheckAPId for crate::db::$ttype {
        async fn check_ap_id(id: Self::Id, ap_id: ActionProviderId, db: &mut diesel_async::AsyncPgConnection) -> diesel::result::QueryResult<bool> {
            use crate::db::{Db, DbWithApId};
            use diesel_async::RunQueryDsl;
            use diesel::prelude::*;

            Self::table()
                .filter(Self::id_column().eq(id))
                .select(Self::ap_id_column().eq(ap_id))
                .get_result(db)
                .await
                .optional()
                .map(|eq| eq.unwrap_or(false))
        }

        async fn check_ap_ids(
            ids: &[Self::Id],
            ap_id: ActionProviderId,
            db: &mut diesel_async::AsyncPgConnection,
        ) -> diesel::result::QueryResult<bool> {
            use crate::db::Db;
            use diesel_async::RunQueryDsl;
            use diesel::prelude::*;

            Self::table()
                .filter(Self::id_column().eq_any(ids))
                .select(Self::ap_id_column().eq(ap_id))
                .get_results(db)
                .await
                .map(|eqs: Vec<bool>| eqs.into_iter().all(|eq| eq))
        }
    }
}

define_derive_deftly! {
    VerifyForUserGet:

    #[async_trait::async_trait]
    impl crate::db::VerifyForUserGet for crate::db::UnverifiedId<<$ttype as crate::db::Db>::Id> {
        type Id = <$ttype as crate::db::Db>::Id;

        async fn verify_user_get(
            self,
            auth: crate::auth::AuthUser,
            db: &mut diesel_async::AsyncPgConnection,
        ) -> Result<Self::Id, axum::http::StatusCode> {
            use crate::db::CheckUserId;

            if crate::db::$ttype::check_user_id(self.0, *auth, db)
                .await
                .map_err(|_| axum::http::StatusCode::INTERNAL_SERVER_ERROR)?
            {
                Ok(self.0)
            } else {
                Err(axum::http::StatusCode::FORBIDDEN)
            }
        }
    }
}

define_derive_deftly! {
    VerifyForUserOrAPGet:

    #[async_trait::async_trait]
    impl crate::db::VerifyForUserOrAPGet for crate::db::UnverifiedId<<$ttype as crate::db::Db>::Id> {
        type Id = <$ttype as crate::db::Db>::Id;

        async fn verify_user_ap_get(
            self,
            auth: crate::auth::AuthUserOrAP,
            db: &mut diesel_async::AsyncPgConnection,
        ) -> Result<Self::Id, axum::http::StatusCode> {
            use crate::db::CheckUserId;

            if crate::db::$ttype::check_user_id(self.0, *auth, db)
                .await
                .map_err(|_| axum::http::StatusCode::INTERNAL_SERVER_ERROR)?
            {
                Ok(self.0)
            } else {
                Err(axum::http::StatusCode::FORBIDDEN)
            }
        }
    }
}

define_derive_deftly! {
    VerifyForUserOrAPGetOptional:

    #[async_trait::async_trait]
    impl crate::db::VerifyForUserOrAPGet for crate::db::UnverifiedId<<$ttype as crate::db::Db>::Id> {
        type Id = <$ttype as crate::db::Db>::Id;

        async fn verify_user_ap_get(
            self,
            auth: crate::auth::AuthUserOrAP,
            db: &mut diesel_async::AsyncPgConnection,
        ) -> Result<Self::Id, axum::http::StatusCode> {
            use crate::db::CheckOptionalUserId;

            if crate::db::$ttype::check_optional_user_id(self.0, *auth, db)
                .await
                .map_err(|_| axum::http::StatusCode::INTERNAL_SERVER_ERROR)?
            {
                Ok(self.0)
            } else {
                Err(axum::http::StatusCode::FORBIDDEN)
            }
        }
    }
}

define_derive_deftly! {
    VerifyForActionProviderGet:

    #[async_trait::async_trait]
    impl crate::db::VerifyForActionProviderGet for crate::db::UnverifiedId<<$ttype as crate::db::Db>::Id> {
        type Id = <$ttype as crate::db::Db>::Id;

        async fn verify_ap_get(
            self,
            auth: crate::auth::AuthAP,
            db: &mut diesel_async::AsyncPgConnection,
        ) -> Result<Self::Id, axum::http::StatusCode> {
            use crate::db::CheckAPId;

            if crate::db::$ttype::check_ap_id(self.0, *auth, db)
                .await
                .map_err(|_| axum::http::StatusCode::INTERNAL_SERVER_ERROR)?
            {
                Ok(self.0)
            } else {
                Err(axum::http::StatusCode::FORBIDDEN)
            }
        }
    }
}

define_derive_deftly! {
    VerifyForActionProviderDisable:

    #[async_trait::async_trait]
    impl crate::db::VerifyForActionProviderDisable for crate::db::UnverifiedIds<<$ttype as crate::db::Db>::Id> {
        type Id = <$ttype as crate::db::Db>::Id;

        async fn verify_ap_disable(
            self,
            auth: crate::auth::AuthAP,
            db: &mut diesel_async::AsyncPgConnection,
        ) -> Result<Vec<Self::Id>, axum::http::StatusCode> {
            use crate::db::CheckAPId;

            if crate::db::$ttype::check_ap_ids(&self.0, *auth, db)
                .await
                .map_err(|_| axum::http::StatusCode::INTERNAL_SERVER_ERROR)?
            {
                Ok(self.0)
            } else {
                Err(axum::http::StatusCode::FORBIDDEN)
            }
        }
    }
}

define_derive_deftly! {
    VerifyForAdminGet:

    impl crate::db::VerifyForAdminGet for crate::db::UnverifiedId<<$ttype as crate::db::Db>::Id> {
        type Id = <$ttype as crate::db::Db>::Id;

        fn verify_adm_get(
            self,
            _auth: crate::auth::AuthAdmin,
        ) -> Result<Self::Id, axum::http::StatusCode> {
            Ok(self.0)
        }
    }
}

define_derive_deftly! {
    VerifyForAdminDelete:

    impl crate::db::VerifyForAdminDelete for crate::db::UnverifiedIds<<$ttype as crate::db::Db>::Id> {
        type Id = <$ttype as crate::db::Db>::Id;

        fn verify_adm_delete(
            self,
            _auth: crate::auth::AuthAdmin,
        ) -> Result<Vec<Self::Id>, axum::http::StatusCode> {
            Ok(self.0)
        }
    }
}

define_derive_deftly! {
    VerifyUncheckedGet:

    impl crate::db::VerifyUncheckedGet for crate::db::UnverifiedId<<$ttype as crate::db::Db>::Id> {
        type Id = <$ttype as crate::db::Db>::Id;

        fn verify_unchecked_get(self) -> Result<Self::Id, axum::http::StatusCode> {
            Ok(self.0)
        }
    }
}

define_derive_deftly! {
    VerifyForUserUpdate:

    #[async_trait::async_trait]
    impl crate::db::VerifyForUserUpdate for crate::db::Unverified<<$ttype as crate::db::Db>::Type> {
        type Type = <$ttype as crate::db::Db>::Type;

        async fn verify_user_update(
            self,
            auth: crate::auth::AuthUser,
            db: &mut diesel_async::AsyncPgConnection,
        ) -> Result<Self::Type, axum::http::StatusCode> {
            use crate::db::CheckUserId;

            let value = self.0;
            if value.user_id == *auth
                && crate::db::$ttype::check_user_id(value.id, *auth, db)
                .await
                .map_err(|_| axum::http::StatusCode::INTERNAL_SERVER_ERROR)?
            {
                Ok(value)
            } else {
                Err(axum::http::StatusCode::FORBIDDEN)
            }
        }
    }

    #[async_trait::async_trait]
    impl crate::db::VerifyMultipleForUserUpdate for crate::db::Unverified<Vec<<$ttype as crate::db::Db>::Type>> {
        type Type = <$ttype as crate::db::Db>::Type;

        async fn verify_user_update(
            self,
            auth: crate::auth::AuthUser,
            db: &mut diesel_async::AsyncPgConnection,
        ) -> Result<Vec<Self::Type>, axum::http::StatusCode> {
            use crate::db::CheckUserId;

            let values = self.0;
            let ids: Vec<_> = values.iter().map(|value| value.id).collect();
            if values.iter().all(|value| value.user_id == *auth)
                && crate::db::$ttype::check_user_ids(&ids, *auth, db)
                .await
                .map_err(|_| axum::http::StatusCode::INTERNAL_SERVER_ERROR)?
            {
                Ok(values)
            } else {
                Err(axum::http::StatusCode::FORBIDDEN)
            }
        }
    }
}

define_derive_deftly! {
    VerifyForUserOrAPUpdate:

    #[async_trait::async_trait]
    impl crate::db::VerifyForUserOrAPUpdate for crate::db::Unverified<<$ttype as crate::db::Db>::Type> {
        type Type = <$ttype as crate::db::Db>::Type;

        async fn verify_user_ap_update(
            self,
            auth: crate::auth::AuthUserOrAP,
            db: &mut diesel_async::AsyncPgConnection,
        ) -> Result<Self::Type, axum::http::StatusCode> {
            use crate::db::CheckUserId;

            let value = self.0;
            if value.user_id == *auth
                && crate::db::$ttype::check_user_id(value.id, *auth, db)
                .await
                .map_err(|_| axum::http::StatusCode::INTERNAL_SERVER_ERROR)?
            {
                Ok(value)
            } else {
                Err(axum::http::StatusCode::FORBIDDEN)
            }
        }
    }

    #[async_trait::async_trait]
    impl crate::db::VerifyMultipleForUserOrAPUpdate for crate::db::Unverified<Vec<<$ttype as crate::db::Db>::Type>> {
        type Type = <$ttype as crate::db::Db>::Type;

        async fn verify_user_ap_update(
            self,
            auth: crate::auth::AuthUserOrAP,
            db: &mut diesel_async::AsyncPgConnection,
        ) -> Result<Vec<Self::Type>, axum::http::StatusCode> {
            use crate::db::CheckUserId;

            let values = self.0;
            let ids: Vec<_> = values.iter().map(|value| value.id).collect();
            if values.iter().all(|value| value.user_id == *auth)
                && crate::db::$ttype::check_user_ids(&ids, *auth, db)
                .await
                .map_err(|_| axum::http::StatusCode::INTERNAL_SERVER_ERROR)?
            {
                Ok(values)
            } else {
                Err(axum::http::StatusCode::FORBIDDEN)
            }
        }
    }
}

define_derive_deftly! {
    VerifyForUserOrAPUpdateOptional:

    #[async_trait::async_trait]
    impl crate::db::VerifyForUserOrAPUpdate for crate::db::Unverified<<$ttype as crate::db::Db>::Type> {
        type Type = <$ttype as crate::db::Db>::Type;

        async fn verify_user_ap_update(
            self,
            auth: crate::auth::AuthUserOrAP,
            db: &mut diesel_async::AsyncPgConnection,
        ) -> Result<Self::Type, axum::http::StatusCode> {
            use crate::db::CheckUserId;

            let value = self.0;
            if value.user_id == Some(*auth)
                && crate::db::$ttype::check_user_id(value.id, *auth, db)
                .await
                .map_err(|_| axum::http::StatusCode::INTERNAL_SERVER_ERROR)?
            {
                Ok(value)
            } else {
                Err(axum::http::StatusCode::FORBIDDEN)
            }
        }
    }

    #[async_trait::async_trait]
    impl crate::db::VerifyMultipleForUserOrAPUpdate for crate::db::Unverified<Vec<<$ttype as crate::db::Db>::Type>> {
        type Type = <$ttype as crate::db::Db>::Type;

        async fn verify_user_ap_update(
            self,
            auth: crate::auth::AuthUserOrAP,
            db: &mut diesel_async::AsyncPgConnection,
        ) -> Result<Vec<Self::Type>, axum::http::StatusCode> {
            use crate::db::CheckUserId;

            let values = self.0;
            let ids: Vec<_> = values.iter().map(|value| value.id).collect();
            if values.iter().all(|value| value.user_id == Some(*auth))
                && crate::db::$ttype::check_user_ids(&ids, *auth, db)
                .await
                .map_err(|_| axum::http::StatusCode::INTERNAL_SERVER_ERROR)?
            {
                Ok(values)
            } else {
                Err(axum::http::StatusCode::FORBIDDEN)
            }
        }
    }
}

define_derive_deftly! {
    VerifyForUserCreate:

    impl crate::db::VerifyForUserCreate for crate::db::Unverified<<$ttype as crate::db::Db>::Type> {
        type Type = <$ttype as crate::db::Db>::Type;

        fn verify_user_create(
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

    impl crate::db::VerifyMultipleForUserCreate for crate::db::Unverified<Vec<<$ttype as crate::db::Db>::Type>> {
        type Type = <$ttype as crate::db::Db>::Type;

        fn verify_user_create(
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

define_derive_deftly! {
    VerifyForUserOrAPCreate:

    impl crate::db::VerifyForUserOrAPCreate for crate::db::Unverified<<$ttype as crate::db::Db>::Type> {
        type Type = <$ttype as crate::db::Db>::Type;

        fn verify_user_ap_create(
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

    impl crate::db::VerifyMultipleForUserOrAPCreate for crate::db::Unverified<Vec<<$ttype as crate::db::Db>::Type>> {
        type Type = <$ttype as crate::db::Db>::Type;

        fn verify_user_ap_create(
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

define_derive_deftly! {
    VerifyForUserOrAPCreateOptional:

    impl crate::db::VerifyForUserOrAPCreate for crate::db::Unverified<<$ttype as crate::db::Db>::Type> {
        type Type = <$ttype as crate::db::Db>::Type;

        fn verify_user_ap_create(
            self,
            auth: crate::auth::AuthUserOrAP,
        ) -> Result<Self::Type, axum::http::StatusCode> {
            let value = self.0;
            if value.user_id == Some(*auth) {
                Ok(value)
            } else {
                Err(axum::http::StatusCode::FORBIDDEN)
            }
        }
    }

    impl crate::db::VerifyMultipleForUserOrAPCreate for crate::db::Unverified<Vec<<$ttype as crate::db::Db>::Type>> {
        type Type = <$ttype as crate::db::Db>::Type;

        fn verify_user_ap_create(
            self,
            auth: crate::auth::AuthUserOrAP,
        ) -> Result<Vec<Self::Type>, axum::http::StatusCode> {
            let values = self.0;
            if values.iter().all(|value| value.user_id == Some(*auth)) {
                Ok(values)
            } else {
                Err(axum::http::StatusCode::FORBIDDEN)
            }
        }
    }
}

define_derive_deftly! {
    VerifyForActionProviderUpdate:

    #[async_trait::async_trait]
    impl crate::db::VerifyForActionProviderUpdate for crate::db::Unverified<<$ttype as crate::db::Db>::Type> {
        type Type = <$ttype as crate::db::Db>::Type;

        async fn verify_ap_update(
            self,
            auth: crate::auth::AuthAP,
            db: &mut diesel_async::AsyncPgConnection,
        ) -> Result<Self::Type, axum::http::StatusCode> {
            use crate::db::CheckAPId;

            let value = self.0;
            if value.action_provider_id == *auth
                && crate::db::$ttype::check_ap_id(value.id, *auth, db)
                .await
                .map_err(|_| axum::http::StatusCode::INTERNAL_SERVER_ERROR)?
            {
                Ok(value)
            } else {
                Err(axum::http::StatusCode::FORBIDDEN)
            }
        }
    }

    #[async_trait::async_trait]
    impl crate::db::VerifyMultipleForActionProviderUpdate for crate::db::Unverified<Vec<<$ttype as crate::db::Db>::Type>> {
        type Type = <$ttype as crate::db::Db>::Type;

        async fn verify_ap_update(
            self,
            auth: crate::auth::AuthAP,
            db: &mut diesel_async::AsyncPgConnection,
        ) -> Result<Vec<Self::Type>, axum::http::StatusCode> {
            use crate::db::CheckAPId;

            let values = self.0;
            if values.iter().all(|value| value.action_provider_id == *auth)
                && crate::db::$ttype::check_ap_ids(&values.iter().map(|value| value.id).collect::<Vec<_>>(), *auth, db)
                .await
                .map_err(|_| axum::http::StatusCode::INTERNAL_SERVER_ERROR)?
            {
                Ok(values)
            } else {
                Err(axum::http::StatusCode::FORBIDDEN)
            }
        }
    }
}

define_derive_deftly! {
    VerifyForActionProviderCreate:

    impl crate::db::VerifyForActionProviderCreate for crate::db::Unverified<<$ttype as crate::db::Db>::Type> {
        type Type = <$ttype as crate::db::Db>::Type;

        fn verify_ap_create(
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

    impl crate::db::VerifyMultipleForActionProviderCreate for crate::db::Unverified<Vec<<$ttype as crate::db::Db>::Type>> {
        type Type = <$ttype as crate::db::Db>::Type;

        fn verify_ap_create(
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

define_derive_deftly! {
    VerifyForAdmin:

    impl crate::db::VerifyForAdmin for crate::db::Unverified<<$ttype as crate::db::Db>::Type> {
        type Type = <$ttype as crate::db::Db>::Type;

        fn verify_adm(
            self,
            _auth: crate::auth::AuthAdmin,
        ) -> Result<Self::Type, axum::http::StatusCode> {
            Ok(self.0)
        }
    }

    impl crate::db::VerifyMultipleForAdmin for crate::db::Unverified<Vec<<$ttype as crate::db::Db>::Type>> {
        type Type = <$ttype as crate::db::Db>::Type;

        fn verify_adm(
            self,
            _auth: crate::auth::AuthAdmin,
        ) -> Result<Vec<Self::Type>, axum::http::StatusCode> {
            Ok(self.0)
        }
    }
}

define_derive_deftly! {
    VerifyUncheckedCreate:

    impl crate::db::VerifyUncheckedCreate for crate::db::Unverified<<$ttype as crate::db::Db>::Type> {
        type Type = <$ttype as crate::db::Db>::Type;

        fn verify_unchecked_create(self) -> Result<Self::Type, axum::http::StatusCode> {
            Ok(self.0)
        }
    }
}
