use diesel::PgConnection;
use rocket::http::Status;

use sport_log_server_derive::{
    InnerIntFromParam, VerifyIdForActionProvider, VerifyIdForAdmin, VerifyIdForUser,
    VerifyIdForUserUnchecked,
};

use crate::{
    auth::AuthenticatedActionProvider,
    model::{Action, ActionEvent, ActionEventId},
};

#[derive(InnerIntFromParam, VerifyIdForActionProvider)]
pub struct UnverifiedActionId(i32);

#[derive(VerifyIdForUser, InnerIntFromParam)]
pub struct UnverifiedActionRuleId(i32);

#[derive(VerifyIdForUser, InnerIntFromParam)]
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

#[derive(InnerIntFromParam, VerifyIdForAdmin, VerifyIdForUserUnchecked)]
pub struct UnverifiedActionProviderId(i32);
