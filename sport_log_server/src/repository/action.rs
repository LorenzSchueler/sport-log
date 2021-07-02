use chrono::NaiveDateTime;
use diesel::prelude::*;

use crate::{
    model::{
        //AccountId, Action, ActionEvent, ActionEventId, ActionId, ActionRule, ActionRuleId,
        //ExecutableActionEvent, NewAction, NewActionEvent, NewActionRule, PlatformId,
        AccountId,
        Action,
        ActionEvent,
        ActionId,
        ActionRule,
        ExecutableActionEvent,
        PlatformId,
    },
    schema::{action, action_event, action_rule, platform, platform_credentials},
};

impl Action {
    //pub fn create(action: NewAction, conn: &PgConnection) -> QueryResult<Action> {
    //diesel::insert_into(action::table)
    //.values(action)
    //.get_result(conn)
    //}

    //pub fn get_by_id(action_id: ActionId, conn: &PgConnection) -> QueryResult<Action> {
    //action::table.find(action_id).get_result(conn)
    //}

    pub fn get_by_platform(
        platform_id: PlatformId,
        conn: &PgConnection,
    ) -> QueryResult<Vec<Action>> {
        action::table
            .filter(action::columns::platform_id.eq(platform_id))
            .get_results(conn)
    }

    //pub fn delete(action_id: ActionId, conn: &PgConnection) -> QueryResult<usize> {
    //diesel::delete(action::table.find(action_id)).execute(conn)
    //}
}

impl ActionRule {
    //pub fn create(action_rule: NewActionRule, conn: &PgConnection) -> QueryResult<ActionRule> {
    //diesel::insert_into(action_rule::table)
    //.values(action_rule)
    //.get_result(conn)
    //}

    //pub fn get_by_id(action_rule_id: ActionRuleId, conn: &PgConnection) -> QueryResult<ActionRule> {
    //action_rule::table.find(action_rule_id).get_result(conn)
    //}

    pub fn get_by_account(
        account_id: AccountId,
        conn: &PgConnection,
    ) -> QueryResult<Vec<ActionRule>> {
        action_rule::table
            .filter(action_rule::columns::account_id.eq(account_id))
            .get_results(conn)
    }

    pub fn get_by_platform(
        platform_id: PlatformId,
        conn: &PgConnection,
    ) -> QueryResult<Vec<ActionRule>> {
        action_rule::table
            .filter(
                action_rule::columns::action_id.eq_any(
                    action::table
                        .select(action::columns::id)
                        .filter(action::columns::platform_id.eq(platform_id))
                        .get_results::<ActionId>(conn)?,
                ),
            )
            .get_results(conn)
    }

    pub fn get_by_account_and_platform(
        account_id: AccountId,
        platform_id: PlatformId,
        conn: &PgConnection,
    ) -> QueryResult<Vec<ActionRule>> {
        action_rule::table
            .filter(action_rule::columns::account_id.eq(account_id))
            .filter(
                action_rule::columns::action_id.eq_any(
                    action::table
                        .select(action::columns::id)
                        .filter(action::columns::platform_id.eq(platform_id))
                        .get_results::<ActionId>(conn)?,
                ),
            )
            .get_results(conn)
    }

    //pub fn update(
    //action_rule_id: ActionRuleId,
    //action_rule: ActionRule,
    //conn: &PgConnection,
    //) -> QueryResult<ActionRule> {
    //diesel::update(action_rule::table.find(action_rule_id))
    //.set(&action_rule)
    //.get_result(conn)
    //}

    //pub fn delete(action_rule_id: ActionRuleId, conn: &PgConnection) -> QueryResult<usize> {
    //diesel::delete(action_rule::table.find(action_rule_id)).execute(conn)
    //}
}

impl ActionEvent {
    //pub fn create(action_event: NewActionEvent, conn: &PgConnection) -> QueryResult<ActionEvent> {
    //diesel::insert_into(action_event::table)
    //.values(action_event)
    //.get_result(conn)
    //}

    //pub fn get_by_id(
    //action_event_id: ActionEventId,
    //conn: &PgConnection,
    //) -> QueryResult<ActionEvent> {
    //action_event::table.find(action_event_id).get_result(conn)
    //}

    pub fn get_by_account(
        account_id: AccountId,
        conn: &PgConnection,
    ) -> QueryResult<Vec<ActionEvent>> {
        action_event::table
            .filter(action_event::columns::account_id.eq(account_id))
            .get_results(conn)
    }

    pub fn get_by_platform(
        platform_id: PlatformId,
        conn: &PgConnection,
    ) -> QueryResult<Vec<ActionEvent>> {
        action_event::table
            .filter(
                action_event::columns::action_id.eq_any(
                    action::table
                        .select(action::columns::id)
                        .filter(action::columns::platform_id.eq(platform_id))
                        .get_results::<ActionId>(conn)?,
                ),
            )
            .get_results(conn)
    }

    pub fn get_by_platform_name(
        platform_name: String,
        conn: &PgConnection,
    ) -> QueryResult<Vec<ActionEvent>> {
        action_event::table
            .filter(
                action_event::columns::action_id.eq_any(
                    action::table
                        .select(action::columns::id)
                        .filter(
                            action::columns::platform_id.eq(platform::table
                                .select(platform::columns::id)
                                .filter(platform::columns::name.eq(platform_name))
                                .first::<PlatformId>(conn)?),
                        )
                        .get_results::<ActionId>(conn)?,
                ),
            )
            .get_results(conn)
    }

    pub fn get_by_account_and_platform(
        account_id: AccountId,
        platform_id: PlatformId,
        conn: &PgConnection,
    ) -> QueryResult<Vec<ActionEvent>> {
        action_event::table
            .filter(action_event::columns::account_id.eq(account_id))
            .filter(
                action_event::columns::action_id.eq_any(
                    action::table
                        .filter(action::columns::platform_id.eq(platform_id))
                        .select(action::columns::id),
                ),
            )
            .get_results(conn)
    }

    //pub fn update(
    //action_event_id: ActionEventId,
    //action_event: ActionEvent,
    //conn: &PgConnection,
    //) -> QueryResult<ActionEvent> {
    //diesel::update(action_event::table.find(action_event_id))
    //.set(&action_event)
    //.get_result(conn)
    //}

    //pub fn delete(action_event_id: ActionEventId, conn: &PgConnection) -> QueryResult<usize> {
    //diesel::delete(action_event::table.find(action_event_id)).execute(conn)
    //}
}

impl ExecutableActionEvent {
    pub fn get_by_platform_name(
        platform_name: String,
        conn: &PgConnection,
    ) -> QueryResult<Vec<ExecutableActionEvent>> {
        action_event::table
            .inner_join(action::table.inner_join(platform::table))
            .inner_join(
                platform_credentials::table.on(platform_credentials::columns::platform_id
                    .eq(platform::columns::id)
                    .and(
                        platform_credentials::columns::account_id
                            .eq(action_event::columns::account_id),
                    )),
            )
            .filter(platform::columns::name.eq(platform_name))
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

    pub fn get_by_platform_name_and_timerange(
        platform_name: String,
        start_time: NaiveDateTime,
        end_time: NaiveDateTime,
        conn: &PgConnection,
    ) -> QueryResult<Vec<ExecutableActionEvent>> {
        action_event::table
            .inner_join(action::table.inner_join(platform::table))
            .inner_join(
                platform_credentials::table.on(platform_credentials::columns::platform_id
                    .eq(platform::columns::id)
                    .and(
                        platform_credentials::columns::account_id
                            .eq(action_event::columns::account_id),
                    )),
            )
            .filter(platform::columns::name.eq(platform_name))
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
