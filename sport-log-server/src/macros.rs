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
    HardDelete:

    #[async_trait::async_trait]
    impl crate::db::HardDelete for crate::db::$ttype {
        async fn hard_delete(epoch: i64, db: &mut diesel_async::AsyncPgConnection) -> diesel::result::QueryResult<usize> {
            use crate::db::{Db, ModifiableDb};
            use diesel_async::RunQueryDsl;
            use diesel::prelude::*;

            diesel::delete(
                Self::table()
                    .filter(Self::deleted_column().eq(true))
                    .filter(Self::epoch_column().le(epoch))
            ).execute(db)
            .await
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
    VerifyIdForUser:

    #[async_trait::async_trait]
    impl crate::db::VerifyIdForUser for crate::db::UnverifiedId<<$ttype as crate::db::Db>::Id> {
        type Id = <$ttype as crate::db::Db>::Id;

        async fn verify_user(
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
    VerifyIdForUserOrAP:

    #[async_trait::async_trait]
    impl crate::db::VerifyIdForUserOrAP for crate::db::UnverifiedId<<$ttype as crate::db::Db>::Id> {
        type Id = <$ttype as crate::db::Db>::Id;

        async fn verify_user_ap(
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
    VerifyIdForUserOrAPOptional:

    #[async_trait::async_trait]
    impl crate::db::VerifyIdForUserOrAP for crate::db::UnverifiedId<<$ttype as crate::db::Db>::Id> {
        type Id = <$ttype as crate::db::Db>::Id;

        async fn verify_user_ap(
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
    VerifyIdForActionProvider:

    #[async_trait::async_trait]
    impl crate::db::VerifyIdForActionProvider for crate::db::UnverifiedId<<$ttype as crate::db::Db>::Id> {
        type Id = <$ttype as crate::db::Db>::Id;

        async fn verify_ap(
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
    VerifyIdsForActionProvider:

    #[async_trait::async_trait]
    impl crate::db::VerifyIdsForActionProvider for crate::db::UnverifiedIds<<$ttype as crate::db::Db>::Id> {
        type Id = <$ttype as crate::db::Db>::Id;

        async fn verify_ap(
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
    VerifyIdForAdmin:

    impl crate::db::VerifyIdForAdmin for crate::db::UnverifiedId<<$ttype as crate::db::Db>::Id> {
        type Id = <$ttype as crate::db::Db>::Id;

        fn verify_adm(
            self,
            _auth: crate::auth::AuthAdmin,
        ) -> Result<Self::Id, axum::http::StatusCode> {
            Ok(self.0)
        }
    }
}

define_derive_deftly! {
    VerifyIdsForAdmin:

    impl crate::db::VerifyIdsForAdmin for crate::db::UnverifiedIds<<$ttype as crate::db::Db>::Id> {
        type Id = <$ttype as crate::db::Db>::Id;

        fn verify_adm(
            self,
            _auth: crate::auth::AuthAdmin,
        ) -> Result<Vec<Self::Id>, axum::http::StatusCode> {
            Ok(self.0)
        }
    }
}

define_derive_deftly! {
    VerifyIdUnchecked:

    impl crate::db::VerifyIdUnchecked for crate::db::UnverifiedId<<$ttype as crate::db::Db>::Id> {
        type Id = <$ttype as crate::db::Db>::Id;

        fn verify_unchecked(self) -> Result<Self::Id, axum::http::StatusCode> {
            Ok(self.0)
        }
    }
}

define_derive_deftly! {
    VerifyForUserWithDb:

    #[async_trait::async_trait]
    impl crate::db::VerifyForUserWithDb for crate::db::Unverified<<$ttype as crate::db::Db>::Type> {
        type Type = <$ttype as crate::db::Db>::Type;

        async fn verify_user(
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
    impl crate::db::VerifyMultipleForUserWithDb for crate::db::Unverified<Vec<<$ttype as crate::db::Db>::Type>> {
        type Type = <$ttype as crate::db::Db>::Type;

        async fn verify_user(
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
    VerifyForUserOrAPWithDb:

    #[async_trait::async_trait]
    impl crate::db::VerifyForUserOrAPWithDb for crate::db::Unverified<<$ttype as crate::db::Db>::Type> {
        type Type = <$ttype as crate::db::Db>::Type;

        async fn verify_user_ap(
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
    impl crate::db::VerifyMultipleForUserOrAPWithDb for crate::db::Unverified<Vec<<$ttype as crate::db::Db>::Type>> {
        type Type = <$ttype as crate::db::Db>::Type;

        async fn verify_user_ap(
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
    VerifyForUserOrAPWithDbOptional:

    #[async_trait::async_trait]
    impl crate::db::VerifyForUserOrAPWithDb for crate::db::Unverified<<$ttype as crate::db::Db>::Type> {
        type Type = <$ttype as crate::db::Db>::Type;

        async fn verify_user_ap(
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
    impl crate::db::VerifyMultipleForUserOrAPWithDb for crate::db::Unverified<Vec<<$ttype as crate::db::Db>::Type>> {
        type Type = <$ttype as crate::db::Db>::Type;

        async fn verify_user_ap(
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
    VerifyForUserWithoutDb:

    impl crate::db::VerifyForUserWithoutDb for crate::db::Unverified<<$ttype as crate::db::Db>::Type> {
        type Type = <$ttype as crate::db::Db>::Type;

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

    impl crate::db::VerifyMultipleForUserWithoutDb for crate::db::Unverified<Vec<<$ttype as crate::db::Db>::Type>> {
        type Type = <$ttype as crate::db::Db>::Type;

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

define_derive_deftly! {
    VerifyForUserOrAPWithoutDb:

    impl crate::db::VerifyForUserOrAPWithoutDb for crate::db::Unverified<<$ttype as crate::db::Db>::Type> {
        type Type = <$ttype as crate::db::Db>::Type;

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

    impl crate::db::VerifyMultipleForUserOrAPWithoutDb for crate::db::Unverified<Vec<<$ttype as crate::db::Db>::Type>> {
        type Type = <$ttype as crate::db::Db>::Type;

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

define_derive_deftly! {
    VerifyForUserOrAPWithoutDbOptional:

    impl crate::db::VerifyForUserOrAPWithoutDb for crate::db::Unverified<<$ttype as crate::db::Db>::Type> {
        type Type = <$ttype as crate::db::Db>::Type;

        fn verify_user_ap_without_db(
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

    impl crate::db::VerifyMultipleForUserOrAPWithoutDb for crate::db::Unverified<Vec<<$ttype as crate::db::Db>::Type>> {
        type Type = <$ttype as crate::db::Db>::Type;

        fn verify_user_ap_without_db(
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
    VerifyForActionProviderWithDb:

    #[async_trait::async_trait]
    impl crate::db::VerifyForActionProviderWithDb for crate::db::Unverified<<$ttype as crate::db::Db>::Type> {
        type Type = <$ttype as crate::db::Db>::Type;

        async fn verify_ap(
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
    impl crate::db::VerifyMultipleForActionProviderWithDb for crate::db::Unverified<Vec<<$ttype as crate::db::Db>::Type>> {
        type Type = <$ttype as crate::db::Db>::Type;

        async fn verify_ap(
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
    VerifyForActionProviderWithoutDb:

    impl crate::db::VerifyForActionProviderWithoutDb for crate::db::Unverified<<$ttype as crate::db::Db>::Type> {
        type Type = <$ttype as crate::db::Db>::Type;

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

    impl crate::db::VerifyMultipleForActionProviderWithoutDb for crate::db::Unverified<Vec<<$ttype as crate::db::Db>::Type>> {
        type Type = <$ttype as crate::db::Db>::Type;

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

define_derive_deftly! {
    VerifyForAdminWithoutDb:

    impl crate::db::VerifyForAdminWithoutDb for crate::db::Unverified<<$ttype as crate::db::Db>::Type> {
        type Type = <$ttype as crate::db::Db>::Type;

        fn verify_adm(
            self,
            _auth: crate::auth::AuthAdmin,
        ) -> Result<Self::Type, axum::http::StatusCode> {
            Ok(self.0)
        }
    }

    impl crate::db::VerifyMultipleForAdminWithoutDb for crate::db::Unverified<Vec<<$ttype as crate::db::Db>::Type>> {
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
    VerifyUnchecked:

    impl crate::db::VerifyUnchecked for crate::db::Unverified<<$ttype as crate::db::Db>::Type> {
        type Type = <$ttype as crate::db::Db>::Type;

        fn verify_unchecked(self) -> Result<Self::Type, axum::http::StatusCode> {
            Ok(self.0)
        }
    }
}
