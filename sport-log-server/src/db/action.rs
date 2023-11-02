use argon2::{password_hash::SaltString, PasswordHash, PasswordHasher, PasswordVerifier};
use chrono::{DateTime, Utc};
use diesel::{prelude::*, result::Error};
use rand_core::OsRng;
use sport_log_types::{
    schema::{action, action_event, action_provider, action_rule, platform_credential},
    Action, ActionEvent, ActionEventId, ActionProviderId, ActionRuleId, CreatableActionRule,
    DeletableActionEvent, ExecutableActionEvent, UserId,
};
use sport_log_types_derive::*;

use crate::{auth::*, db::*};

#[derive(
    Db,
    ModifiableDb,
    VerifyIdForAdmin,
    VerifyIdUnchecked,
    GetById,
    GetByIds,
    GetAll,
    GetBySync,
    HardDelete,
    VerifyForAdminWithoutDb,
    VerifyUnchecked,
)]
pub struct ActionProviderDb;

/// Same as trait [`Create`](crate::db::Create) but with mutable references
impl ActionProviderDb {
    pub fn create(
        action_provider: &mut <Self as Db>::Type,
        db: &mut PgConnection,
    ) -> QueryResult<usize> {
        let salt = SaltString::generate(&mut OsRng);
        action_provider.password = build_hasher()
            .hash_password(action_provider.password.as_bytes(), &salt)
            .map_err(|_| Error::RollbackTransaction)? // this should not happen but prevents panic
            .to_string();

        diesel::insert_into(action_provider::table)
            .values(&*action_provider)
            .execute(db)
    }

    pub fn create_multiple(
        action_providers: &mut [<Self as Db>::Type],
        db: &mut PgConnection,
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
    }
}

impl ActionProviderDb {
    pub fn auth(
        name: &str,
        password: &str,
        db: &mut PgConnection,
    ) -> QueryResult<ActionProviderId> {
        let (action_provider_id, password_hash): (ActionProviderId, String) =
            action_provider::table
                .filter(action_provider::columns::name.eq(name))
                .select((
                    action_provider::columns::id,
                    action_provider::columns::password,
                ))
                .get_result(db)?;

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

    pub fn auth_as_user(
        name: &str,
        password: &str,
        user_id: UserId,
        db: &mut PgConnection,
    ) -> QueryResult<AuthApForUser> {
        let (action_provider_id, password_hash): (ActionProviderId, String) =
            action_provider::table
                .filter(action_provider::columns::name.eq(name))
                .select((
                    action_provider::columns::id,
                    action_provider::columns::password,
                ))
                .get_result(db)?;

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
                .get_result(db)?;

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

#[derive(
    Db,
    DbWithApId,
    ModifiableDb,
    VerifyIdUnchecked,
    VerifyIdForActionProvider,
    Create,
    GetById,
    GetByIds,
    GetAll,
    GetBySync,
    HardDelete,
    CheckAPId,
    VerifyForActionProviderWithDb,
    VerifyForActionProviderWithoutDb,
)]
pub struct ActionDb;

impl ActionDb {
    pub fn get_by_action_provider(
        action_provider_id: ActionProviderId,
        db: &mut PgConnection,
    ) -> QueryResult<Vec<<Self as Db>::Type>> {
        action::table
            .filter(action::columns::action_provider_id.eq(action_provider_id))
            .select(Action::as_select())
            .get_results(db)
    }
}

#[derive(
    Db,
    DbWithUserId,
    ModifiableDb,
    VerifyIdForUser,
    Create,
    GetById,
    GetByIds,
    GetByUser,
    GetByUserSync,
    Update,
    HardDelete,
    CheckUserId,
    VerifyForUserWithDb,
    VerifyForUserWithoutDb,
)]
pub struct ActionRuleDb;

#[derive(
    Db,
    DbWithUserId,
    ModifiableDb,
    VerifyIdForUser,
    VerifyIdForActionProvider,
    VerifyIdsForActionProvider,
    VerifyIdForAdmin,
    VerifyIdsForAdmin,
    Create,
    GetById,
    GetByIds,
    GetByUser,
    GetByUserSync,
    Update,
    HardDelete,
    CheckUserId,
    VerifyForUserWithDb,
    VerifyForUserWithoutDb,
    VerifyForAdminWithoutDb,
)]
pub struct ActionEventDb;

impl CheckAPId for ActionEventDb {
    fn check_ap_id(
        id: Self::Id,
        ap_id: ActionProviderId,
        db: &mut PgConnection,
    ) -> QueryResult<bool> {
        action_event::table
            .inner_join(action::table)
            .filter(action_event::columns::id.eq(id))
            .select(action::columns::action_provider_id.eq(ap_id))
            .get_result(db)
            .optional()
            .map(|eq| eq.unwrap_or(false))
    }

    fn check_ap_ids(
        ids: &[Self::Id],
        ap_id: ActionProviderId,
        db: &mut PgConnection,
    ) -> QueryResult<bool> {
        action_event::table
            .inner_join(action::table)
            .filter(action_event::columns::id.eq_any(ids))
            .select(action::columns::action_provider_id.eq(ap_id))
            .get_results(db)
            .map(|eqs: Vec<bool>| eqs.into_iter().all(|eq| eq))
    }
}

impl ActionEventDb {
    pub fn create_multiple_ignore_conflict(
        action_events: Vec<ActionEvent>,
        db: &mut PgConnection,
    ) -> QueryResult<usize> {
        diesel::insert_into(action_event::table)
            .values(action_events)
            .on_conflict_do_nothing()
            .execute(db)
    }

    pub fn disable_multiple(
        action_event_ids: Vec<ActionEventId>,
        db: &mut PgConnection,
    ) -> QueryResult<usize> {
        diesel::update(
            action_event::table.filter(action_event::columns::id.eq_any(action_event_ids)),
        )
        .set(action_event::columns::enabled.eq(false))
        .execute(db)
    }

    pub fn delete_multiple(
        action_event_ids: Vec<ActionEventId>,
        db: &mut PgConnection,
    ) -> QueryResult<usize> {
        diesel::update(
            action_event::table.filter(action_event::columns::id.eq_any(action_event_ids)),
        )
        .set(action_event::columns::deleted.eq(true))
        .execute(db)
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

impl GetAll for CreatableActionRuleDb {
    fn get_all(db: &mut PgConnection) -> QueryResult<Vec<<Self as Db>::Type>> {
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
    pub fn get_by_action_provider(
        action_provider_id: ActionProviderId,
        db: &mut PgConnection,
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
    }

    pub fn get_ordered_by_action_provider_and_timespan(
        action_provider_id: ActionProviderId,
        start_datetime: DateTime<Utc>,
        end_datetime: DateTime<Utc>,
        db: &mut PgConnection,
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

impl GetAll for DeletableActionEventDb {
    fn get_all(db: &mut PgConnection) -> QueryResult<Vec<<Self as Db>::Type>> {
        Self::table()
            .inner_join(action::table)
            .filter(action_event::columns::deleted.eq(false))
            .select((
                Self::table().primary_key(),
                action_event::columns::datetime,
                action::columns::delete_after,
            ))
            .get_results(db)
    }
}
