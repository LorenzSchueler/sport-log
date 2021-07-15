use diesel::PgConnection;
use rocket::{http::Status, serde::json::Json};

use sport_log_server_derive::{InnerIntFromParam, VerifyForUser};

use crate::{
    auth::{AuthenticatedActionProvider, AuthenticatedAdmin, AuthenticatedUser},
    model::{
        Action, ActionEvent, ActionEventId, ActionId, ActionProvider, ActionProviderId, ActionRule,
        NewAction, NewActionEvent, NewActionProvider, NewActionRule,
    },
};

impl NewAction {
    pub fn verify(action: Json<Self>, auth: &AuthenticatedActionProvider) -> Result<Self, Status> {
        let action = action.into_inner();
        if action.action_provider_id == **auth {
            Ok(action)
        } else {
            Err(Status::Forbidden)
        }
    }
}

impl Action {
    pub fn verify(
        action: Json<Action>,
        auth: &AuthenticatedActionProvider,
    ) -> Result<Action, Status> {
        let action = action.into_inner();
        if action.action_provider_id == **auth {
            Ok(action)
        } else {
            Err(Status::Forbidden)
        }
    }
}

#[derive(InnerIntFromParam)]
pub struct UnverifiedActionId(i32);

impl UnverifiedActionId {
    pub fn verify_ap(
        self,
        auth: &AuthenticatedActionProvider,
        conn: &PgConnection,
    ) -> Result<ActionId, Status> {
        let entity =
            Action::get_by_id(ActionId(self.0), conn).map_err(|_| Status::InternalServerError)?;
        if entity.action_provider_id == **auth {
            Ok(ActionId(self.0))
        } else {
            Err(Status::Forbidden)
        }
    }
}

impl NewActionRule {
    pub fn verify(
        action_rule: Json<NewActionRule>,
        auth: &AuthenticatedUser,
    ) -> Result<NewActionRule, Status> {
        let action_rule = action_rule.into_inner();
        if action_rule.user_id == **auth {
            Ok(action_rule)
        } else {
            Err(Status::Forbidden)
        }
    }
}

impl ActionRule {
    pub fn verify(
        action_rule: Json<ActionRule>,
        auth: &AuthenticatedUser,
    ) -> Result<ActionRule, Status> {
        let action_rule = action_rule.into_inner();
        if action_rule.user_id == **auth {
            Ok(action_rule)
        } else {
            Err(Status::Forbidden)
        }
    }
}

#[derive(VerifyForUser, InnerIntFromParam)]
pub struct UnverifiedActionRuleId(i32);

impl NewActionEvent {
    pub fn verify(
        action_event: Json<NewActionEvent>,
        auth: &AuthenticatedUser,
    ) -> Result<NewActionEvent, Status> {
        let action_event = action_event.into_inner();
        if action_event.user_id == **auth {
            Ok(action_event)
        } else {
            Err(Status::Forbidden)
        }
    }
}

impl ActionEvent {
    pub fn verify(
        action_event: Json<ActionEvent>,
        auth: &AuthenticatedUser,
    ) -> Result<ActionEvent, Status> {
        let action_event = action_event.into_inner();
        if action_event.user_id == **auth {
            Ok(action_event)
        } else {
            Err(Status::Forbidden)
        }
    }
}

#[derive(VerifyForUser, InnerIntFromParam)]
pub struct UnverifiedActionEventId(i32);

impl UnverifiedActionEventId {
    pub fn verify_ap(
        self,
        auth: &AuthenticatedActionProvider,
        conn: &PgConnection,
    ) -> Result<ActionEventId, Status> {
        let action_event = ActionEvent::get_by_id(ActionEventId(self.0), conn)
            .map_err(|_| Status::InternalServerError)?;
        let entity = Action::get_by_id(action_event.action_id, conn)
            .map_err(|_| Status::InternalServerError)?;
        if entity.action_provider_id == **auth {
            Ok(ActionEventId(self.0))
        } else {
            Err(Status::Forbidden)
        }
    }
}

impl NewActionProvider {
    pub fn verify_adm(
        action_provider: Json<NewActionProvider>,
        _auth: &AuthenticatedAdmin,
    ) -> Result<NewActionProvider, Status> {
        Ok(action_provider.into_inner())
    }
}

impl ActionProvider {
    pub fn verify_adm(
        action_provider: Json<ActionProvider>,
        _auth: &AuthenticatedAdmin,
    ) -> Result<ActionProvider, Status> {
        Ok(action_provider.into_inner())
    }
}

#[derive(InnerIntFromParam)]
pub struct UnverifiedActionProviderId(i32);

impl UnverifiedActionProviderId {
    pub fn verify_adm(self, _auth: &AuthenticatedAdmin) -> Result<ActionProviderId, Status> {
        Ok(ActionProviderId(self.0))
    }

    pub fn verify(self, _auth: &AuthenticatedUser) -> Result<ActionProviderId, Status> {
        Ok(ActionProviderId(self.0))
    }
}
