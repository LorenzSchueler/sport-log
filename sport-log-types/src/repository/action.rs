use argon2::{password_hash::SaltString, Argon2, PasswordHash, PasswordHasher, PasswordVerifier};
use chrono::{DateTime, Utc};
use diesel::{prelude::*, result::Error};
use rand_core::OsRng;

use crate::{
    schema::{action, action_event, action_provider, action_rule, platform_credential},
    Action, ActionEvent, ActionEventId, ActionProvider, ActionProviderId, ActionRule, CheckAPId,
    CreatableActionRule, Create, DeletableActionEvent, ExecutableActionEvent, GetAll, UserId,
};

impl Create for ActionProvider {
    fn create(mut action_provider: Self, conn: &PgConnection) -> QueryResult<Self> {
        let salt = SaltString::generate(&mut OsRng);
        action_provider.password = Argon2::default()
            .hash_password_simple(action_provider.password.as_bytes(), salt.as_ref())
            .unwrap()
            .to_string();

        diesel::insert_into(action_provider::table)
            .values(action_provider)
            .get_result(conn)
    }
}

impl ActionProvider {
    pub fn auth(name: &str, password: &str, conn: &PgConnection) -> QueryResult<ActionProviderId> {
        let (action_provider_id, password_hash): (ActionProviderId, String) =
            action_provider::table
                .filter(action_provider::columns::name.eq(name))
                .select((
                    action_provider::columns::id,
                    action_provider::columns::password,
                ))
                .get_result(conn)?;

        let password_hash = PasswordHash::new(password_hash.as_str()).unwrap();
        if Argon2::default()
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
        conn: &PgConnection,
    ) -> QueryResult<ActionProviderId> {
        let (action_provider_id, password_hash): (ActionProviderId, String) =
            action_provider::table
                .filter(action_provider::columns::name.eq(name))
                .filter(
                    action_provider::columns::id.eq_any(
                        action::table
                            .filter(
                                action::columns::id.eq_any(
                                    action_event::table
                                        .filter(action_event::columns::user_id.eq(user_id))
                                        .select(action_event::columns::action_id),
                                ),
                            )
                            .select(action::columns::action_provider_id),
                    ),
                )
                .select((
                    action_provider::columns::id,
                    action_provider::columns::password,
                ))
                .get_result(conn)?;

        let password_hash = PasswordHash::new(password_hash.as_str()).unwrap();
        if Argon2::default()
            .verify_password(password.as_bytes(), &password_hash)
            .is_ok()
        {
            Ok(action_provider_id)
        } else {
            Err(Error::NotFound)
        }
    }
}

impl Action {
    pub fn get_by_action_provider(
        action_provider_id: ActionProviderId,
        conn: &PgConnection,
    ) -> QueryResult<Vec<Self>> {
        action::table
            .filter(action::columns::action_provider_id.eq(action_provider_id))
            .get_results(conn)
    }
}

impl ActionRule {
    pub fn get_by_action_provider(
        action_provider_id: ActionProviderId,
        conn: &PgConnection,
    ) -> QueryResult<Vec<Self>> {
        action_rule::table
            .filter(
                action_rule::columns::action_id.eq_any(
                    action::table
                        .select(action::columns::id)
                        .filter(action::columns::action_provider_id.eq(action_provider_id)),
                ),
            )
            .get_results(conn)
    }

    pub fn get_by_user_and_action_provider(
        user_id: UserId,
        action_provider_id: ActionProviderId,
        conn: &PgConnection,
    ) -> QueryResult<Vec<Self>> {
        action_rule::table
            .filter(action_rule::columns::user_id.eq(user_id))
            .filter(
                action_rule::columns::action_id.eq_any(
                    action::table
                        .select(action::columns::id)
                        .filter(action::columns::action_provider_id.eq(action_provider_id)),
                ),
            )
            .get_results(conn)
    }
}

impl CheckAPId for ActionEvent {
    type Id = ActionEventId;

    fn check_ap_id(
        id: Self::Id,
        ap_id: ActionProviderId,
        conn: &PgConnection,
    ) -> QueryResult<bool> {
        action::table
            .filter(
                action::columns::id.eq_any(
                    action_event::table
                        .find(id)
                        .select(action_event::columns::action_id),
                ),
            )
            .filter(action::columns::action_provider_id.eq(ap_id))
            .count()
            .get_result(conn)
            .map(|count: i64| count == 1)
    }

    fn check_ap_ids(
        ids: &Vec<Self::Id>,
        ap_id: ActionProviderId,
        conn: &PgConnection,
    ) -> QueryResult<bool> {
        action::table
            .filter(
                action::columns::id.eq_any(
                    action_event::table
                        .filter(action_event::columns::id.eq_any(ids))
                        .select(action_event::columns::action_id),
                ),
            )
            .filter(action::columns::action_provider_id.eq(ap_id))
            .count()
            .get_result(conn)
            .map(|count: i64| count == 1)
    }
}

impl ActionEvent {
    pub fn create_multiple_ignore_conflict(
        action_events: Vec<ActionEvent>,
        conn: &PgConnection,
    ) -> QueryResult<Vec<ActionEvent>> {
        diesel::insert_into(action_event::table)
            .values(action_events)
            .on_conflict_do_nothing()
            .get_results(conn)
    }

    pub fn get_by_action_provider(
        action_provider_id: ActionProviderId,
        conn: &PgConnection,
    ) -> QueryResult<Vec<Self>> {
        action_event::table
            .filter(
                action_event::columns::action_id.eq_any(
                    action::table
                        .select(action::columns::id)
                        .filter(action::columns::action_provider_id.eq(action_provider_id)),
                ),
            )
            .get_results(conn)
    }

    pub fn get_by_user_and_action_provider(
        user_id: UserId,
        action_provider_id: ActionProviderId,
        conn: &PgConnection,
    ) -> QueryResult<Vec<Self>> {
        action_event::table
            .filter(action_event::columns::user_id.eq(user_id))
            .filter(
                action_event::columns::action_id.eq_any(
                    action::table
                        .filter(action::columns::action_provider_id.eq(action_provider_id))
                        .select(action::columns::id),
                ),
            )
            .get_results(conn)
    }

    pub fn delete_multiple(
        action_event_ids: Vec<ActionEventId>,
        conn: &PgConnection,
    ) -> QueryResult<usize> {
        diesel::update(
            action_event::table.filter(action_event::columns::id.eq_any(action_event_ids)),
        )
        .set(action_event::columns::deleted.eq(true))
        .execute(conn)
    }
}

impl GetAll for CreatableActionRule {
    fn get_all(conn: &PgConnection) -> QueryResult<Vec<Self>> {
        action_rule::table
            .inner_join(action::table)
            .filter(action_rule::columns::enabled.eq(true))
            .select((
                action_rule::columns::id,
                action_rule::columns::user_id,
                action_rule::columns::action_id,
                action_rule::columns::weekday,
                action_rule::columns::time,
                action::columns::create_before,
            ))
            .get_results(conn)
    }
}

impl ExecutableActionEvent {
    pub fn get_by_action_provider(
        action_provider_id: ActionProviderId,
        conn: &PgConnection,
    ) -> QueryResult<Vec<Self>> {
        action_event::table
            .inner_join(action::table.inner_join(action_provider::table))
            .inner_join(
                platform_credential::table.on(platform_credential::columns::platform_id
                    .eq(action_provider::columns::platform_id)
                    .and(platform_credential::columns::user_id.eq(action_event::columns::user_id))),
            )
            .filter(action_provider::columns::id.eq(action_provider_id))
            .filter(action_event::columns::enabled.eq(true))
            .select((
                action_event::columns::id,
                action::columns::name,
                action_event::columns::datetime,
                platform_credential::columns::user_id,
                platform_credential::columns::username,
                platform_credential::columns::password,
            ))
            .get_results(conn)
    }

    pub fn get_ordered_by_action_provider_and_timespan(
        action_provider_id: ActionProviderId,
        start_datetime: DateTime<Utc>,
        end_datetime: DateTime<Utc>,
        conn: &PgConnection,
    ) -> QueryResult<Vec<Self>> {
        action_event::table
            .inner_join(action::table.inner_join(action_provider::table))
            .inner_join(
                platform_credential::table.on(platform_credential::columns::platform_id
                    .eq(action_provider::columns::platform_id)
                    .and(platform_credential::columns::user_id.eq(action_event::columns::user_id))),
            )
            .filter(action_provider::columns::id.eq(action_provider_id))
            .filter(action_event::columns::enabled.eq(true))
            .filter(action_event::columns::datetime.between(start_datetime, end_datetime))
            .select((
                action_event::columns::id,
                action::columns::name,
                action_event::columns::datetime,
                platform_credential::columns::user_id,
                platform_credential::columns::username,
                platform_credential::columns::password,
            ))
            .order_by(action_event::columns::datetime)
            .get_results(conn)
    }
}

impl GetAll for DeletableActionEvent {
    fn get_all(conn: &PgConnection) -> QueryResult<Vec<Self>> {
        action_event::table
            .inner_join(action::table)
            .select((
                action_event::columns::id,
                action_event::columns::datetime,
                action::columns::delete_after,
            ))
            .get_results(conn)
    }
}
