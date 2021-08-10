use serde::{Deserialize, Serialize};

use crate::{
    Action, ActionEvent, ActionProvider, ActionRule, CardioSession, Diary, Metcon, MetconMovement,
    MetconSession, Movement, Platform, PlatformCredential, Route, StrengthSession, StrengthSet,
    User, Wod,
};

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct AccountData {
    pub user: User,
    pub diaries: Vec<Diary>,
    pub wods: Vec<Wod>,
    pub movements: Vec<Movement>,
    pub strenght_sessions: Vec<StrengthSession>,
    pub strenght_set: Vec<StrengthSet>,
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
    pub action_event: Vec<ActionEvent>,
}
