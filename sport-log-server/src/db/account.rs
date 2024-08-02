use diesel::QueryResult;
use diesel_async::AsyncPgConnection;
use sport_log_types::{AccountData, EpochMap, UserId};

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
            epoch_map: Self::get_epoch_map_by_user(user_id, db).await?,
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
            epoch_map: Self::get_epoch_map_by_user(user_id, db).await?,
        })
    }

    async fn get_epoch_map_by_user(
        user_id: UserId,
        db: &mut AsyncPgConnection,
    ) -> QueryResult<EpochMap> {
        Ok(EpochMap {
            user: UserDb::get_epoch_by_user(user_id, db).await?,
            diary: DiaryDb::get_epoch_by_user(user_id, db).await?,
            wod: WodDb::get_epoch_by_user(user_id, db).await?,
            movement: MovementDb::get_epoch_by_user_optional(user_id, db).await?,
            strength_session: StrengthSessionDb::get_epoch_by_user(user_id, db).await?,
            strength_set: StrengthSetDb::get_epoch_by_user(user_id, db).await?,
            metcon: MetconDb::get_epoch_by_user_optional(user_id, db).await?,
            metcon_session: MetconSessionDb::get_epoch_by_user(user_id, db).await?,
            metcon_movement: MetconMovementDb::get_epoch_by_user_optional(user_id, db).await?,
            cardio_session: CardioSessionDb::get_epoch_by_user(user_id, db).await?,
            route: RouteDb::get_epoch_by_user(user_id, db).await?,
            platform: PlatformDb::get_epoch(db).await?,
            platform_credential: PlatformCredentialDb::get_epoch_by_user(user_id, db).await?,
            action_provider: ActionProviderDb::get_epoch(db).await?,
            action: ActionDb::get_epoch(db).await?,
            action_rule: ActionRuleDb::get_epoch_by_user(user_id, db).await?,
            action_event: ActionEventDb::get_epoch_by_user(user_id, db).await?,
        })
    }
}
