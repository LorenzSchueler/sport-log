use std::ops::Deref;

use chrono::{NaiveDateTime, NaiveTime};
use rocket::{http::Status, request::FromParam, serde::json::Json};

use crate::{
    auth::{AuthenticatedActionProvider, AuthenticatedAdmin, AuthenticatedUser},
    handler::to_json,
    model::{
        Action, ActionEvent, ActionProvider, ActionProviderId, ActionRule, ExecutableActionEvent,
        NewAction, NewActionEvent, NewActionProvider, NewActionRule,
    },
    verification::{UnverifiedActionEventId, UnverifiedActionId, UnverifiedActionRuleId},
    Db,
};

#[post(
    "/adm/action_provider",
    format = "application/json",
    data = "<action_provider>"
)]
pub async fn create_action_provider(
    action_provider: Json<NewActionProvider>,
    _auth: AuthenticatedAdmin,
    conn: Db,
) -> Result<Json<ActionProvider>, Status> {
    to_json(
        conn.run(|c| ActionProvider::create(action_provider.into_inner(), c))
            .await,
    )
}

#[get("/adm/action_provider")]
pub async fn get_action_providers(
    _auth: AuthenticatedAdmin,
    conn: Db,
) -> Result<Json<Vec<ActionProvider>>, Status> {
    to_json(conn.run(|c| ActionProvider::get_all(c)).await)
}

#[delete("/adm/action_provider/<action_provider_id>")]
pub async fn delete_action_provider(
    action_provider_id: ActionProviderId,
    _auth: AuthenticatedAdmin,
    conn: Db,
) -> Result<Status, Status> {
    conn.run(move |c| {
        Action::delete(action_provider_id, c)
            .map(|_| Status::NoContent)
            .map_err(|_| Status::InternalServerError)
    })
    .await
}

#[post("/ap/action", format = "application/json", data = "<action>")]
pub async fn create_action(
    action: Json<NewAction>,
    auth: AuthenticatedActionProvider,
    conn: Db,
) -> Result<Json<Action>, Status> {
    let action = NewAction::verify(action, auth)?;
    to_json(conn.run(|c| Action::create(action, c)).await)
}

#[get("/ap/action/<action_id>")]
pub async fn get_action(
    action_id: UnverifiedActionId,
    auth: AuthenticatedActionProvider,
    conn: Db,
) -> Result<Json<Action>, Status> {
    let action_id = conn.run(|c| action_id.verify_ap(auth, c)).await?;
    to_json(conn.run(move |c| Action::get_by_id(action_id, c)).await)
}

#[get("/ap/action")]
pub async fn get_actions_by_action_provider(
    auth: AuthenticatedActionProvider,
    conn: Db,
) -> Result<Json<Vec<Action>>, Status> {
    to_json(
        conn.run(move |c| Action::get_by_action_provider(*auth, c))
            .await,
    )
}

#[get("/action")]
pub async fn get_actions(_auth: AuthenticatedUser, conn: Db) -> Result<Json<Vec<Action>>, Status> {
    to_json(conn.run(|c| Action::get_all(c)).await)
}

#[delete("/ap/action/<action_id>")]
pub async fn delete_action(
    action_id: UnverifiedActionId,
    auth: AuthenticatedActionProvider,
    conn: Db,
) -> Result<Status, Status> {
    conn.run(|c| {
        Action::delete(action_id.verify_ap(auth, c)?, c)
            .map(|_| Status::NoContent)
            .map_err(|_| Status::InternalServerError)
    })
    .await
}

#[post("/action_rule", format = "application/json", data = "<action_rule>")]
pub async fn create_action_rule(
    action_rule: Json<NewActionRule>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<ActionRule>, Status> {
    let action_rule = NewActionRule::verify(action_rule, auth)?;
    to_json(conn.run(|c| ActionRule::create(action_rule, c)).await)
}

#[get("/action_rule/<action_rule_id>")]
pub async fn get_action_rule(
    action_rule_id: UnverifiedActionRuleId,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<ActionRule>, Status> {
    let action_rule_id = conn.run(|c| action_rule_id.verify(auth, c)).await?;
    to_json(
        conn.run(move |c| ActionRule::get_by_id(action_rule_id, c))
            .await,
    )
}

#[get("/action_rule")]
pub async fn get_action_rules_by_user(
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Vec<ActionRule>>, Status> {
    to_json(conn.run(move |c| ActionRule::get_by_user(*auth, c)).await)
}

#[get("/action_rule/action_provider/<action_provider_id>")]
pub async fn get_action_rules_by_user_and_action_provider(
    action_provider_id: ActionProviderId,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Vec<ActionRule>>, Status> {
    to_json(
        conn.run(move |c| {
            ActionRule::get_by_user_and_action_provider(*auth, action_provider_id, c)
        })
        .await,
    )
}

#[put("/action_rule", format = "application/json", data = "<action_rule>")]
pub async fn update_action_rule(
    action_rule: Json<ActionRule>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<ActionRule>, Status> {
    let action_rule = ActionRule::verify(action_rule, auth)?;
    to_json(conn.run(|c| ActionRule::update(action_rule, c)).await)
}

#[delete("/action_rule/<action_rule_id>")]
pub async fn delete_action_rule(
    action_rule_id: UnverifiedActionRuleId,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Status, Status> {
    conn.run(|c| {
        ActionRule::delete(action_rule_id.verify(auth, c)?, c)
            .map(|_| Status::NoContent)
            .map_err(|_| Status::InternalServerError)
    })
    .await
}

#[post("/action_event", format = "application/json", data = "<action_event>")]
pub async fn create_action_event(
    action_event: Json<NewActionEvent>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<ActionEvent>, Status> {
    let action_event = NewActionEvent::verify(action_event, auth)?;
    to_json(conn.run(|c| ActionEvent::create(action_event, c)).await)
}

#[get("/action_event/<action_event_id>")]
pub async fn get_action_event(
    action_event_id: UnverifiedActionEventId,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<ActionEvent>, Status> {
        let action_event_id = conn.run(|c| action_event_id.verify(auth, c)).await?;
    to_json(
        conn.run(move |c| ActionEvent::get_by_id(action_event_id, c))
            .await,
    )
}

#[get("/action_event")]
pub async fn get_action_events_by_user(
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Vec<ActionEvent>>, Status> {
    to_json(conn.run(move |c| ActionEvent::get_by_user(*auth, c)).await)
}

#[get("/ap/action_event")]
pub async fn get_action_events_by_action_provider(
    auth: AuthenticatedActionProvider,
    conn: Db,
) -> Result<Json<Vec<ActionEvent>>, Status> {
    to_json(
        conn.run(move |c| ActionEvent::get_by_action_provider(*auth, c))
            .await,
    )
}

#[get("/action_event/action_provider/<action_provider_id>")]
pub async fn get_action_events_by_user_and_action_provider(
    action_provider_id: ActionProviderId,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Vec<ActionEvent>>, Status> {
    to_json(
        conn.run(move |c| {
            ActionEvent::get_by_user_and_action_provider(*auth, action_provider_id, c)
        })
        .await,
    )
}

#[put("/action_event", format = "application/json", data = "<action_event>")]
pub async fn update_action_event(
    action_event: Json<ActionEvent>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<ActionEvent>, Status> {
    let action_event = ActionEvent::verify(action_event, auth)?;
    to_json(conn.run(|c| ActionEvent::update(action_event, c)).await)
}

#[delete("/action_event/<action_event_id>")]
pub async fn delete_action_event(
    action_event_id: UnverifiedActionEventId,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Status, Status> {
    conn.run(|c| {
        ActionEvent::delete(action_event_id.verify(auth, c)?, c)
            .map(|_| Status::NoContent)
            .map_err(|_| Status::InternalServerError)
    })
    .await
}

#[delete("/ap/action_event/<action_event_id>")]
pub async fn delete_action_event_ap(
    action_event_id: UnverifiedActionEventId,
    auth: AuthenticatedActionProvider,
    conn: Db,
) -> Result<Status, Status> {
    conn.run(|c| {
        ActionEvent::delete(action_event_id.verify_ap(auth, c)?, c)
            .map(|_| Status::NoContent)
            .map_err(|_| Status::InternalServerError)
    })
    .await
}

#[get("/ap/executable_action_event")]
pub async fn get_executable_action_events_by_action_provider(
    auth: AuthenticatedActionProvider,
    conn: Db,
) -> Result<Json<Vec<ExecutableActionEvent>>, Status> {
    to_json(
        conn.run(move |c| ExecutableActionEvent::get_by_action_provider(*auth, c))
            .await,
    )
}

#[get("/ap/executable_action_event/timerange/<start_time>/<end_time>")]
pub async fn get_executable_action_events_by_action_provider_and_timerange(
    start_time: NaiveDateTimeWrapper,
    end_time: NaiveDateTimeWrapper,
    auth: AuthenticatedActionProvider,
    conn: Db,
) -> Result<Json<Vec<ExecutableActionEvent>>, Status> {
    to_json(
        conn.run(move |c| {
            ExecutableActionEvent::get_by_action_provider_and_timerange(
                *auth,
                *start_time,
                *end_time,
                c,
            )
        })
        .await,
    )
}

pub struct NaiveTimeWrapper(NaiveTime);
pub struct NaiveDateTimeWrapper(NaiveDateTime);

impl<'v> FromParam<'v> for NaiveTimeWrapper {
    type Error = &'v str;

    fn from_param(param: &'v str) -> Result<Self, Self::Error> {
        Ok(NaiveTimeWrapper(param.parse().map_err(|_| param)?))
    }
}

impl<'v> FromParam<'v> for NaiveDateTimeWrapper {
    type Error = &'v str;

    fn from_param(param: &'v str) -> Result<NaiveDateTimeWrapper, Self::Error> {
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
