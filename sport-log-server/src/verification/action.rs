use diesel::PgConnection;
use rocket::http::Status;
use rocket_contrib::json::Json;

use sport_log_server_derive::UnverifiedFromParamToVerified;

use crate::{
    auth::{AuthenticatedActionProvider, AuthenticatedUser},
    model::{
        Action, ActionEvent, ActionEventId, ActionId, ActionRule, ActionRuleId, NewAction,
        NewActionEvent, NewActionRule,
    },
};

impl NewAction {
    pub fn verify(action: Json<Self>, auth: AuthenticatedActionProvider) -> Result<Self, Status> {
        let action = action.into_inner();
        if action.action_provider_id == *auth {
            Ok(action)
        } else {
            Err(Status::Forbidden)
        }
    }
}

impl Action {
    pub fn verify(
        action: Json<Action>,
        auth: AuthenticatedActionProvider,
    ) -> Result<Action, Status> {
        let action = action.into_inner();
        if action.action_provider_id == *auth {
            Ok(action)
        } else {
            Err(Status::Forbidden)
        }
    }
}
pub struct UnverifiedActionId(ActionId);

impl<'v> rocket::request::FromParam<'v> for UnverifiedActionId {
    type Error = &'v rocket::http::RawStr;

    fn from_param(param: &'v rocket::http::RawStr) -> Result<Self, Self::Error> {
        Ok(Self(ActionId::from_param(param)?))
    }
}

impl UnverifiedActionId {
    pub fn verify(
        self,
        auth: AuthenticatedActionProvider,
        conn: &PgConnection,
    ) -> Result<ActionId, rocket::http::Status> {
        let entity = Action::get_by_id(self.0, conn)
            .map_err(|_| rocket::http::Status::InternalServerError)?;
        if entity.action_provider_id == *auth {
            Ok(self.0)
        } else {
            Err(rocket::http::Status::Forbidden)
        }
    }
}

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
