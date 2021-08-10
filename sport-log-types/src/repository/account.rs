use chrono::{DateTime, Utc};
use diesel::{PgConnection, QueryResult};

use crate::{
    AccountData, Action, ActionEvent, ActionProvider, ActionRule, CardioSession, Diary, GetAll,
    GetById, GetByUser, Metcon, MetconMovement, MetconSession, Movement, Platform,
    PlatformCredential, Route, StrengthSession, StrengthSet, User, UserId, Wod,
};

impl AccountData {
    pub fn get_by_user(user_id: UserId, conn: &PgConnection) -> QueryResult<Self> {
        Ok(AccountData {
            user: User::get_by_id(user_id, conn)?,
            diaries: Diary::get_by_user(user_id, conn)?,
            wods: Wod::get_by_user(user_id, conn)?,
            movements: Movement::get_by_user(user_id, conn)?,
            strenght_sessions: StrengthSession::get_by_user(user_id, conn)?,
            strenght_set: StrengthSet::get_by_user(user_id, conn)?,
            metcons: Metcon::get_by_user(user_id, conn)?,
            metcon_sessions: MetconSession::get_by_user(user_id, conn)?,
            metcon_movements: MetconMovement::get_by_user(user_id, conn)?,
            cardio_sessions: CardioSession::get_by_user(user_id, conn)?,
            routes: Route::get_by_user(user_id, conn)?,
            platforms: Platform::get_all(conn)?,
            platform_credentials: PlatformCredential::get_by_user(user_id, conn)?,
            action_providers: ActionProvider::get_all(conn)?,
            actions: Action::get_all(conn)?,
            action_rules: ActionRule::get_by_user(user_id, conn)?,
            action_event: ActionEvent::get_by_user(user_id, conn)?,
        })
    }

    pub fn get_by_user_and_last_sync(
        user_id: UserId,
        last_sync: DateTime<Utc>,
        conn: &PgConnection,
    ) -> QueryResult<Self> {
        Ok(AccountData {
            user: User::get_by_id(user_id, conn)?,
            diaries: Diary::get_by_user(user_id, conn)?,
            wods: Wod::get_by_user(user_id, conn)?,
            movements: Movement::get_by_user(user_id, conn)?,
            strenght_sessions: StrengthSession::get_by_user(user_id, conn)?,
            strenght_set: StrengthSet::get_by_user(user_id, conn)?,
            metcons: Metcon::get_by_user(user_id, conn)?,
            metcon_sessions: MetconSession::get_by_user(user_id, conn)?,
            metcon_movements: MetconMovement::get_by_user(user_id, conn)?,
            cardio_sessions: CardioSession::get_by_user(user_id, conn)?,
            routes: Route::get_by_user(user_id, conn)?,
            platforms: Platform::get_all(conn)?,
            platform_credentials: PlatformCredential::get_by_user(user_id, conn)?,
            action_providers: ActionProvider::get_all(conn)?,
            actions: Action::get_all(conn)?,
            action_rules: ActionRule::get_by_user(user_id, conn)?,
            action_event: ActionEvent::get_by_user(user_id, conn)?,
        })
    }
}
