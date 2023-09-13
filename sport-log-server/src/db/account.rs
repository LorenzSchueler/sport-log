use chrono::{DateTime, Utc};
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
            movement_muscles: MovementMuscleDb::get_by_user(user_id, db).await?,
            strength_blueprints: StrengthBlueprintDb::get_by_user(user_id, db).await?,
            strength_blueprint_sets: StrengthBlueprintSetDb::get_by_user(user_id, db).await?,
            strength_sessions: StrengthSessionDb::get_by_user(user_id, db).await?,
            strength_sets: StrengthSetDb::get_by_user(user_id, db).await?,
            metcons: MetconDb::get_by_user(user_id, db).await?,
            metcon_sessions: MetconSessionDb::get_by_user(user_id, db).await?,
            metcon_movements: MetconMovementDb::get_by_user(user_id, db).await?,
            metcon_items: MetconItemDb::get_by_user(user_id, db).await?,
            cardio_blueprints: CardioBlueprintDb::get_by_user(user_id, db).await?,
            cardio_sessions: CardioSessionDb::get_by_user(user_id, db).await?,
            routes: RouteDb::get_by_user(user_id, db).await?,
            training_plans: TrainingPlanDb::get_by_user(user_id, db).await?,
            platforms: PlatformDb::get_all(db).await?,
            platform_credentials: PlatformCredentialDb::get_by_user(user_id, db).await?,
            action_providers: ActionProviderDb::get_all(db).await?,
            actions: ActionDb::get_all(db).await?,
            action_rules: ActionRuleDb::get_by_user(user_id, db).await?,
            action_events: ActionEventDb::get_by_user(user_id, db).await?,
        })
    }

    pub async fn get_by_user_and_last_sync(
        user_id: UserId,
        last_sync: DateTime<Utc>,
        db: &mut AsyncPgConnection,
    ) -> QueryResult<AccountData> {
        Ok(AccountData {
            user: UserDb::get_by_id_and_last_sync(user_id, last_sync, db).await?,
            diaries: DiaryDb::get_by_user_and_last_sync(user_id, last_sync, db).await?,
            wods: WodDb::get_by_user_and_last_sync(user_id, last_sync, db).await?,
            movements: MovementDb::get_by_user_and_last_sync(user_id, last_sync, db).await?,
            movement_muscles: MovementMuscleDb::get_by_user_and_last_sync(user_id, last_sync, db)
                .await?,
            strength_blueprints: StrengthBlueprintDb::get_by_user_and_last_sync(
                user_id, last_sync, db,
            )
            .await?,
            strength_blueprint_sets: StrengthBlueprintSetDb::get_by_user_and_last_sync(
                user_id, last_sync, db,
            )
            .await?,
            strength_sessions: StrengthSessionDb::get_by_user_and_last_sync(user_id, last_sync, db)
                .await?,
            strength_sets: StrengthSetDb::get_by_user_and_last_sync(user_id, last_sync, db).await?,
            metcons: MetconDb::get_by_user_and_last_sync(user_id, last_sync, db).await?,
            metcon_sessions: MetconSessionDb::get_by_user_and_last_sync(user_id, last_sync, db)
                .await?,
            metcon_movements: MetconMovementDb::get_by_user_and_last_sync(user_id, last_sync, db)
                .await?,
            metcon_items: MetconItemDb::get_by_user_and_last_sync(user_id, last_sync, db).await?,
            cardio_blueprints: CardioBlueprintDb::get_by_user_and_last_sync(user_id, last_sync, db)
                .await?,
            cardio_sessions: CardioSessionDb::get_by_user_and_last_sync(user_id, last_sync, db)
                .await?,
            routes: RouteDb::get_by_user_and_last_sync(user_id, last_sync, db).await?,
            training_plans: TrainingPlanDb::get_by_user_and_last_sync(user_id, last_sync, db)
                .await?,
            platforms: PlatformDb::get_by_last_sync(last_sync, db).await?,
            platform_credentials: PlatformCredentialDb::get_by_user_and_last_sync(
                user_id, last_sync, db,
            )
            .await?,
            action_providers: ActionProviderDb::get_by_last_sync(last_sync, db).await?,
            actions: ActionDb::get_by_last_sync(last_sync, db).await?,
            action_rules: ActionRuleDb::get_by_user_and_last_sync(user_id, last_sync, db).await?,
            action_events: ActionEventDb::get_by_user_and_last_sync(user_id, last_sync, db).await?,
        })
    }
}
