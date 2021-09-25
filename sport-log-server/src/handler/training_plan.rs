use sport_log_types::{
    AuthUserOrAP, Create, CreateMultiple, Db, GetById, GetByUser, TrainingPlan, TrainingPlanId,
    Unverified, UnverifiedId, Update, VerifyForUserOrAPWithDb, VerifyForUserOrAPWithoutDb,
    VerifyIdForUserOrAP, VerifyMultipleForUserOrAPWithDb, VerifyMultipleForUserOrAPWithoutDb,
};

use crate::handler::{IntoJson, JsonError, JsonResult};

#[post(
    "/training_plan",
    format = "application/json",
    data = "<training_plan>"
)]
pub async fn create_training_plan(
    training_plan: Unverified<TrainingPlan>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<TrainingPlan> {
    let training_plan = training_plan
        .verify_user_ap_without_db(&auth)
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| TrainingPlan::create(training_plan, c))
        .await
        .into_json()
}

#[post(
    "/training_plans",
    format = "application/json",
    data = "<training_plans>"
)]
pub async fn create_training_plans(
    training_plans: Unverified<Vec<TrainingPlan>>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Vec<TrainingPlan>> {
    let training_plans = training_plans
        .verify_user_ap_without_db(&auth)
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| TrainingPlan::create_multiple(training_plans, c))
        .await
        .into_json()
}

#[get("/training_plan/<training_plan_id>")]
pub async fn get_training_plan(
    training_plan_id: UnverifiedId<TrainingPlanId>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<TrainingPlan> {
    let training_plan_id = conn
        .run(move |c| training_plan_id.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(move |c| TrainingPlan::get_by_id(training_plan_id, c))
        .await
        .into_json()
}

#[get("/training_plan")]
pub async fn get_training_plans(auth: AuthUserOrAP, conn: Db) -> JsonResult<Vec<TrainingPlan>> {
    conn.run(move |c| TrainingPlan::get_by_user(*auth, c))
        .await
        .into_json()
}

#[put(
    "/training_plan",
    format = "application/json",
    data = "<training_plan>"
)]
pub async fn update_training_plan(
    training_plan: Unverified<TrainingPlan>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<TrainingPlan> {
    let training_plan = conn
        .run(move |c| training_plan.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| TrainingPlan::update(training_plan, c))
        .await
        .into_json()
}

#[put(
    "/training_plans",
    format = "application/json",
    data = "<training_plans>"
)]
pub async fn update_training_plans(
    training_plans: Unverified<Vec<TrainingPlan>>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Vec<TrainingPlan>> {
    let training_plans = conn
        .run(move |c| training_plans.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| TrainingPlan::update_multiple(training_plans, c))
        .await
        .into_json()
}
