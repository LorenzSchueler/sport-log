use diesel::PgConnection;
use rocket::http::Status;
use rocket_contrib::json::Json;

use sport_log_server_derive::UnverifiedFromParamToVerified;

use crate::{
    auth::AuthenticatedUser,
    model::{ActionEvent, ActionEventId, ActionRule, ActionRuleId, NewActionEvent, NewActionRule},
};

impl NewActionRule {
    pub fn verify(
        action_rule: Json<NewActionRule>,
        auth: AuthenticatedUser,
    ) -> Result<NewActionRule, Status> {
        let action_rule = action_rule.into_inner();
        if action_rule.user_id == *auth {
            Ok(action_rule)
        } else {
            Err(Status::Forbidden)
        }
    }
}

impl ActionRule {
    pub fn verify(
        action_rule: Json<ActionRule>,
        auth: AuthenticatedUser,
    ) -> Result<ActionRule, Status> {
        let action_rule = action_rule.into_inner();
        if action_rule.user_id == *auth {
            Ok(action_rule)
        } else {
            Err(Status::Forbidden)
        }
    }
}

#[derive(UnverifiedFromParamToVerified)]
pub struct UnverifiedActionRuleId(ActionRuleId);

impl NewActionEvent {
    pub fn verify(
        action_event: Json<NewActionEvent>,
        auth: AuthenticatedUser,
    ) -> Result<NewActionEvent, Status> {
        let action_event = action_event.into_inner();
        if action_event.user_id == *auth {
            Ok(action_event)
        } else {
            Err(Status::Forbidden)
        }
    }
}

impl ActionEvent {
    pub fn verify(
        action_event: Json<ActionEvent>,
        auth: AuthenticatedUser,
    ) -> Result<ActionEvent, Status> {
        let action_event = action_event.into_inner();
        if action_event.user_id == *auth {
            Ok(action_event)
        } else {
            Err(Status::Forbidden)
        }
    }
}

#[derive(UnverifiedFromParamToVerified)]
pub struct UnverifiedActionEventId(ActionEventId);
