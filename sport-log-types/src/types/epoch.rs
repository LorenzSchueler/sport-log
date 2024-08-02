use derive_deftly::Deftly;
#[cfg(feature = "db")]
use diesel::{deserialize::FromSqlRow, expression::AsExpression, sql_types::BigInt};
use serde::{Deserialize, Serialize};

use crate::types::IdString;

#[derive(Serialize, Deserialize, Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Deftly)]
#[derive_deftly(IdString)]
#[serde(try_from = "IdString", into = "IdString")]
#[cfg_attr(
    feature = "db",
    derive(FromSqlRow, AsExpression),
    derive_deftly(IntoPgBigInt, FromPgBigInt),
    diesel(sql_type = BigInt)
)]
pub struct Epoch(pub i64);

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct EpochResponse {
    pub epoch: Epoch,
}
