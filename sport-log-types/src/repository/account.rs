use chrono::{DateTime, Utc};
use diesel::{PgConnection, QueryResult};

use crate::{
    AccountData, Action, ActionEvent, ActionProvider, ActionRule, CardioBlueprint, CardioSession,
    Diary, GetAll, GetById, GetBySync, GetByUser, GetByUserSync, Metcon, MetconItem,
    MetconMovement, MetconSession, Movement, MovementMuscle, Platform, PlatformCredential, Route,
    StrengthBlueprint, StrengthBlueprintSet, StrengthSession, StrengthSet, TrainingPlan, User,
    UserId, Wod,
};

impl AccountData {
    pub fn get_by_user(user_id: UserId, db: &PgConnection) -> QueryResult<Self> {
        Ok(AccountData {
            user: Some(User::get_by_id(user_id, db)?),
            diaries: Diary::get_by_user(user_id, db)?,
            wods: Wod::get_by_user(user_id, db)?,
            movements: Movement::get_by_user(user_id, db)?,
            movement_muscles: MovementMuscle::get_by_user(user_id, db)?,
            strength_blueprints: StrengthBlueprint::get_by_user(user_id, db)?,
            strength_blueprint_sets: StrengthBlueprintSet::get_by_user(user_id, db)?,
            strength_sessions: StrengthSession::get_by_user(user_id, db)?,
            strength_sets: StrengthSet::get_by_user(user_id, db)?,
            metcons: Metcon::get_by_user(user_id, db)?,
            metcon_sessions: MetconSession::get_by_user(user_id, db)?,
            metcon_movements: MetconMovement::get_by_user(user_id, db)?,
            metcon_items: MetconItem::get_by_user(user_id, db)?,
            cardio_blueprints: CardioBlueprint::get_by_user(user_id, db)?,
            cardio_sessions: CardioSession::get_by_user(user_id, db)?,
            routes: Route::get_by_user(user_id, db)?,
            training_plans: TrainingPlan::get_by_user(user_id, db)?,
            platforms: Platform::get_all(db)?,
            platform_credentials: PlatformCredential::get_by_user(user_id, db)?,
            action_providers: ActionProvider::get_all(db)?,
            actions: Action::get_all(db)?,
            action_rules: ActionRule::get_by_user(user_id, db)?,
            action_events: ActionEvent::get_by_user(user_id, db)?,
        })
    }

    pub fn get_by_user_and_last_sync(
        user_id: UserId,
        last_sync: DateTime<Utc>,
        db: &PgConnection,
    ) -> QueryResult<Self> {
        Ok(AccountData {
            user: User::get_by_id_and_last_sync(user_id, last_sync, db)?,
            diaries: Diary::get_by_user_and_last_sync(user_id, last_sync, db)?,
            wods: Wod::get_by_user_and_last_sync(user_id, last_sync, db)?,
            movements: Movement::get_by_user_and_last_sync(user_id, last_sync, db)?,
            movement_muscles: MovementMuscle::get_by_user_and_last_sync(user_id, last_sync, db)?,
            strength_blueprints: StrengthBlueprint::get_by_user_and_last_sync(
                user_id, last_sync, db,
            )?,
            strength_blueprint_sets: StrengthBlueprintSet::get_by_user_and_last_sync(
                user_id, last_sync, db,
            )?,
            strength_sessions: StrengthSession::get_by_user_and_last_sync(user_id, last_sync, db)?,
            strength_sets: StrengthSet::get_by_user_and_last_sync(user_id, last_sync, db)?,
            metcons: Metcon::get_by_user_and_last_sync(user_id, last_sync, db)?,
            metcon_sessions: MetconSession::get_by_user_and_last_sync(user_id, last_sync, db)?,
            metcon_movements: MetconMovement::get_by_user_and_last_sync(user_id, last_sync, db)?,
            metcon_items: MetconItem::get_by_user_and_last_sync(user_id, last_sync, db)?,
            cardio_blueprints: CardioBlueprint::get_by_user_and_last_sync(user_id, last_sync, db)?,
            cardio_sessions: CardioSession::get_by_user_and_last_sync(user_id, last_sync, db)?,
            routes: Route::get_by_user_and_last_sync(user_id, last_sync, db)?,
            training_plans: TrainingPlan::get_by_user_and_last_sync(user_id, last_sync, db)?,
            platforms: Platform::get_by_last_sync(last_sync, db)?,
            platform_credentials: PlatformCredential::get_by_user_and_last_sync(
                user_id, last_sync, db,
            )?,
            action_providers: ActionProvider::get_by_last_sync(last_sync, db)?,
            actions: Action::get_by_last_sync(last_sync, db)?,
            action_rules: ActionRule::get_by_user_and_last_sync(user_id, last_sync, db)?,
            action_events: ActionEvent::get_by_user_and_last_sync(user_id, last_sync, db)?,
        })
    }
}
