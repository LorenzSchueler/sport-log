use rocket::{http::Status, serde::json::Json};

use sport_log_types::{
    Action, ActionEvent, ActionEventId, ActionId, ActionProvider, ActionProviderId, ActionRule,
    ActionRuleId, AuthenticatedActionProvider, AuthenticatedAdmin, AuthenticatedUser, Create,
    CreateMultiple, Db, Delete, DeleteMultiple, ExecutableActionEvent, GetAll, GetById, GetByUser,
    NewAction, NewActionEvent, NewActionProvider, NewActionRule, Unverified, UnverifiedId,
    UnverifiedIds, Update, VerifyForActionProviderWithoutDb, VerifyForAdminWithoutDb,
    VerifyForUserWithDb, VerifyForUserWithoutDb, VerifyIdForActionProvider, VerifyIdForAdmin,
    VerifyIdForUser, VerifyIdForUserUnchecked, VerifyMultipleForUserWithoutDb,
    VerifyMultipleIdForUser,
};

use crate::handler::{IntoJson, NaiveDateTimeWrapper};

#[post(
    "/adm/action_provider",
    format = "application/json",
    data = "<action_provider>"
)]
pub async fn adm_create_action_provider(
    action_provider: Unverified<NewActionProvider>,
    auth: AuthenticatedAdmin,
    conn: Db,
) -> Result<Json<ActionProvider>, Status> {
    let action_provider = action_provider.verify_adm(&auth)?;
    conn.run(|c| ActionProvider::create(action_provider, c))
        .await
        .into_json()
}

#[get("/adm/action_provider")]
pub async fn adm_get_action_providers(
    _auth: AuthenticatedAdmin,
    conn: Db,
) -> Result<Json<Vec<ActionProvider>>, Status> {
    conn.run(|c| ActionProvider::get_all(c)).await.into_json()
}

#[delete("/adm/action_provider/<action_provider_id>")]
pub async fn adm_delete_action_provider(
    action_provider_id: UnverifiedId<ActionProviderId>,
    auth: AuthenticatedAdmin,
    conn: Db,
) -> Result<Status, Status> {
    let action_provider_id = action_provider_id.verify_adm(&auth)?;
    conn.run(move |c| {
        ActionProvider::delete(action_provider_id, c)
            .map(|_| Status::NoContent)
            .map_err(|_| Status::InternalServerError)
    })
    .await
}

#[post("/ap/action", format = "application/json", data = "<action>")]
pub async fn ap_create_action(
    action: Unverified<NewAction>,
    auth: AuthenticatedActionProvider,
    conn: Db,
) -> Result<Json<Action>, Status> {
    let action = action.verify_ap(&auth)?;
    conn.run(|c| Action::create(action, c)).await.into_json()
}

#[get("/ap/action/<action_id>")]
pub async fn ap_get_action(
    action_id: UnverifiedId<ActionId>,
    auth: AuthenticatedActionProvider,
    conn: Db,
) -> Result<Json<Action>, Status> {
    let action_id = conn.run(move |c| action_id.verify_ap(&auth, c)).await?;
    conn.run(move |c| Action::get_by_id(action_id, c))
        .await
        .into_json()
}

#[get("/ap/action")]
pub async fn ap_get_actions_by_action_provider(
    auth: AuthenticatedActionProvider,
    conn: Db,
) -> Result<Json<Vec<Action>>, Status> {
    conn.run(move |c| Action::get_by_action_provider(*auth, c))
        .await
        .into_json()
}

#[get("/action")]
pub async fn get_actions(_auth: AuthenticatedUser, conn: Db) -> Result<Json<Vec<Action>>, Status> {
    conn.run(|c| Action::get_all(c)).await.into_json()
}

#[delete("/ap/action/<action_id>")]
pub async fn ap_delete_action(
    action_id: UnverifiedId<ActionId>,
    auth: AuthenticatedActionProvider,
    conn: Db,
) -> Result<Status, Status> {
    conn.run(move |c| {
        Action::delete(action_id.verify_ap(&auth, c)?, c)
            .map(|_| Status::NoContent)
            .map_err(|_| Status::InternalServerError)
    })
    .await
}

#[post("/action_rule", format = "application/json", data = "<action_rule>")]
pub async fn create_action_rule(
    action_rule: Unverified<NewActionRule>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<ActionRule>, Status> {
    let action_rule = action_rule.verify(&auth)?;
    conn.run(|c| ActionRule::create(action_rule, c))
        .await
        .into_json()
}

#[post("/action_rules", format = "application/json", data = "<action_rules>")]
pub async fn create_action_rules(
    action_rules: Unverified<Vec<NewActionRule>>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Vec<ActionRule>>, Status> {
    let action_rules = action_rules.verify(&auth)?;
    conn.run(|c| ActionRule::create_multiple(action_rules, c))
        .await
        .into_json()
}

#[get("/action_rule/<action_rule_id>")]
pub async fn get_action_rule(
    action_rule_id: UnverifiedId<ActionRuleId>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<ActionRule>, Status> {
    let action_rule_id = conn.run(move |c| action_rule_id.verify(&auth, c)).await?;
    conn.run(move |c| ActionRule::get_by_id(action_rule_id, c))
        .await
        .into_json()
}

#[get("/action_rule")]
pub async fn get_action_rules_by_user(
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Vec<ActionRule>>, Status> {
    conn.run(move |c| ActionRule::get_by_user(*auth, c))
        .await
        .into_json()
}

#[get("/action_rule/action_provider/<action_provider_id>")]
pub async fn get_action_rules_by_user_and_action_provider(
    action_provider_id: UnverifiedId<ActionProviderId>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Vec<ActionRule>>, Status> {
    let action_provider_id = action_provider_id.verify_unchecked(&auth)?;
    conn.run(move |c| ActionRule::get_by_user_and_action_provider(*auth, action_provider_id, c))
        .await
        .into_json()
}

#[put("/action_rule", format = "application/json", data = "<action_rule>")]
pub async fn update_action_rule(
    action_rule: Unverified<ActionRule>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<ActionRule>, Status> {
    let action_rule = conn.run(move |c| action_rule.verify(&auth, c)).await?;
    conn.run(|c| ActionRule::update(action_rule, c))
        .await
        .into_json()
}

#[delete("/action_rule/<action_rule_id>")]
pub async fn delete_action_rule(
    action_rule_id: UnverifiedId<ActionRuleId>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Status, Status> {
    conn.run(move |c| {
        ActionRule::delete(action_rule_id.verify(&auth, c)?, c)
            .map(|_| Status::NoContent)
            .map_err(|_| Status::InternalServerError)
    })
    .await
}

#[delete(
    "/action_rules",
    format = "application/json",
    data = "<action_rule_ids>"
)]
pub async fn delete_action_rules(
    action_rule_ids: UnverifiedIds<ActionRuleId>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Status, Status> {
    conn.run(move |c| {
        ActionRule::delete_multiple(action_rule_ids.verify(&auth, c)?, c)
            .map(|_| Status::NoContent)
            .map_err(|_| Status::InternalServerError)
    })
    .await
}

#[post("/action_event", format = "application/json", data = "<action_event>")]
pub async fn create_action_event(
    action_event: Unverified<NewActionEvent>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<ActionEvent>, Status> {
    let action_event = action_event.verify(&auth)?;
    conn.run(|c| ActionEvent::create(action_event, c))
        .await
        .into_json()
}

#[post(
    "/action_events",
    format = "application/json",
    data = "<action_events>"
)]
pub async fn create_action_events(
    action_events: Unverified<Vec<NewActionEvent>>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Vec<ActionEvent>>, Status> {
    let action_events = action_events.verify(&auth)?;
    conn.run(|c| ActionEvent::create_multiple(action_events, c))
        .await
        .into_json()
}

#[get("/action_event/<action_event_id>")]
pub async fn get_action_event(
    action_event_id: UnverifiedId<ActionEventId>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<ActionEvent>, Status> {
    let action_event_id = conn.run(move |c| action_event_id.verify(&auth, c)).await?;
    conn.run(move |c| ActionEvent::get_by_id(action_event_id, c))
        .await
        .into_json()
}

#[get("/action_event")]
pub async fn get_action_events(
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Vec<ActionEvent>>, Status> {
    conn.run(move |c| ActionEvent::get_by_user(*auth, c))
        .await
        .into_json()
}

#[get("/ap/action_event")]
pub async fn ap_get_action_events(
    auth: AuthenticatedActionProvider,
    conn: Db,
) -> Result<Json<Vec<ActionEvent>>, Status> {
    conn.run(move |c| ActionEvent::get_by_action_provider(*auth, c))
        .await
        .into_json()
}

#[get("/action_event/action_provider/<action_provider_id>")]
pub async fn get_action_events_by_action_provider(
    action_provider_id: UnverifiedId<ActionProviderId>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Vec<ActionEvent>>, Status> {
    let action_provider_id = action_provider_id.verify_unchecked(&auth)?;
    conn.run(move |c| ActionEvent::get_by_user_and_action_provider(*auth, action_provider_id, c))
        .await
        .into_json()
}

#[put("/action_event", format = "application/json", data = "<action_event>")]
pub async fn update_action_event(
    action_event: Unverified<ActionEvent>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<ActionEvent>, Status> {
    let action_event = conn.run(move |c| action_event.verify(&auth, c)).await?;
    conn.run(|c| ActionEvent::update(action_event, c))
        .await
        .into_json()
}

#[delete("/action_event/<action_event_id>")]
pub async fn delete_action_event(
    action_event_id: UnverifiedId<ActionEventId>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Status, Status> {
    conn.run(move |c| {
        ActionEvent::delete(action_event_id.verify(&auth, c)?, c)
            .map(|_| Status::NoContent)
            .map_err(|_| Status::InternalServerError)
    })
    .await
}

#[delete(
    "/action_events",
    format = "application/json",
    data = "<action_event_ids>"
)]
pub async fn delete_action_events(
    action_event_ids: UnverifiedIds<ActionEventId>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Status, Status> {
    conn.run(move |c| {
        ActionEvent::delete_multiple(action_event_ids.verify(&auth, c)?, c)
            .map(|_| Status::NoContent)
            .map_err(|_| Status::InternalServerError)
    })
    .await
}

#[delete("/ap/action_event/<action_event_id>")]
pub async fn ap_delete_action_event(
    action_event_id: UnverifiedId<ActionEventId>,
    auth: AuthenticatedActionProvider,
    conn: Db,
) -> Result<Status, Status> {
    conn.run(move |c| {
        ActionEvent::delete(action_event_id.verify_ap(&auth, c)?, c)
            .map(|_| Status::NoContent)
            .map_err(|_| Status::InternalServerError)
    })
    .await
}

#[get("/ap/executable_action_event")]
pub async fn ap_get_executable_action_events(
    auth: AuthenticatedActionProvider,
    conn: Db,
) -> Result<Json<Vec<ExecutableActionEvent>>, Status> {
    conn.run(move |c| ExecutableActionEvent::get_by_action_provider(*auth, c))
        .await
        .into_json()
}

#[get("/ap/executable_action_event/timespan/<start_datetime>/<end_datetime>")]
pub async fn ap_get_ordered_executable_action_events_by_timespan(
    start_datetime: NaiveDateTimeWrapper,
    end_datetime: NaiveDateTimeWrapper,
    auth: AuthenticatedActionProvider,
    conn: Db,
) -> Result<Json<Vec<ExecutableActionEvent>>, Status> {
    conn.run(move |c| {
        ExecutableActionEvent::get_ordered_by_action_provider_and_timespan(
            *auth,
            *start_datetime,
            *end_datetime,
            c,
        )
    })
    .await
    .into_json()
}
