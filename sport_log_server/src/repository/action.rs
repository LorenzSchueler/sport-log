use chrono::NaiveDateTime;
use diesel::prelude::*;

use crate::{
    model::{
        AccountId, Action, ActionEvent, ActionProvider, ActionProviderId, ActionRule,
        ExecutableActionEvent,
    },
    schema::{action, action_event, action_provider, action_rule, platform_credentials},
};
impl ActionProvider {
    pub fn authenticate(
        name: &str,
        password: &str,
        conn: &PgConnection,
    ) -> QueryResult<ActionProviderId> {
        action_provider::table
            .filter(action_provider::columns::name.eq(name))
            .filter(action_provider::columns::password.eq(password)) // TODO use hash function
            .select(action_provider::columns::id)
            .get_result(conn)
    }
}

impl Action {
    pub fn get_by_action_provider(
        action_provider_id: ActionProviderId,
        conn: &PgConnection,
    ) -> QueryResult<Vec<Action>> {
        action::table
            .filter(action::columns::action_provider_id.eq(action_provider_id))
            .get_results(conn)
    }
}

impl ActionRule {
    pub fn get_by_account(
        account_id: AccountId,
        conn: &PgConnection,
    ) -> QueryResult<Vec<ActionRule>> {
        action_rule::table
            .filter(action_rule::columns::account_id.eq(account_id))
            .get_results(conn)
    }

    //pub fn get_by_platform(
    //platform_id: PlatformId,
    //conn: &PgConnection,
    //) -> QueryResult<Vec<ActionRule>> {
    //action_rule::table
    //.filter(
    //action_rule::columns::action_id.eq_any(
    //action::table
    //.select(action::columns::id)
    //.filter(action::columns::platform_id.eq(platform_id))
    //.get_results::<ActionId>(conn)?,
    //),
    //)
    //.get_results(conn)
    //}

    //pub fn get_by_account_and_platform(
    //account_id: AccountId,
    //platform_id: PlatformId,
    //conn: &PgConnection,
    //) -> QueryResult<Vec<ActionRule>> {
    //action_rule::table
    //.filter(action_rule::columns::account_id.eq(account_id))
    //.filter(
    //action_rule::columns::action_id.eq_any(
    //action::table
    //.select(action::columns::id)
    //.filter(action::columns::platform_id.eq(platform_id))
    //.get_results::<ActionId>(conn)?,
    //),
    //)
    //.get_results(conn)
    //}
}

impl ActionEvent {
    pub fn get_by_account(
        account_id: AccountId,
        conn: &PgConnection,
    ) -> QueryResult<Vec<ActionEvent>> {
        action_event::table
            .filter(action_event::columns::account_id.eq(account_id))
            .get_results(conn)
    }

    //pub fn get_by_platform(
    //platform_id: PlatformId,
    //conn: &PgConnection,
    //) -> QueryResult<Vec<ActionEvent>> {
    //action_event::table
    //.filter(
    //action_event::columns::action_id.eq_any(
    //action::table
    //.select(action::columns::id)
    //.filter(action::columns::platform_id.eq(platform_id))
    //.get_results::<ActionId>(conn)?,
    //),
    //)
    //.get_results(conn)
    //}

    //pub fn get_by_platform_name(
    //platform_name: String,
    //conn: &PgConnection,
    //) -> QueryResult<Vec<ActionEvent>> {
    //action_event::table
    //.filter(
    //action_event::columns::action_id.eq_any(
    //action::table
    //.select(action::columns::id)
    //.filter(
    //action::columns::platform_id.eq(platform::table
    //.select(platform::columns::id)
    //.filter(platform::columns::name.eq(platform_name))
    //.first::<PlatformId>(conn)?),
    //)
    //.get_results::<ActionId>(conn)?,
    //),
    //)
    //.get_results(conn)
    //}

    //pub fn get_by_account_and_platform(
    //account_id: AccountId,
    //platform_id: PlatformId,
    //conn: &PgConnection,
    //) -> QueryResult<Vec<ActionEvent>> {
    //action_event::table
    //.filter(action_event::columns::account_id.eq(account_id))
    //.filter(
    //action_event::columns::action_id.eq_any(
    //action::table
    //.filter(action::columns::platform_id.eq(platform_id))
    //.select(action::columns::id),
    //),
    //)
    //.get_results(conn)
    //}
}

impl ExecutableActionEvent {
    pub fn get_by_action_provider_name(
        action_provider_name: String,
        conn: &PgConnection,
    ) -> QueryResult<Vec<ExecutableActionEvent>> {
        action_event::table
            .inner_join(action::table.inner_join(action_provider::table))
            .inner_join(
                platform_credentials::table.on(platform_credentials::columns::platform_id
                    .eq(action_provider::columns::platform_id)
                    .and(
                        platform_credentials::columns::account_id
                            .eq(action_event::columns::account_id),
                    )),
            )
            .filter(action_provider::columns::name.eq(action_provider_name))
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

    pub fn get_by_action_provider_name_and_timerange(
        action_provider_name: String,
        start_time: NaiveDateTime,
        end_time: NaiveDateTime,
        conn: &PgConnection,
    ) -> QueryResult<Vec<ExecutableActionEvent>> {
        action_event::table
            .inner_join(action::table.inner_join(action_provider::table))
            .inner_join(
                platform_credentials::table.on(platform_credentials::columns::platform_id
                    .eq(action_provider::columns::platform_id)
                    .and(
                        platform_credentials::columns::account_id
                            .eq(action_event::columns::account_id),
                    )),
            )
            .filter(action_provider::columns::name.eq(action_provider_name))
            .filter(action_event::columns::enabled.eq(true))
            .filter(action_event::columns::datetime.ge(start_time))
            .filter(action_event::columns::datetime.le(end_time))
            .select((
                action_event::columns::id,
                action::columns::name,
                action_event::columns::datetime,
                platform_credentials::columns::username,
                platform_credentials::columns::password,
            ))
            .order_by(action_event::columns::datetime)
            .get_results::<ExecutableActionEvent>(conn)
    }
}
