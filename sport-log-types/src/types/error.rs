use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug)]
pub enum ErrorMessage {
    UniqueViolation(String),
    ForeignKeyViolation(String),
    PrimaryKeyViolation(String),
    Other(String),
}

#[derive(Serialize, Deserialize, Debug)]
pub struct Error {
    pub status: u16,
    pub message: Option<ErrorMessage>,
}
