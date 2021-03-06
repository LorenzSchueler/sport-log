use serde::{Deserialize, Serialize};

/// The lowest and highest version supported by the server.
#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct Version {
    pub min: String,
    pub max: String,
}
