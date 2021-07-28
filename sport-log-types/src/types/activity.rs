use serde::{Deserialize, Serialize};

use crate::types::{
    CardioSessionDescription, Diary, MetconSessionDescription, StrengthSessionDescription, Wod,
};

/// Enum of all possible Activities and all their correlated types.
///
/// Used for the activity endpoint which provides a single endpoint for retrieving all Activities in a given timespan.
#[derive(Serialize, Deserialize, Debug, Clone)]
pub enum Activity {
    Diary(Diary),
    Wod(Wod),
    StrengthSession(StrengthSessionDescription),
    MetconSession(MetconSessionDescription),
    CardioSession(CardioSessionDescription),
}
