use argon2::{password_hash::SaltString, Argon2, PasswordHash, PasswordHasher, PasswordVerifier};
use chrono::NaiveDateTime;
use diesel::{prelude::*, result::Error};
use rand_core::OsRng;

use crate::{
    schema::{action, action_event, action_provider, action_rule, platform_credentials},
    types::{
        Action, ActionEvent, ActionId, ActionProvider, ActionProviderId, ActionRule, Create,
        ExecutableActionEvent, NewActionProvider, UserId,
    },
};

impl Create for ActionProvider {
    type New = NewActionProvider;

    fn create(mut action_provider: Self::New, conn: &PgConnection) -> QueryResult<Self> {
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
    pub fn authenticate(
        name: &str,
        password: &str,
        conn: &PgConnection,
    ) -> QueryResult<ActionProviderId> {
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
                        .filter(action::columns::action_provider_id.eq(action_provider_id))
                        .get_results::<ActionId>(conn)?,
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
                        .filter(action::columns::action_provider_id.eq(action_provider_id))
                        .get_results::<ActionId>(conn)?,
                ),
            )
            .get_results(conn)
    }
}

impl ActionEvent {
    pub fn get_by_action_provider(
        action_provider_id: ActionProviderId,
        conn: &PgConnection,
    ) -> QueryResult<Vec<Self>> {
        action_event::table
            .filter(
                action_event::columns::action_id.eq_any(
                    action::table
                        .select(action::columns::id)
                        .filter(action::columns::action_provider_id.eq(action_provider_id))
                        .get_results::<ActionId>(conn)?,
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
}

impl ExecutableActionEvent {
    pub fn get_by_action_provider(
        action_provider_id: ActionProviderId,
        conn: &PgConnection,
    ) -> QueryResult<Vec<Self>> {
        action_event::table
            .inner_join(action::table.inner_join(action_provider::table))
            .inner_join(
                platform_credentials::table.on(platform_credentials::columns::platform_id
                    .eq(action_provider::columns::platform_id)
                    .and(
                        platform_credentials::columns::user_id.eq(action_event::columns::user_id),
                    )),
            )
            .filter(action_provider::columns::id.eq(action_provider_id))
            .filter(action_event::columns::enabled.eq(true))
            .select((
                action_event::columns::id,
                action::columns::name,
                action_event::columns::datetime,
                platform_credentials::columns::username,
                platform_credentials::columns::password,
            ))
            .get_results::<ExecutableActionEvent>(conn)
    }

    pub fn get_ordered_by_action_provider_and_timerange(
        // TODO rename to span
        action_provider_id: ActionProviderId,
        start_datetime: NaiveDateTime,
        end_datetime: NaiveDateTime,
        conn: &PgConnection,
    ) -> QueryResult<Vec<Self>> {
        action_event::table
            .inner_join(action::table.inner_join(action_provider::table))
            .inner_join(
                platform_credentials::table.on(platform_credentials::columns::platform_id
                    .eq(action_provider::columns::platform_id)
                    .and(
                        platform_credentials::columns::user_id.eq(action_event::columns::user_id),
                    )),
            )
            .filter(action_provider::columns::id.eq(action_provider_id))
            .filter(action_event::columns::enabled.eq(true))
            .filter(action_event::columns::datetime.ge(start_datetime))
            .filter(action_event::columns::datetime.le(end_datetime))
            .select((
                action_event::columns::id,
                action::columns::name,
                action_event::columns::datetime,
                platform_credentials::columns::username,
                platform_credentials::columns::password,
            ))
            .order_by(action_event::columns::datetime)
            .get_results(conn)
    }
}
