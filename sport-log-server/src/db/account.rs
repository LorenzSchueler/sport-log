use chrono::{DateTime, Utc};
use diesel::{PgConnection, QueryResult};
use sport_log_types::{AccountData, UserId};

use crate::db::*;

pub struct AccountDataDb;

impl AccountDataDb {
    pub fn get_by_user(user_id: UserId, db: &mut PgConnection) -> QueryResult<AccountData> {
        Ok(AccountData {
            user: Some(UserDb::get_by_id(user_id, db)?),
            diaries: DiaryDb::get_by_user(user_id, db)?,
            wods: WodDb::get_by_user(user_id, db)?,
            movements: MovementDb::get_by_user(user_id, db)?,
            movement_muscles: MovementMuscleDb::get_by_user(user_id, db)?,
            strength_blueprints: StrengthBlueprintDb::get_by_user(user_id, db)?,
            strength_blueprint_sets: StrengthBlueprintSetDb::get_by_user(user_id, db)?,
            strength_sessions: StrengthSessionDb::get_by_user(user_id, db)?,
            strength_sets: StrengthSetDb::get_by_user(user_id, db)?,
            metcons: MetconDb::get_by_user(user_id, db)?,
            metcon_sessions: MetconSessionDb::get_by_user(user_id, db)?,
            metcon_movements: MetconMovementDb::get_by_user(user_id, db)?,
            metcon_items: MetconItemDb::get_by_user(user_id, db)?,
            cardio_blueprints: CardioBlueprintDb::get_by_user(user_id, db)?,
            cardio_sessions: CardioSessionDb::get_by_user(user_id, db)?,
            routes: RouteDb::get_by_user(user_id, db)?,
            training_plans: TrainingPlanDb::get_by_user(user_id, db)?,
            platforms: PlatformDb::get_all(db)?,
            platform_credentials: PlatformCredentialDb::get_by_user(user_id, db)?,
            action_providers: ActionProviderDb::get_all(db)?,
            actions: ActionDb::get_all(db)?,
            action_rules: ActionRuleDb::get_by_user(user_id, db)?,
            action_events: ActionEventDb::get_by_user(user_id, db)?,
        })
    }

    pub fn get_by_user_and_last_sync(
        user_id: UserId,
        last_sync: DateTime<Utc>,
        db: &mut PgConnection,
    ) -> QueryResult<AccountData> {
        Ok(AccountData {
            user: UserDb::get_by_id_and_last_sync(user_id, last_sync, db)?,
            diaries: DiaryDb::get_by_user_and_last_sync(user_id, last_sync, db)?,
            wods: WodDb::get_by_user_and_last_sync(user_id, last_sync, db)?,
            movements: MovementDb::get_by_user_and_last_sync(user_id, last_sync, db)?,
            movement_muscles: MovementMuscleDb::get_by_user_and_last_sync(user_id, last_sync, db)?,
            strength_blueprints: StrengthBlueprintDb::get_by_user_and_last_sync(
                user_id, last_sync, db,
            )?,
            strength_blueprint_sets: StrengthBlueprintSetDb::get_by_user_and_last_sync(
                user_id, last_sync, db,
            )?,
            strength_sessions: StrengthSessionDb::get_by_user_and_last_sync(
                user_id, last_sync, db,
            )?,
            strength_sets: StrengthSetDb::get_by_user_and_last_sync(user_id, last_sync, db)?,
            metcons: MetconDb::get_by_user_and_last_sync(user_id, last_sync, db)?,
            metcon_sessions: MetconSessionDb::get_by_user_and_last_sync(user_id, last_sync, db)?,
            metcon_movements: MetconMovementDb::get_by_user_and_last_sync(user_id, last_sync, db)?,
            metcon_items: MetconItemDb::get_by_user_and_last_sync(user_id, last_sync, db)?,
            cardio_blueprints: CardioBlueprintDb::get_by_user_and_last_sync(
                user_id, last_sync, db,
            )?,
            cardio_sessions: CardioSessionDb::get_by_user_and_last_sync(user_id, last_sync, db)?,
            routes: RouteDb::get_by_user_and_last_sync(user_id, last_sync, db)?,
            training_plans: TrainingPlanDb::get_by_user_and_last_sync(user_id, last_sync, db)?,
            platforms: PlatformDb::get_by_last_sync(last_sync, db)?,
            platform_credentials: PlatformCredentialDb::get_by_user_and_last_sync(
                user_id, last_sync, db,
            )?,
            action_providers: ActionProviderDb::get_by_last_sync(last_sync, db)?,
            actions: ActionDb::get_by_last_sync(last_sync, db)?,
            action_rules: ActionRuleDb::get_by_user_and_last_sync(user_id, last_sync, db)?,
            action_events: ActionEventDb::get_by_user_and_last_sync(user_id, last_sync, db)?,
        })
    }
}
