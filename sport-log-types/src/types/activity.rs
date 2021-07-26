use serde::{Deserialize, Serialize};

use crate::types::{CardioSession, Diary, MetconSession, StrengthSession, Wod};

/// Enum of all possible Activities.
///
/// Used for the activity endpoint which provides a single endpoint for retrieving all Activities in a given timerange.
#[derive(Serialize, Deserialize, Debug, Clone)]
pub enum Activity {
    Diary(Diary),
    Wod(Wod),
    StrengthSession(StrengthSession),
    MetconSession(MetconSession),
    CardioSession(CardioSession),
    //StrengthSession((StrengthSession, Vec<StrengthSet>)), // TODO
    //MetconSession((MetconSession, Metcon, Vec<MetconMovement>)),
    //CardioSession((CardioSession, Option<Route>)),
}
