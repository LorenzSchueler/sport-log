use serde::{Deserialize, Serialize};

use crate::{
    Action, ActionEvent, ActionProvider, ActionRule, CardioBlueprint, CardioSession, Diary, Metcon,
    MetconItem, MetconMovement, MetconSession, Movement, MovementMuscle, Platform,
    PlatformCredential, Route, StrengthBlueprint, StrengthBlueprintSet, StrengthSession,
    StrengthSet, TrainingPlan, User, Wod,
};

/// A representation of all or recently updated data belonging to a user account.
///
/// This struct is used for the `account_data` endpoints.
#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct AccountData {
    pub user: Option<User>,
    pub diaries: Vec<Diary>,
    pub wods: Vec<Wod>,
    pub movements: Vec<Movement>,
    pub movement_muscles: Vec<MovementMuscle>,
    pub strength_blueprints: Vec<StrengthBlueprint>,
    pub strength_blueprint_sets: Vec<StrengthBlueprintSet>,
    pub strength_sessions: Vec<StrengthSession>,
    pub strength_sets: Vec<StrengthSet>,
    pub metcons: Vec<Metcon>,
    pub metcon_sessions: Vec<MetconSession>,
    pub metcon_movements: Vec<MetconMovement>,
    pub metcon_items: Vec<MetconItem>,
    pub cardio_blueprints: Vec<CardioBlueprint>,
    pub cardio_sessions: Vec<CardioSession>,
    pub routes: Vec<Route>,
    pub training_plans: Vec<TrainingPlan>,
    pub platforms: Vec<Platform>,
    pub platform_credentials: Vec<PlatformCredential>,
    pub action_providers: Vec<ActionProvider>,
    pub actions: Vec<Action>,
    pub action_rules: Vec<ActionRule>,
    pub action_events: Vec<ActionEvent>,
}
