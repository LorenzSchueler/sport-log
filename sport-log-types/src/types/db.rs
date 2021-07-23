use diesel::pg::PgConnection;
use rocket_sync_db_pools::database;

#[database("sport_log")]
pub struct Db(PgConnection);
