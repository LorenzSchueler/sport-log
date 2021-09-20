use rocket::http::Status;

use sport_log_types::{
    Action, ActionEvent, ActionProvider, ActionRule, AuthAdmin, CardioBlueprint, CardioSession, Db,
    Diary, Group, GroupUser, HardDelete, Metcon, MetconItem, MetconMovement, MetconSession,
    Movement, MovementMuscle, Platform, PlatformCredential, Route, SharedCardioSession,
    SharedDiary, SharedMetconSession, SharedStrengthSession, StrengthBlueprint,
    StrengthBlueprintSet, StrengthSession, StrengthSet, TrainingPlan, Wod,
};

use crate::handler::DateTimeWrapper;

#[delete("/adm/garbage_collection/<last_change>")]
pub async fn adm_garbage_collect(
    last_change: DateTimeWrapper,
    _auth: AuthAdmin,
    conn: Db,
) -> Result<Status, Status> {
    conn.run(move |c| {
        Platform::hard_delete(*last_change, c).map_err(|_| Status::InternalServerError)?;
        PlatformCredential::hard_delete(*last_change, c)
            .map_err(|_| Status::InternalServerError)?;
        Action::hard_delete(*last_change, c).map_err(|_| Status::InternalServerError)?;
        ActionProvider::hard_delete(*last_change, c).map_err(|_| Status::InternalServerError)?;
        ActionRule::hard_delete(*last_change, c).map_err(|_| Status::InternalServerError)?;
        ActionEvent::hard_delete(*last_change, c).map_err(|_| Status::InternalServerError)?;
        Diary::hard_delete(*last_change, c).map_err(|_| Status::InternalServerError)?;
        Wod::hard_delete(*last_change, c).map_err(|_| Status::InternalServerError)?;
        Movement::hard_delete(*last_change, c).map_err(|_| Status::InternalServerError)?;
        MovementMuscle::hard_delete(*last_change, c).map_err(|_| Status::InternalServerError)?;
        TrainingPlan::hard_delete(*last_change, c).map_err(|_| Status::InternalServerError)?;
        StrengthBlueprint::hard_delete(*last_change, c).map_err(|_| Status::InternalServerError)?;
        StrengthBlueprintSet::hard_delete(*last_change, c)
            .map_err(|_| Status::InternalServerError)?;
        StrengthSession::hard_delete(*last_change, c).map_err(|_| Status::InternalServerError)?;
        StrengthSet::hard_delete(*last_change, c).map_err(|_| Status::InternalServerError)?;
        Metcon::hard_delete(*last_change, c).map_err(|_| Status::InternalServerError)?;
        MetconMovement::hard_delete(*last_change, c).map_err(|_| Status::InternalServerError)?;
        MetconSession::hard_delete(*last_change, c).map_err(|_| Status::InternalServerError)?;
        MetconItem::hard_delete(*last_change, c).map_err(|_| Status::InternalServerError)?;
        Route::hard_delete(*last_change, c).map_err(|_| Status::InternalServerError)?;
        CardioBlueprint::hard_delete(*last_change, c).map_err(|_| Status::InternalServerError)?;
        CardioSession::hard_delete(*last_change, c).map_err(|_| Status::InternalServerError)?;
        Group::hard_delete(*last_change, c).map_err(|_| Status::InternalServerError)?;
        GroupUser::hard_delete(*last_change, c).map_err(|_| Status::InternalServerError)?;
        SharedDiary::hard_delete(*last_change, c).map_err(|_| Status::InternalServerError)?;
        SharedStrengthSession::hard_delete(*last_change, c)
            .map_err(|_| Status::InternalServerError)?;
        SharedMetconSession::hard_delete(*last_change, c)
            .map_err(|_| Status::InternalServerError)?;
        SharedCardioSession::hard_delete(*last_change, c)
            .map_err(|_| Status::InternalServerError)?;

        Ok(Status::NoContent)
    })
    .await
}
