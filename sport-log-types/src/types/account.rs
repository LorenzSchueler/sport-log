use serde::{Deserialize, Serialize};

use crate::*;

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct EpochMap {
    pub user: Epoch,
    pub diary: Epoch,
    pub wod: Epoch,
    pub movement: Epoch,
    pub strength_session: Epoch,
    pub strength_set: Epoch,
    pub metcon: Epoch,
    pub metcon_session: Epoch,
    pub metcon_movement: Epoch,
    pub cardio_session: Epoch,
    pub route: Epoch,
    pub platform: Epoch,
    pub platform_credential: Epoch,
    pub action_provider: Epoch,
    pub action: Epoch,
    pub action_rule: Epoch,
    pub action_event: Epoch,
}

/// A representation of all or recently updated data belonging to a user account.
///
/// This struct is used for the `account_data` endpoints.
#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct AccountData {
    pub user: Option<User>,
    pub diaries: Vec<Diary>,
    pub wods: Vec<Wod>,
    pub movements: Vec<Movement>,
    pub strength_sessions: Vec<StrengthSession>,
    pub strength_sets: Vec<StrengthSet>,
    pub metcons: Vec<Metcon>,
    pub metcon_sessions: Vec<MetconSession>,
    pub metcon_movements: Vec<MetconMovement>,
    pub cardio_sessions: Vec<CardioSession>,
    pub routes: Vec<Route>,
    pub platforms: Vec<Platform>,
    pub platform_credentials: Vec<PlatformCredential>,
    pub action_providers: Vec<ActionProvider>,
    pub actions: Vec<Action>,
    pub action_rules: Vec<ActionRule>,
    pub action_events: Vec<ActionEvent>,
    pub epoch_map: EpochMap,
}
