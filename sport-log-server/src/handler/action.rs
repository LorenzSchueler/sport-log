use rocket::{http::Status, State};

use sport_log_types::{
    Action, ActionEvent, ActionEventId, ActionId, ActionProvider, ActionProviderId, ActionRule,
    ActionRuleId, AuthAP, AuthAdmin, AuthUser, Config, CreatableActionRule, Create, CreateMultiple,
    Db, DeletableActionEvent, ExecutableActionEvent, GetAll, GetById, GetByUser, Unverified,
    UnverifiedId, UnverifiedIds, Update, VerifyForActionProviderWithoutDb, VerifyForAdminWithoutDb,
    VerifyForUserWithDb, VerifyForUserWithoutDb, VerifyIdForActionProvider, VerifyIdForUser,
    VerifyIdUnchecked, VerifyIdsForActionProvider, VerifyIdsForAdmin,
    VerifyMultipleForActionProviderWithoutDb, VerifyMultipleForAdminWithoutDb,
    VerifyMultipleForUserWithDb, VerifyMultipleForUserWithoutDb, VerifyUnchecked,
};

use crate::handler::{DateTimeWrapper, IntoJson, JsonError, JsonResult};

#[post(
    "/adm/action_provider",
    format = "application/json",
    data = "<action_provider>"
)]
pub async fn adm_create_action_provider(
    action_provider: Unverified<ActionProvider>,
    auth: AuthAdmin,
    conn: Db,
) -> JsonResult<ActionProvider> {
    let action_provider = action_provider
        .verify_adm(&auth)
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| ActionProvider::create(action_provider, c))
        .await
        .into_json()
}

#[post(
    "/ap/action_provider",
    format = "application/json",
    data = "<action_provider>"
)]
pub async fn ap_create_action_provider(
    action_provider: Unverified<ActionProvider>,
    config: &State<Config>,
    conn: Db,
) -> JsonResult<ActionProvider> {
    if !config.ap_self_registration {
        return Err(JsonError {
            status: Status::Forbidden,
            message: None,
        });
    }
    let action_provider = action_provider
        .verify_unchecked()
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| ActionProvider::create(action_provider, c))
        .await
        .into_json()
}

#[get("/adm/action_provider")]
pub async fn adm_get_action_providers(
    _auth: AuthAdmin,
    conn: Db,
) -> JsonResult<Vec<ActionProvider>> {
    conn.run(|c| ActionProvider::get_all(c)).await.into_json()
}

#[get("/ap/action_provider")]
pub async fn ap_get_action_provider(auth: AuthAP, conn: Db) -> JsonResult<ActionProvider> {
    conn.run(move |c| ActionProvider::get_by_id(*auth, c))
        .await
        .into_json()
}

#[get("/action_provider")]
pub async fn get_action_providers(_auth: AuthUser, conn: Db) -> JsonResult<Vec<ActionProvider>> {
    conn.run(|c| ActionProvider::get_all(c)).await.into_json()
}

#[post("/ap/action", format = "application/json", data = "<action>")]
pub async fn ap_create_action(
    action: Unverified<Action>,
    auth: AuthAP,
    conn: Db,
) -> JsonResult<Action> {
    let action = action
        .verify_ap_without_db(&auth)
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| Action::create(action, c)).await.into_json()
}

#[post("/ap/actions", format = "application/json", data = "<actions>")]
pub async fn ap_create_actions(
    actions: Unverified<Vec<Action>>,
    auth: AuthAP,
    conn: Db,
) -> JsonResult<Vec<Action>> {
    let actions = actions
        .verify_ap_without_db(&auth)
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| Action::create_multiple(actions, c))
        .await
        .into_json()
}

#[get("/ap/action/<action_id>")]
pub async fn ap_get_action(
    action_id: UnverifiedId<ActionId>,
    auth: AuthAP,
    conn: Db,
) -> JsonResult<Action> {
    let action_id = conn
        .run(move |c| action_id.verify_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(move |c| Action::get_by_id(action_id, c))
        .await
        .into_json()
}

#[get("/ap/action")]
pub async fn ap_get_actions(auth: AuthAP, conn: Db) -> JsonResult<Vec<Action>> {
    conn.run(move |c| Action::get_by_action_provider(*auth, c))
        .await
        .into_json()
}

#[get("/action")]
pub async fn get_actions(_auth: AuthUser, conn: Db) -> JsonResult<Vec<Action>> {
    conn.run(|c| Action::get_all(c)).await.into_json()
}

#[post("/action_rule", format = "application/json", data = "<action_rule>")]
pub async fn create_action_rule(
    action_rule: Unverified<ActionRule>,
    auth: AuthUser,
    conn: Db,
) -> JsonResult<ActionRule> {
    let action_rule = action_rule
        .verify_user_without_db(&auth)
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| ActionRule::create(action_rule, c))
        .await
        .into_json()
}

#[post("/action_rules", format = "application/json", data = "<action_rules>")]
pub async fn create_action_rules(
    action_rules: Unverified<Vec<ActionRule>>,
    auth: AuthUser,
    conn: Db,
) -> JsonResult<Vec<ActionRule>> {
    let action_rules = action_rules
        .verify_user_without_db(&auth)
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| ActionRule::create_multiple(action_rules, c))
        .await
        .into_json()
}

#[get("/action_rule/<action_rule_id>")]
pub async fn get_action_rule(
    action_rule_id: UnverifiedId<ActionRuleId>,
    auth: AuthUser,
    conn: Db,
) -> JsonResult<ActionRule> {
    let action_rule_id = conn
        .run(move |c| action_rule_id.verify_user(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(move |c| ActionRule::get_by_id(action_rule_id, c))
        .await
        .into_json()
}

#[get("/action_rule")]
pub async fn get_action_rules(auth: AuthUser, conn: Db) -> JsonResult<Vec<ActionRule>> {
    conn.run(move |c| ActionRule::get_by_user(*auth, c))
        .await
        .into_json()
}

#[get("/action_rule/action_provider/<action_provider_id>")]
pub async fn get_action_rules_by_action_provider(
    action_provider_id: UnverifiedId<ActionProviderId>,
    auth: AuthUser,
    conn: Db,
) -> JsonResult<Vec<ActionRule>> {
    let action_provider_id = action_provider_id
        .verify_unchecked()
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(move |c| ActionRule::get_by_user_and_action_provider(*auth, action_provider_id, c))
        .await
        .into_json()
}

#[put("/action_rule", format = "application/json", data = "<action_rule>")]
pub async fn update_action_rule(
    action_rule: Unverified<ActionRule>,
    auth: AuthUser,
    conn: Db,
) -> JsonResult<ActionRule> {
    let action_rule = conn
        .run(move |c| action_rule.verify_user(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| ActionRule::update(action_rule, c))
        .await
        .into_json()
}

#[put("/action_rules", format = "application/json", data = "<action_rules>")]
pub async fn update_action_rules(
    action_rules: Unverified<Vec<ActionRule>>,
    auth: AuthUser,
    conn: Db,
) -> JsonResult<Vec<ActionRule>> {
    let action_rules = conn
        .run(move |c| action_rules.verify_user(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| ActionRule::update_multiple(action_rules, c))
        .await
        .into_json()
}

#[post("/action_event", format = "application/json", data = "<action_event>")]
pub async fn create_action_event(
    action_event: Unverified<ActionEvent>,
    auth: AuthUser,
    conn: Db,
) -> JsonResult<ActionEvent> {
    let action_event = action_event
        .verify_user_without_db(&auth)
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
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
    action_events: Unverified<Vec<ActionEvent>>,
    auth: AuthUser,
    conn: Db,
) -> JsonResult<Vec<ActionEvent>> {
    let action_events = action_events
        .verify_user_without_db(&auth)
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| ActionEvent::create_multiple(action_events, c))
        .await
        .into_json()
}

#[post(
    "/adm/action_events",
    format = "application/json",
    data = "<action_events>"
)]
pub async fn adm_create_action_events(
    action_events: Unverified<Vec<ActionEvent>>,
    auth: AuthAdmin,
    conn: Db,
) -> JsonResult<Vec<ActionEvent>> {
    let action_events = action_events
        .verify_adm(&auth)
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| ActionEvent::create_multiple_ignore_conflict(action_events, c))
        .await
        .into_json()
}

#[get("/action_event/<action_event_id>")]
pub async fn get_action_event(
    action_event_id: UnverifiedId<ActionEventId>,
    auth: AuthUser,
    conn: Db,
) -> JsonResult<ActionEvent> {
    let action_event_id = conn
        .run(move |c| action_event_id.verify_user(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(move |c| ActionEvent::get_by_id(action_event_id, c))
        .await
        .into_json()
}

#[get("/action_event")]
pub async fn get_action_events(auth: AuthUser, conn: Db) -> JsonResult<Vec<ActionEvent>> {
    conn.run(move |c| ActionEvent::get_by_user(*auth, c))
        .await
        .into_json()
}

#[get("/action_event/action_provider/<action_provider_id>")]
pub async fn get_action_events_by_action_provider(
    action_provider_id: UnverifiedId<ActionProviderId>,
    auth: AuthUser,
    conn: Db,
) -> JsonResult<Vec<ActionEvent>> {
    let action_provider_id = action_provider_id
        .verify_unchecked()
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(move |c| ActionEvent::get_by_user_and_action_provider(*auth, action_provider_id, c))
        .await
        .into_json()
}

#[put("/action_event", format = "application/json", data = "<action_event>")]
pub async fn update_action_event(
    action_event: Unverified<ActionEvent>,
    auth: AuthUser,
    conn: Db,
) -> JsonResult<ActionEvent> {
    let action_event = conn
        .run(move |c| action_event.verify_user(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| ActionEvent::update(action_event, c))
        .await
        .into_json()
}

#[put(
    "/action_events",
    format = "application/json",
    data = "<action_events>"
)]
pub async fn update_action_events(
    action_events: Unverified<Vec<ActionEvent>>,
    auth: AuthUser,
    conn: Db,
) -> JsonResult<Vec<ActionEvent>> {
    let action_events = conn
        .run(move |c| action_events.verify_user(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| ActionEvent::update_multiple(action_events, c))
        .await
        .into_json()
}

#[put(
    "/adm/action_event",
    format = "application/json",
    data = "<action_event>"
)]
pub async fn adm_update_action_event(
    action_event: Unverified<ActionEvent>,
    auth: AuthAdmin,
    conn: Db,
) -> JsonResult<ActionEvent> {
    let action_event = conn
        .run(move |_| action_event.verify_adm(&auth))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| ActionEvent::update(action_event, c))
        .await
        .into_json()
}

#[delete(
    "/ap/action_events",
    format = "application/json",
    data = "<action_event_ids>"
)]
pub async fn ap_disable_action_events(
    action_event_ids: UnverifiedIds<ActionEventId>,
    auth: AuthAP,
    conn: Db,
) -> Result<Status, JsonError> {
    conn.run(move |c| {
        ActionEvent::disable_multiple(
            action_event_ids
                .verify_ap(&auth, c)
                .map_err(|status| JsonError {
                    status,
                    message: None,
                })?,
            c,
        )
        .map(|_| Status::NoContent)
        .map_err(|_| JsonError {
            status: Status::InternalServerError,
            message: None,
        })
    })
    .await
}

#[delete(
    "/adm/action_events",
    format = "application/json",
    data = "<action_event_ids>"
)]
pub async fn adm_delete_action_events(
    action_event_ids: UnverifiedIds<ActionEventId>,
    auth: AuthAdmin,
    conn: Db,
) -> Result<Status, Status> {
    conn.run(move |c| {
        ActionEvent::delete_multiple(action_event_ids.verify_adm(&auth)?, c)
            .map(|_| Status::NoContent)
            .map_err(|_| Status::InternalServerError)
    })
    .await
}

#[get("/adm/creatable_action_rule")]
pub async fn adm_get_creatable_action_rules(
    _auth: AuthAdmin,
    conn: Db,
) -> JsonResult<Vec<CreatableActionRule>> {
    conn.run(move |c| CreatableActionRule::get_all(c))
        .await
        .into_json()
}

#[get("/ap/executable_action_event")]
pub async fn ap_get_executable_action_events(
    auth: AuthAP,
    conn: Db,
) -> JsonResult<Vec<ExecutableActionEvent>> {
    conn.run(move |c| ExecutableActionEvent::get_by_action_provider(*auth, c))
        .await
        .into_json()
}

#[get("/ap/executable_action_event/timespan/<start_datetime>/<end_datetime>")]
pub async fn ap_get_ordered_executable_action_events_by_timespan(
    start_datetime: DateTimeWrapper,
    end_datetime: DateTimeWrapper,
    auth: AuthAP,
    conn: Db,
) -> JsonResult<Vec<ExecutableActionEvent>> {
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

#[get("/adm/deletable_action_event")]
pub async fn adm_get_deletable_action_events(
    _auth: AuthAdmin,
    conn: Db,
) -> JsonResult<Vec<DeletableActionEvent>> {
    conn.run(move |c| DeletableActionEvent::get_all(c))
        .await
        .into_json()
}
