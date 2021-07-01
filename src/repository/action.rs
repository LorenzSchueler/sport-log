use diesel::prelude::*;

use crate::{
    model::{
        AccountId, Action, ActionEvent, ActionEventId, ActionId, ActionRule, ActionRuleId,
        NewAction, NewActionEvent, NewActionRule, PlatformId,
    },
    schema::{action, action_event, action_rule, platform},
};

pub fn create_action(action: NewAction, conn: &PgConnection) -> QueryResult<Action> {
    diesel::insert_into(action::table)
        .values(action)
        .get_result(conn)
}

pub fn get_action(action_id: ActionId, conn: &PgConnection) -> QueryResult<Action> {
    action::table.find(action_id).get_result(conn)
}

pub fn get_actions_by_platform(
    platform_id: PlatformId,
    conn: &PgConnection,
) -> QueryResult<Vec<Action>> {
    action::table
        .filter(action::columns::platform_id.eq(platform_id))
        .get_results(conn)
}

pub fn delete_action(action_id: ActionId, conn: &PgConnection) -> QueryResult<usize> {
    diesel::delete(action::table.find(action_id)).execute(conn)
}

pub fn create_action_rule(
    action_rule: NewActionRule,
    conn: &PgConnection,
) -> QueryResult<ActionRule> {
    diesel::insert_into(action_rule::table)
        .values(action_rule)
        .get_result(conn)
}

pub fn get_action_rule(
    action_rule_id: ActionRuleId,
    conn: &PgConnection,
) -> QueryResult<ActionRule> {
    action_rule::table.find(action_rule_id).get_result(conn)
}

pub fn get_action_rules_by_account(
    account_id: AccountId,
    conn: &PgConnection,
) -> QueryResult<Vec<ActionRule>> {
    action_rule::table
        .filter(action_rule::columns::account_id.eq(account_id))
        .get_results(conn)
}

pub fn get_action_rules_by_platform(
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

pub fn get_action_rules_by_account_and_platform(
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

pub fn update_action_rule(
    action_rule_id: ActionRuleId,
    action_rule: ActionRule,
    conn: &PgConnection,
) -> QueryResult<ActionRule> {
    diesel::update(action_rule::table.find(action_rule_id))
        .set(&action_rule)
        .get_result(conn)
}

pub fn delete_action_rule(action_rule_id: ActionRuleId, conn: &PgConnection) -> QueryResult<usize> {
    diesel::delete(action_rule::table.find(action_rule_id)).execute(conn)
}

pub fn create_action_event(
    action_event: NewActionEvent,
    conn: &PgConnection,
) -> QueryResult<ActionEvent> {
    diesel::insert_into(action_event::table)
        .values(action_event)
        .get_result(conn)
}

pub fn get_action_event(
    action_event_id: ActionEventId,
    conn: &PgConnection,
) -> QueryResult<ActionEvent> {
    action_event::table.find(action_event_id).get_result(conn)
}

pub fn get_action_events_by_account(
    account_id: AccountId,
    conn: &PgConnection,
) -> QueryResult<Vec<ActionEvent>> {
    action_event::table
        .filter(action_event::columns::account_id.eq(account_id))
        .get_results(conn)
}

pub fn get_action_events_by_platform(
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

pub fn get_action_events_by_platform_name(
    platform_name: String,
    conn: &PgConnection,
) -> QueryResult<Vec<ActionEvent>> {
    action_event::table
        .filter(
            action_event::columns::action_id.eq_any(
                action::table
                    .select(action::columns::id)
                    .filter(action::columns::platform_id.eq(platform::table
                        .select(platform::columns::id)
                        .filter(platform::columns::name.eq(platform_name))
                        .first::<PlatformId>(conn)?))
                    .get_results::<ActionId>(conn)?,
            ),
        )
        .get_results(conn)
}

pub fn get_action_events_by_account_and_platform(
    account_id: AccountId,
    platform_id: PlatformId,
    conn: &PgConnection,
) -> QueryResult<Vec<ActionEvent>> {
    action_event::table
        .filter(action_event::columns::account_id.eq(account_id))
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

pub fn update_action_event(
    action_event_id: ActionEventId,
    action_event: ActionEvent,
    conn: &PgConnection,
) -> QueryResult<ActionEvent> {
    diesel::update(action_event::table.find(action_event_id))
        .set(&action_event)
        .get_result(conn)
}

pub fn delete_action_event(
    action_event_id: ActionEventId,
    conn: &PgConnection,
) -> QueryResult<usize> {
    diesel::delete(action_event::table.find(action_event_id)).execute(conn)
}
