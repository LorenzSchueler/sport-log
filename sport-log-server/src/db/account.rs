use diesel::QueryResult;
use diesel_async::AsyncPgConnection;
use sport_log_types::{AccountData, UserId};

use crate::db::*;

pub struct AccountDataDb;

impl AccountDataDb {
    pub async fn get_by_user(
        user_id: UserId,
        db: &mut AsyncPgConnection,
    ) -> QueryResult<AccountData> {
        Ok(AccountData {
            user: Some(UserDb::get_by_id(user_id, db).await?),
            diaries: DiaryDb::get_by_user(user_id, db).await?,
            wods: WodDb::get_by_user(user_id, db).await?,
            movements: MovementDb::get_by_user(user_id, db).await?,
            strength_sessions: StrengthSessionDb::get_by_user(user_id, db).await?,
            strength_sets: StrengthSetDb::get_by_user(user_id, db).await?,
            metcons: MetconDb::get_by_user(user_id, db).await?,
            metcon_sessions: MetconSessionDb::get_by_user(user_id, db).await?,
            metcon_movements: MetconMovementDb::get_by_user(user_id, db).await?,
            cardio_sessions: CardioSessionDb::get_by_user(user_id, db).await?,
            routes: RouteDb::get_by_user(user_id, db).await?,
            platforms: PlatformDb::get_all(db).await?,
            platform_credentials: PlatformCredentialDb::get_by_user(user_id, db).await?,
            action_providers: ActionProviderDb::get_all(db).await?,
            actions: ActionDb::get_all(db).await?,
            action_rules: ActionRuleDb::get_by_user(user_id, db).await?,
            action_events: ActionEventDb::get_by_user(user_id, db).await?,
        })
    }

    pub async fn get_by_user_and_epoch(
        user_id: UserId,
        epoch: i64,
        db: &mut AsyncPgConnection,
    ) -> QueryResult<AccountData> {
        Ok(AccountData {
            user: UserDb::get_by_id_and_epoch(user_id, epoch, db).await?,
            diaries: DiaryDb::get_by_user_and_epoch(user_id, epoch, db).await?,
            wods: WodDb::get_by_user_and_epoch(user_id, epoch, db).await?,
            movements: MovementDb::get_by_user_and_epoch(user_id, epoch, db).await?,
            strength_sessions: StrengthSessionDb::get_by_user_and_epoch(user_id, epoch, db).await?,
            strength_sets: StrengthSetDb::get_by_user_and_epoch(user_id, epoch, db).await?,
            metcons: MetconDb::get_by_user_and_epoch(user_id, epoch, db).await?,
            metcon_sessions: MetconSessionDb::get_by_user_and_epoch(user_id, epoch, db).await?,
            metcon_movements: MetconMovementDb::get_by_user_and_epoch(user_id, epoch, db).await?,
            cardio_sessions: CardioSessionDb::get_by_user_and_epoch(user_id, epoch, db).await?,
            routes: RouteDb::get_by_user_and_epoch(user_id, epoch, db).await?,
            platforms: PlatformDb::get_by_epoch(epoch, db).await?,
            platform_credentials: PlatformCredentialDb::get_by_user_and_epoch(user_id, epoch, db)
                .await?,
            action_providers: ActionProviderDb::get_by_epoch(epoch, db).await?,
            actions: ActionDb::get_by_epoch(epoch, db).await?,
            action_rules: ActionRuleDb::get_by_user_and_epoch(user_id, epoch, db).await?,
            action_events: ActionEventDb::get_by_user_and_epoch(user_id, epoch, db).await?,
        })
    }
}
