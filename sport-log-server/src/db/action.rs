use argon2::{password_hash::SaltString, PasswordHash, PasswordHasher, PasswordVerifier};
use chrono::{DateTime, Utc};
use derive_deftly::Deftly;
use diesel::{prelude::*, result::Error};
use diesel_async::RunQueryDsl;
use rand_core::OsRng;
use sport_log_derive::*;
use sport_log_types::{
    schema::{action, action_event, action_provider, action_rule, platform_credential},
    Action, ActionEvent, ActionEventId, ActionProviderId, ActionRuleId, CreatableActionRule,
    DeletableActionEvent, ExecutableActionEvent, UserId,
};

use crate::{auth::*, db::*};

#[derive(Db, ModifiableDb, Deftly)]
#[derive_deftly(
    VerifyForAdminGet,
    VerifyUncheckedGet,
    GetById,
    GetAll,
    GetByEpoch,
    VerifyForAdmin,
    VerifyUncheckedCreate
)]
pub struct ActionProviderDb;

/// Same as trait [`Create`] but with mutable references
impl ActionProviderDb {
    pub async fn create(
        action_provider: &mut <Self as Db>::Type,
        db: &mut AsyncPgConnection,
    ) -> QueryResult<usize> {
        let salt = SaltString::generate(&mut OsRng);
        action_provider.password = build_hasher()
            .hash_password(action_provider.password.as_bytes(), &salt)
            .map_err(|_| Error::RollbackTransaction)? // this should not happen but prevents panic
            .to_string();

        diesel::insert_into(action_provider::table)
            .values(&*action_provider)
            .execute(db)
            .await
    }

    pub async fn create_multiple(
        action_providers: &mut [<Self as Db>::Type],
        db: &mut AsyncPgConnection,
    ) -> QueryResult<usize> {
        for action_provider in &mut *action_providers {
            let salt = SaltString::generate(&mut OsRng);
            action_provider.password = build_hasher()
                .hash_password(action_provider.password.as_bytes(), &salt)
                .map_err(|_| Error::RollbackTransaction)? // this should not happen but prevents panic
                .to_string();
        }

        diesel::insert_into(action_provider::table)
            .values(&*action_providers)
            .execute(db)
            .await
    }
}

#[allow(clippy::multiple_inherent_impl)]
impl ActionProviderDb {
    pub async fn auth(
        name: &str,
        password: &str,
        db: &mut AsyncPgConnection,
    ) -> QueryResult<ActionProviderId> {
        let (action_provider_id, password_hash): (ActionProviderId, String) =
            action_provider::table
                .filter(action_provider::columns::name.eq(name))
                .select((
                    action_provider::columns::id,
                    action_provider::columns::password,
                ))
                .get_result(db)
                .await?;

        let password_hash =
            PasswordHash::new(password_hash.as_str()).map_err(|_| Error::RollbackTransaction)?; // this should not happen but prevents panic
        if build_hasher()
            .verify_password(password.as_bytes(), &password_hash)
            .is_ok()
        {
            Ok(action_provider_id)
        } else {
            Err(Error::NotFound)
        }
    }

    pub async fn auth_as_user(
        name: &str,
        password: &str,
        user_id: UserId,
        db: &mut AsyncPgConnection,
    ) -> QueryResult<AuthApForUser> {
        let (action_provider_id, password_hash): (ActionProviderId, String) =
            action_provider::table
                .filter(action_provider::columns::name.eq(name))
                .select((
                    action_provider::columns::id,
                    action_provider::columns::password,
                ))
                .get_result(db)
                .await?;

        let password_hash =
            PasswordHash::new(password_hash.as_str()).map_err(|_| Error::RollbackTransaction)?; // this should not happen but prevents panic
        if build_hasher()
            .verify_password(password.as_bytes(), &password_hash)
            .is_ok()
        {
            let action_events: i64 = action::table
                .inner_join(action_event::table)
                .filter(action::columns::action_provider_id.eq(action_provider_id))
                .filter(action_event::columns::user_id.eq(user_id))
                .filter(action_event::columns::enabled.eq(true))
                .filter(action_event::columns::deleted.eq(false))
                .count()
                .get_result(db)
                .await?;

            if action_events > 0 {
                Ok(AuthApForUser::Allowed(action_provider_id))
            } else {
                Ok(AuthApForUser::Forbidden)
            }
        } else {
            Err(Error::NotFound)
        }
    }
}

#[derive(Db, DbWithApId, ModifiableDb, Deftly)]
#[derive_deftly(
    VerifyUncheckedGet,
    VerifyForActionProviderGet,
    Create,
    GetById,
    GetAll,
    GetByEpoch,
    Update,
    CheckAPId,
    VerifyForActionProviderUpdate,
    VerifyForActionProviderCreate
)]
pub struct ActionDb;

impl ActionDb {
    pub async fn get_by_action_provider(
        action_provider_id: ActionProviderId,
        db: &mut AsyncPgConnection,
    ) -> QueryResult<Vec<<Self as Db>::Type>> {
        action::table
            .filter(action::columns::action_provider_id.eq(action_provider_id))
            .select(Action::as_select())
            .get_results(db)
            .await
    }
}

#[derive(Db, DbWithUserId, ModifiableDb, Deftly)]
#[derive_deftly(
    VerifyForUserGet,
    Create,
    GetById,
    GetByUser,
    GetByUserAndEpoch,
    Update,
    CheckUserId,
    VerifyForUserUpdate,
    VerifyForUserCreate
)]
pub struct ActionRuleDb;

#[derive(Db, DbWithUserId, ModifiableDb, Deftly)]
#[derive_deftly(
    VerifyForUserGet,
    VerifyForActionProviderGet,
    VerifyForActionProviderDisable,
    VerifyForAdminGet,
    VerifyForAdminDelete,
    Create,
    GetById,
    GetByUser,
    GetByUserAndEpoch,
    Update,
    CheckUserId,
    VerifyForUserUpdate,
    VerifyForUserCreate,
    VerifyForAdmin
)]
pub struct ActionEventDb;

#[async_trait]
impl CheckAPId for ActionEventDb {
    async fn check_ap_id(
        id: Self::Id,
        ap_id: ActionProviderId,
        db: &mut AsyncPgConnection,
    ) -> QueryResult<bool> {
        action_event::table
            .inner_join(action::table)
            .filter(action_event::columns::id.eq(id))
            .select(action::columns::action_provider_id.eq(ap_id))
            .get_result(db)
            .await
            .optional()
            .map(|eq| eq.unwrap_or(false))
    }

    async fn check_ap_ids(
        ids: &[Self::Id],
        ap_id: ActionProviderId,
        db: &mut AsyncPgConnection,
    ) -> QueryResult<bool> {
        action_event::table
            .inner_join(action::table)
            .filter(action_event::columns::id.eq_any(ids))
            .select(action::columns::action_provider_id.eq(ap_id))
            .get_results(db)
            .await
            .map(|eqs: Vec<bool>| eqs.into_iter().all(|eq| eq))
    }
}

impl ActionEventDb {
    pub async fn create_multiple_ignore_conflict(
        action_events: Vec<ActionEvent>,
        db: &mut AsyncPgConnection,
    ) -> QueryResult<usize> {
        diesel::insert_into(action_event::table)
            .values(action_events)
            .on_conflict_do_nothing()
            .execute(db)
            .await
    }

    pub async fn disable_multiple(
        action_event_ids: Vec<ActionEventId>,
        db: &mut AsyncPgConnection,
    ) -> QueryResult<usize> {
        diesel::update(
            action_event::table.filter(action_event::columns::id.eq_any(action_event_ids)),
        )
        .set(action_event::columns::enabled.eq(false))
        .execute(db)
        .await
    }

    pub async fn delete_multiple(
        action_event_ids: Vec<ActionEventId>,
        db: &mut AsyncPgConnection,
    ) -> QueryResult<usize> {
        diesel::update(
            action_event::table.filter(action_event::columns::id.eq_any(action_event_ids)),
        )
        .set(action_event::columns::deleted.eq(true))
        .execute(db)
        .await
    }
}

pub struct CreatableActionRuleDb;

impl Db for CreatableActionRuleDb {
    type Id = ActionRuleId;
    type Type = CreatableActionRule;
    type Table = action_rule::table;

    fn table() -> Self::Table {
        action_rule::table
    }

    fn id_column() -> <Self::Table as Table>::PrimaryKey {
        action_rule::columns::id
    }
}

#[async_trait]
impl GetAll for CreatableActionRuleDb {
    async fn get_all(db: &mut AsyncPgConnection) -> QueryResult<Vec<<Self as Db>::Type>> {
        action_rule::table
            .inner_join(action::table)
            .filter(action_rule::columns::enabled.eq(true))
            .filter(action_rule::columns::deleted.eq(false))
            .select((
                action_rule::columns::id,
                action_rule::columns::user_id,
                action_rule::columns::action_id,
                action_rule::columns::weekday,
                action_rule::columns::time,
                action_rule::columns::arguments,
                action::columns::create_before,
            ))
            .get_results(db)
            .await
    }
}

pub struct ExecutableActionEventDb;

impl Db for ExecutableActionEventDb {
    type Id = ActionEventId;
    type Type = ExecutableActionEvent;
    type Table = action_event::table;

    fn table() -> Self::Table {
        action_event::table
    }

    fn id_column() -> <Self::Table as Table>::PrimaryKey {
        action_event::columns::id
    }
}

impl ExecutableActionEventDb {
    pub async fn get_by_action_provider(
        action_provider_id: ActionProviderId,
        db: &mut AsyncPgConnection,
    ) -> QueryResult<Vec<ExecutableActionEvent>> {
        action_event::table
            .inner_join(action::table.inner_join(action_provider::table))
            .left_outer_join(
                platform_credential::table.on(platform_credential::columns::platform_id
                    .eq(action_provider::columns::platform_id)
                    .and(platform_credential::columns::user_id.eq(action_event::columns::user_id))),
            )
            .filter(action_provider::columns::id.eq(action_provider_id))
            .filter(action_event::columns::enabled.eq(true))
            .filter(action_event::columns::deleted.eq(false))
            .select((
                action_event::columns::id,
                action::columns::name,
                action_event::columns::datetime,
                action_event::columns::arguments,
                action_event::columns::user_id,
                platform_credential::columns::username.nullable(),
                platform_credential::columns::password.nullable(),
            ))
            .get_results(db)
            .await
    }

    pub async fn get_ordered_by_action_provider_and_timespan(
        action_provider_id: ActionProviderId,
        start_datetime: DateTime<Utc>,
        end_datetime: DateTime<Utc>,
        db: &mut AsyncPgConnection,
    ) -> QueryResult<Vec<ExecutableActionEvent>> {
        action_event::table
            .inner_join(action::table.inner_join(action_provider::table))
            .left_outer_join(
                platform_credential::table.on(platform_credential::columns::platform_id
                    .eq(action_provider::columns::platform_id)
                    .and(platform_credential::columns::user_id.eq(action_event::columns::user_id))),
            )
            .filter(action_provider::columns::id.eq(action_provider_id))
            .filter(action_event::columns::enabled.eq(true))
            .filter(action_event::columns::deleted.eq(false))
            .filter(action_event::columns::datetime.between(start_datetime, end_datetime))
            .select((
                action_event::columns::id,
                action::columns::name,
                action_event::columns::datetime,
                action_event::columns::arguments,
                action_event::columns::user_id,
                platform_credential::columns::username.nullable(),
                platform_credential::columns::password.nullable(),
            ))
            .order_by(action_event::columns::datetime)
            .get_results(db)
            .await
    }
}

pub struct DeletableActionEventDb();

impl Db for DeletableActionEventDb {
    type Id = ActionEventId;
    type Type = DeletableActionEvent;
    type Table = action_event::table;

    fn table() -> Self::Table {
        action_event::table
    }

    fn id_column() -> <Self::Table as Table>::PrimaryKey {
        action_event::columns::id
    }
}

#[async_trait]
impl GetAll for DeletableActionEventDb {
    async fn get_all(db: &mut AsyncPgConnection) -> QueryResult<Vec<<Self as Db>::Type>> {
        Self::table()
            .inner_join(action::table)
            .filter(action_event::columns::deleted.eq(false))
            .select((
                Self::table().primary_key(),
                action_event::columns::datetime,
                action::columns::delete_after,
            ))
            .get_results(db)
            .await
    }
}
