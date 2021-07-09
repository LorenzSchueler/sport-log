use std::ops::Deref;

use chrono::{NaiveDateTime, NaiveTime};
use rocket::{
    http::{RawStr, Status},
    request::FromParam,
};
use rocket_contrib::json::Json;

use crate::{
    auth::{AuthenticatedActionProvider, AuthenticatedUser},
    handler::to_json,
    model::{
        Action, ActionEvent, ActionId, ActionProviderId, ActionRule, ExecutableActionEvent,
        NewAction, NewActionEvent, NewActionRule,
    },
    verification::{UnverifiedActionEventId, UnverifiedActionRuleId},
    Db,
};

// TODO authentification
#[post("/action", format = "application/json", data = "<action>")]
pub fn create_action(action: Json<NewAction>, conn: Db) -> Result<Json<Action>, Status> {
    to_json(Action::create(action.into_inner(), &conn))
}

// TODO authentification
#[get("/action/<action_id>")]
pub fn get_action(action_id: ActionId, conn: Db) -> Result<Json<Action>, Status> {
    to_json(Action::get_by_id(action_id, &conn))
}

// TODO authentification
#[get("/action/platform/<action_provider_id>")]
pub fn get_actions_by_platform(
    action_provider_id: ActionProviderId,
    conn: Db,
) -> Result<Json<Vec<Action>>, Status> {
    to_json(Action::get_by_action_provider(action_provider_id, &conn))
}

// TODO authentification
#[delete("/action/<action_id>")]
pub fn delete_action(action_id: ActionId, conn: Db) -> Result<Status, Status> {
    Action::delete(action_id, &conn)
        .map(|_| Status::NoContent)
        .map_err(|_| Status::InternalServerError)
}

#[post("/action_rule", format = "application/json", data = "<action_rule>")]
pub fn create_action_rule(
    action_rule: Json<NewActionRule>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<ActionRule>, Status> {
    to_json(ActionRule::create(
        NewActionRule::verify(action_rule, auth)?,
        &conn,
    ))
}

#[get("/action_rule/<action_rule_id>")]
pub fn get_action_rule(
    action_rule_id: UnverifiedActionRuleId,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<ActionRule>, Status> {
    to_json(ActionRule::get_by_id(
        action_rule_id.verify(auth, &conn)?,
        &conn,
    ))
}

#[get("/action_rule")]
pub fn get_action_rules_by_user(
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Vec<ActionRule>>, Status> {
    to_json(ActionRule::get_by_user(*auth, &conn))
}

#[get("/action_rule/action_provider/<action_provider_id>")]
pub fn get_action_rules_by_user_and_action_provider(
    action_provider_id: ActionProviderId,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Vec<ActionRule>>, Status> {
    to_json(ActionRule::get_by_user_and_action_provider(
        *auth,
        action_provider_id,
        &conn,
    ))
}

#[put("/action_rule", format = "application/json", data = "<action_rule>")]
pub fn update_action_rule(
    action_rule: Json<ActionRule>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<ActionRule>, Status> {
    to_json(ActionRule::update(
        ActionRule::verify(action_rule, auth)?,
        &conn,
    ))
}

#[delete("/action_rule/<action_rule_id>")]
pub fn delete_action_rule(
    action_rule_id: UnverifiedActionRuleId,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Status, Status> {
    ActionRule::delete(action_rule_id.verify(auth, &conn)?, &conn)
        .map(|_| Status::NoContent)
        .map_err(|_| Status::InternalServerError)
}

#[post("/action_event", format = "application/json", data = "<action_event>")]
pub fn create_action_event(
    action_event: Json<NewActionEvent>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<ActionEvent>, Status> {
    to_json(ActionEvent::create(
        NewActionEvent::verify(action_event, auth)?,
        &conn,
    ))
}

#[get("/action_event/<action_event_id>")]
pub fn get_action_event(
    action_event_id: UnverifiedActionEventId,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<ActionEvent>, Status> {
    to_json(ActionEvent::get_by_id(
        action_event_id.verify(auth, &conn)?,
        &conn,
    ))
}

#[get("/action_event")]
pub fn get_action_events_by_user(
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Vec<ActionEvent>>, Status> {
    to_json(ActionEvent::get_by_user(*auth, &conn))
}

#[get("/ap/action_event")]
pub fn get_action_events_by_action_provider(
    auth: AuthenticatedActionProvider,
    conn: Db,
) -> Result<Json<Vec<ActionEvent>>, Status> {
    to_json(ActionEvent::get_by_action_provider(*auth, &conn))
}

#[get("/action_event/action_provider/<action_provider_id>")]
pub fn get_action_events_by_user_and_action_provider(
    action_provider_id: ActionProviderId,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Vec<ActionEvent>>, Status> {
    to_json(ActionEvent::get_by_user_and_action_provider(
        *auth,
        action_provider_id,
        &conn,
    ))
}

#[put("/action_event", format = "application/json", data = "<action_event>")]
pub fn update_action_event(
    action_event: Json<ActionEvent>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<ActionEvent>, Status> {
    to_json(ActionEvent::update(
        ActionEvent::verify(action_event, auth)?,
        &conn,
    ))
}

#[delete("/action_event/<action_event_id>")]
pub fn delete_action_event(
    action_event_id: UnverifiedActionEventId,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Status, Status> {
    ActionEvent::delete(action_event_id.verify(auth, &conn)?, &conn)
        .map(|_| Status::NoContent)
        .map_err(|_| Status::InternalServerError)
}

#[get("/ap/executable_action_event")]
pub fn get_executable_action_events_by_action_provider(
    auth: AuthenticatedActionProvider,
    conn: Db,
) -> Result<Json<Vec<ExecutableActionEvent>>, Status> {
    to_json(ExecutableActionEvent::get_by_action_provider(*auth, &conn))
}

#[get("/ap/executable_action_event/timerange/<start_time>/<end_time>")]
pub fn get_executable_action_events_by_action_provider_and_timerange(
    start_time: NaiveDateTimeWrapper,
    end_time: NaiveDateTimeWrapper,
    auth: AuthenticatedActionProvider,
    conn: Db,
) -> Result<Json<Vec<ExecutableActionEvent>>, Status> {
    to_json(ExecutableActionEvent::get_by_action_provider_and_timerange(
        *auth,
        *start_time,
        *end_time,
        &conn,
    ))
}

pub struct NaiveTimeWrapper(NaiveTime);
pub struct NaiveDateTimeWrapper(NaiveDateTime);

impl<'v> FromParam<'v> for NaiveTimeWrapper {
    type Error = &'v RawStr;

    fn from_param(param: &'v RawStr) -> Result<Self, Self::Error> {
        Ok(NaiveTimeWrapper(param.parse().map_err(|_| param)?))
    }
}

impl<'v> FromParam<'v> for NaiveDateTimeWrapper {
    type Error = &'v RawStr;

    fn from_param(param: &'v RawStr) -> Result<NaiveDateTimeWrapper, Self::Error> {
        Ok(NaiveDateTimeWrapper(param.parse().map_err(|_| param)?))
    }
}

impl Deref for NaiveTimeWrapper {
    type Target = NaiveTime;
    fn deref(&self) -> &NaiveTime {
        &self.0
    }
}

impl Deref for NaiveDateTimeWrapper {
    type Target = NaiveDateTime;
    fn deref(&self) -> &NaiveDateTime {
        &self.0
    }
}
