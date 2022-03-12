use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug)]
pub struct ConflictDescriptor {
    pub table: String,
    pub columns: Vec<String>,
}

#[derive(Serialize, Deserialize, Debug)]
pub enum ErrorMessage {
    UniqueViolation(ConflictDescriptor),
    ForeignKeyViolation(ConflictDescriptor),
    PrimaryKeyViolation(ConflictDescriptor),
    Other(String),
}

#[derive(Serialize, Deserialize, Debug)]
pub struct Error {
    pub status: u16,
    pub message: Option<ErrorMessage>,
}
