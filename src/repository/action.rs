use super::*;
use crate::schema::{action, action_event, action_rule};

pub fn create_action(new_action: NewAction, conn: &PgConnection) -> QueryResult<Action> {
    diesel::insert_into(action::table)
        .values(new_action)
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
    new_action_rule: NewActionRule,
    conn: &PgConnection,
) -> QueryResult<ActionRule> {
    diesel::insert_into(action_rule::table)
        .values(new_action_rule)
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
