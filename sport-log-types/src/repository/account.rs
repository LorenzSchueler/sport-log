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
    pub fn get_by_user(user_id: UserId, conn: &PgConnection) -> QueryResult<Self> {
        Ok(AccountData {
            user: Some(User::get_by_id(user_id, conn)?),
            diaries: Diary::get_by_user(user_id, conn)?,
            wods: Wod::get_by_user(user_id, conn)?,
            movements: Movement::get_by_user(user_id, conn)?,
            movement_muscles: MovementMuscle::get_by_user(user_id, conn)?,
            strength_blueprints: StrengthBlueprint::get_by_user(user_id, conn)?,
            strength_blueprint_sets: StrengthBlueprintSet::get_by_user(user_id, conn)?,
            strength_sessions: StrengthSession::get_by_user(user_id, conn)?,
            strength_sets: StrengthSet::get_by_user(user_id, conn)?,
            metcons: Metcon::get_by_user(user_id, conn)?,
            metcon_sessions: MetconSession::get_by_user(user_id, conn)?,
            metcon_movements: MetconMovement::get_by_user(user_id, conn)?,
            metcon_items: MetconItem::get_by_user(user_id, conn)?,
            cardio_blueprints: CardioBlueprint::get_by_user(user_id, conn)?,
            cardio_sessions: CardioSession::get_by_user(user_id, conn)?,
            routes: Route::get_by_user(user_id, conn)?,
            training_plans: TrainingPlan::get_by_user(user_id, conn)?,
            platforms: Platform::get_all(conn)?,
            platform_credentials: PlatformCredential::get_by_user(user_id, conn)?,
            action_providers: ActionProvider::get_all(conn)?,
            actions: Action::get_all(conn)?,
            action_rules: ActionRule::get_by_user(user_id, conn)?,
            action_events: ActionEvent::get_by_user(user_id, conn)?,
        })
    }

    pub fn get_by_user_and_last_sync(
        user_id: UserId,
        last_sync: DateTime<Utc>,
        conn: &PgConnection,
    ) -> QueryResult<Self> {
        Ok(AccountData {
            user: User::get_by_id_and_last_sync(user_id, last_sync, conn)?,
            diaries: Diary::get_by_user_and_last_sync(user_id, last_sync, conn)?,
            wods: Wod::get_by_user_and_last_sync(user_id, last_sync, conn)?,
            movements: Movement::get_by_user_and_last_sync(user_id, last_sync, conn)?,
            movement_muscles: MovementMuscle::get_by_user_and_last_sync(user_id, last_sync, conn)?,
            strength_blueprints: StrengthBlueprint::get_by_user_and_last_sync(
                user_id, last_sync, conn,
            )?,
            strength_blueprint_sets: StrengthBlueprintSet::get_by_user_and_last_sync(
                user_id, last_sync, conn,
            )?,
            strength_sessions: StrengthSession::get_by_user_and_last_sync(
                user_id, last_sync, conn,
            )?,
            strength_sets: StrengthSet::get_by_user_and_last_sync(user_id, last_sync, conn)?,
            metcons: Metcon::get_by_user_and_last_sync(user_id, last_sync, conn)?,
            metcon_sessions: MetconSession::get_by_user_and_last_sync(user_id, last_sync, conn)?,
            metcon_movements: MetconMovement::get_by_user_and_last_sync(user_id, last_sync, conn)?,
            metcon_items: MetconItem::get_by_user_and_last_sync(user_id, last_sync, conn)?,
            cardio_blueprints: CardioBlueprint::get_by_user_and_last_sync(
                user_id, last_sync, conn,
            )?,
            cardio_sessions: CardioSession::get_by_user_and_last_sync(user_id, last_sync, conn)?,
            routes: Route::get_by_user_and_last_sync(user_id, last_sync, conn)?,
            training_plans: TrainingPlan::get_by_user_and_last_sync(user_id, last_sync, conn)?,
            platforms: Platform::get_by_last_sync(last_sync, conn)?,
            platform_credentials: PlatformCredential::get_by_user_and_last_sync(
                user_id, last_sync, conn,
            )?,
            action_providers: ActionProvider::get_by_last_sync(last_sync, conn)?,
            actions: Action::get_by_last_sync(last_sync, conn)?,
            action_rules: ActionRule::get_by_user_and_last_sync(user_id, last_sync, conn)?,
            action_events: ActionEvent::get_by_user_and_last_sync(user_id, last_sync, conn)?,
        })
    }
}
