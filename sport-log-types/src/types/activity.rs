use serde::{Deserialize, Serialize};

use crate::types::{CardioSession, Diary, MetconSession, StrengthSession, Wod};

#[derive(Serialize, Deserialize, Debug, Clone)]
pub enum Activity {
    Diary(Diary),
    Wod(Wod),
    StrengthSession(StrengthSession),
    MetconSession(MetconSession),
    CardioSession(CardioSession),
}
