use super::*;
use repo::action;

#[post("/action", format = "application/json", data = "<new_action>")]
pub fn create_action(new_action: Json<NewAction>, conn: Db) -> Result<Json<Action>, Status> {
    to_json(action::create_action(new_action.into_inner(), &conn))
}

#[get("/action/<action_id>")]
pub fn get_action(action_id: ActionId, conn: Db) -> Result<Json<Action>, Status> {
    to_json(action::get_action(action_id, &conn))
}

#[get("/action/platform/<platform_id>")]
pub fn get_actions_by_platform(
    platform_id: PlatformId,
    conn: Db,
) -> Result<Json<Vec<Action>>, Status> {
    to_json(action::get_actions_by_platform(platform_id, &conn))
}

#[delete("/action/<action_id>")]
pub fn delete_action(action_id: ActionId, conn: Db) -> Result<Status, Status> {
    action::delete_action(action_id, &conn)
        .map(|_| Status::NoContent)
        .map_err(|_| Status::InternalServerError)
}

#[post(
    "/action_rule",
    format = "application/json",
    data = "<new_action_rule>"
)]
pub fn create_action_rule(
    new_action_rule: Json<NewActionRule>,
    conn: Db,
) -> Result<Json<ActionRule>, Status> {
    to_json(action::create_action_rule(
        new_action_rule.into_inner(),
        &conn,
    ))
}

#[get("/action_rule/<action_rule_id>")]
pub fn get_action_rule(action_rule_id: ActionRuleId, conn: Db) -> Result<Json<ActionRule>, Status> {
    to_json(action::get_action_rule(action_rule_id, &conn))
}

#[get("/action_rule/account/<account_id>")]
pub fn get_action_rules_by_account(
    account_id: AccountId,
    conn: Db,
) -> Result<Json<Vec<ActionRule>>, Status> {
    to_json(action::get_action_rules_by_account(account_id, &conn))
}

#[get("/action_rule/platform/<platform_id>")]
pub fn get_action_rules_by_platform(
    platform_id: PlatformId,
    conn: Db,
) -> Result<Json<Vec<ActionRule>>, Status> {
    to_json(action::get_action_rules_by_platform(platform_id, &conn))
}

#[get("/action_rule/account/<account_id>/platform/<platform_id>")]
pub fn get_action_rules_by_account_and_platform(
    account_id: AccountId,
    platform_id: PlatformId,
    conn: Db,
) -> Result<Json<Vec<ActionRule>>, Status> {
    to_json(action::get_action_rules_by_account_and_platform(
        account_id,
        platform_id,
        &conn,
    ))
}

#[put("/action_rule", format = "application/json", data = "<action_rule>")]
pub fn update_action_rule(action_rule: Json<ActionRule>, conn: Db) -> Result<Json<ActionRule>, Status> {
    to_json(action::update_action_rule(
        action_rule.id,
        action_rule.into_inner(),
        &conn,
    ))
}

#[delete("/action_rule/<action_rule_id>")]
pub fn delete_action_rule(action_rule_id: ActionRuleId, conn: Db) -> Result<Status, Status> {
    action::delete_action_rule(action_rule_id, &conn)
        .map(|_| Status::NoContent)
        .map_err(|_| Status::InternalServerError)
}
