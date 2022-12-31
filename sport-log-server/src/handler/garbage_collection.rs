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
    mut db: DbConn,
) -> HandlerResult<StatusCode> {
    Platform::hard_delete(last_change, &mut db)?;
    PlatformCredential::hard_delete(last_change, &mut db)?;
    Action::hard_delete(last_change, &mut db)?;
    ActionProvider::hard_delete(last_change, &mut db)?;
    ActionRule::hard_delete(last_change, &mut db)?;
    ActionEvent::hard_delete(last_change, &mut db)?;
    Diary::hard_delete(last_change, &mut db)?;
    Wod::hard_delete(last_change, &mut db)?;
    Movement::hard_delete(last_change, &mut db)?;
    MovementMuscle::hard_delete(last_change, &mut db)?;
    TrainingPlan::hard_delete(last_change, &mut db)?;
    StrengthBlueprint::hard_delete(last_change, &mut db)?;
    StrengthBlueprintSet::hard_delete(last_change, &mut db)?;
    StrengthSession::hard_delete(last_change, &mut db)?;
    StrengthSet::hard_delete(last_change, &mut db)?;
    Metcon::hard_delete(last_change, &mut db)?;
    MetconMovement::hard_delete(last_change, &mut db)?;
    MetconSession::hard_delete(last_change, &mut db)?;
    MetconItem::hard_delete(last_change, &mut db)?;
    Route::hard_delete(last_change, &mut db)?;
    CardioBlueprint::hard_delete(last_change, &mut db)?;
    CardioSession::hard_delete(last_change, &mut db)?;
    Group::hard_delete(last_change, &mut db)?;
    GroupUser::hard_delete(last_change, &mut db)?;
    SharedDiary::hard_delete(last_change, &mut db)?;
    SharedStrengthSession::hard_delete(last_change, &mut db)?;
    SharedMetconSession::hard_delete(last_change, &mut db)?;
    SharedCardioSession::hard_delete(last_change, &mut db)?;

    Ok(StatusCode::OK)
}
