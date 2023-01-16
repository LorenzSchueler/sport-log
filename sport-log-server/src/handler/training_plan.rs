use axum::{extract::Query, http::StatusCode, Json};
use sport_log_types::{
    AuthUserOrAP, Create, DbConn, GetById, GetByUser, TrainingPlan, TrainingPlanId, UnverifiedId,
    Update, VerifyForUserOrAPWithDb, VerifyForUserOrAPWithoutDb, VerifyIdForUserOrAP,
    VerifyMultipleForUserOrAPWithDb, VerifyMultipleForUserOrAPWithoutDb,
};

use crate::handler::{HandlerResult, IdOption, UnverifiedSingleOrVec};

pub async fn create_training_plans(
    auth: AuthUserOrAP,
    mut db: DbConn,
    Json(training_plans): Json<UnverifiedSingleOrVec<TrainingPlan>>,
) -> HandlerResult<StatusCode> {
    match training_plans {
        UnverifiedSingleOrVec::Single(training_plan) => {
            let training_plan = training_plan.verify_user_ap_without_db(auth)?;
            TrainingPlan::create(&training_plan, &mut db)
        }
        UnverifiedSingleOrVec::Vec(training_plans) => {
            let training_plans = training_plans.verify_user_ap_without_db(auth)?;
            TrainingPlan::create_multiple(&training_plans, &mut db)
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

pub async fn get_training_plans(
    auth: AuthUserOrAP,
    Query(IdOption { id }): Query<IdOption<UnverifiedId<TrainingPlanId>>>,
    mut db: DbConn,
) -> HandlerResult<Json<Vec<TrainingPlan>>> {
    match id {
        Some(id) => {
            let training_plan_id = id.verify_user_ap(auth, &mut db)?;
            TrainingPlan::get_by_id(training_plan_id, &mut db).map(|t| vec![t])
        }
        None => TrainingPlan::get_by_user(*auth, &mut db),
    }
    .map(Json)
    .map_err(Into::into)
}

pub async fn update_training_plans(
    auth: AuthUserOrAP,
    mut db: DbConn,
    Json(training_plans): Json<UnverifiedSingleOrVec<TrainingPlan>>,
) -> HandlerResult<StatusCode> {
    match training_plans {
        UnverifiedSingleOrVec::Single(training_plan) => {
            let training_plan = training_plan.verify_user_ap(auth, &mut db)?;
            TrainingPlan::update(&training_plan, &mut db)
        }
        UnverifiedSingleOrVec::Vec(training_plans) => {
            let training_plans = training_plans.verify_user_ap(auth, &mut db)?;
            TrainingPlan::update_multiple(&training_plans, &mut db)
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}
