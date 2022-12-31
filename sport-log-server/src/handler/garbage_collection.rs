use axum::{extract::Query, http::StatusCode};

use chrono::{DateTime, Utc};
use serde::Deserialize;
use sport_log_types::{
    Action, ActionEvent, ActionProvider, ActionRule, AuthAdmin, CardioBlueprint, CardioSession,
    DbConn, Diary, Group, GroupUser, HardDelete, Metcon, MetconItem, MetconMovement, MetconSession,
    Movement, MovementMuscle, Platform, PlatformCredential, Route, SharedCardioSession,
    SharedDiary, SharedMetconSession, SharedStrengthSession, StrengthBlueprint,
    StrengthBlueprintSet, StrengthSession, StrengthSet, TrainingPlan, Wod,
};

use crate::handler::HandlerResult;

#[derive(Debug, Deserialize)]
pub struct LastChange {
    pub last_change: DateTime<Utc>,
}

pub async fn adm_do_garbage_collection(
    _auth: AuthAdmin,
    Query(LastChange { last_change }): Query<LastChange>,
    db: DbConn,
) -> HandlerResult<StatusCode> {
    Platform::hard_delete(last_change, &db)?;
    PlatformCredential::hard_delete(last_change, &db)?;
    Action::hard_delete(last_change, &db)?;
    ActionProvider::hard_delete(last_change, &db)?;
    ActionRule::hard_delete(last_change, &db)?;
    ActionEvent::hard_delete(last_change, &db)?;
    Diary::hard_delete(last_change, &db)?;
    Wod::hard_delete(last_change, &db)?;
    Movement::hard_delete(last_change, &db)?;
    MovementMuscle::hard_delete(last_change, &db)?;
    TrainingPlan::hard_delete(last_change, &db)?;
    StrengthBlueprint::hard_delete(last_change, &db)?;
    StrengthBlueprintSet::hard_delete(last_change, &db)?;
    StrengthSession::hard_delete(last_change, &db)?;
    StrengthSet::hard_delete(last_change, &db)?;
    Metcon::hard_delete(last_change, &db)?;
    MetconMovement::hard_delete(last_change, &db)?;
    MetconSession::hard_delete(last_change, &db)?;
    MetconItem::hard_delete(last_change, &db)?;
    Route::hard_delete(last_change, &db)?;
    CardioBlueprint::hard_delete(last_change, &db)?;
    CardioSession::hard_delete(last_change, &db)?;
    Group::hard_delete(last_change, &db)?;
    GroupUser::hard_delete(last_change, &db)?;
    SharedDiary::hard_delete(last_change, &db)?;
    SharedStrengthSession::hard_delete(last_change, &db)?;
    SharedMetconSession::hard_delete(last_change, &db)?;
    SharedCardioSession::hard_delete(last_change, &db)?;

    Ok(StatusCode::OK)
}
