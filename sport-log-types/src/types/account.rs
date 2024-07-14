use serde::{Deserialize, Serialize};

use crate::*;

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
}
