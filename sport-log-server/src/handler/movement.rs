use axum::{extract::Query, http::StatusCode, Json};
use sport_log_types::{
    AuthUserOrAP, Create, DbConn, Eorm, GetAll, GetById, GetByUser, Movement, MovementId,
    UnverifiedId, Update, VerifyForUserOrAPWithoutDb, VerifyIdForUserOrAP,
    VerifyMultipleForUserOrAPWithDb, VerifyMultipleForUserOrAPWithoutDb,
};

use crate::handler::{HandlerResult, IdOption, UnverifiedSingleOrVec};

pub async fn create_movements(
    auth: AuthUserOrAP,
    mut db: DbConn,
    Json(movements): Json<UnverifiedSingleOrVec<Movement>>,
) -> HandlerResult<StatusCode> {
    match movements {
        UnverifiedSingleOrVec::Single(movement) => {
            let movement = movement.verify_user_ap_without_db(auth)?;
            Movement::create(&movement, &mut db)
        }
        UnverifiedSingleOrVec::Vec(movements) => {
            let movements = movements.verify_user_ap_without_db(auth)?;
            Movement::create_multiple(&movements, &mut db)
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

pub async fn get_movements(
    auth: AuthUserOrAP,
    Query(IdOption { id }): Query<IdOption<UnverifiedId<MovementId>>>,
    mut db: DbConn,
) -> HandlerResult<Json<Vec<Movement>>> {
    match id {
        Some(id) => {
            let movement_id = id.verify_user_ap(auth, &mut db)?;
            Movement::get_by_id(movement_id, &mut db).map(|m| vec![m])
        }
        None => Movement::get_by_user(*auth, &mut db),
    }
    .map(Json)
    .map_err(Into::into)
}

pub async fn update_movements(
    auth: AuthUserOrAP,
    mut db: DbConn,
    Json(movements): Json<UnverifiedSingleOrVec<Movement>>,
) -> HandlerResult<StatusCode> {
    match movements {
        UnverifiedSingleOrVec::Single(movement) => {
            let movement = movement.verify_user_ap_without_db(auth)?;
            Movement::update(&movement, &mut db)
        }
        UnverifiedSingleOrVec::Vec(movements) => {
            let movements = movements.verify_user_ap(auth, &mut db)?;
            Movement::update_multiple(&movements, &mut db)
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

////#[post(
////"/movement_muscle",
////format = "application/json",
////data = "<movement_muscle>"
////)]
//pub async fn create_movement_muscle(
//auth: AuthUserOrAP,
//mut db: DbConn,
//Json(movement_muscle): Json<Unverified<MovementMuscle>>,
//) -> HandlerResult<Json<MovementMuscle>> {
//let movement_muscle = movement_muscle
//.verify_user_ap_create(auth, &mut db)
//.map_err(Error::from)?;
//MovementMuscle::create(&movement_muscle, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

////#[post(
////"/movement_muscles",
////format = "application/json",
////data = "<movement_muscles>"
////)]
//pub async fn create_movement_muscles(
//auth: AuthUserOrAP,
//mut db: DbConn,
//Json(movement_muscles): Json<UnverifiedSingleOrVec<MovementMuscle>>>,
//) -> HandlerResult<Json<Vec<MovementMuscle>>> {
//let movement_muscles = movement_muscles
//.verify_user_ap_create(auth, &mut db)
//.map_err(|status| Error {
//status,
//message: None,
//})?;
//MovementMuscle::create_multiple(&movement_muscles, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

////#[get("/movement_muscle/<movement_muscle_id>")]
//pub async fn get_movement_muscle(
//auth: AuthUserOrAP,
//Path(movement_muscle_id): Path<UnverifiedId<MovementMuscleId>>,
//mut db: DbConn,
//) -> HandlerResult<Json<MovementMuscle>> {
//let movement_muscle_id = movement_muscle_id
//.verify_user_ap(auth, &mut db)
//.map_err(Error::from)?;
//MovementMuscle::get_by_id(movement_muscle_id, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

////#[get("/movement_muscle")]
//pub async fn get_movement_muscles(
//auth: AuthUserOrAP,
//mut db: DbConn,
//) -> HandlerResult<Json<Vec<MovementMuscle>>> {
//MovementMuscle::get_by_user(*auth, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

////#[put(
////"/movement_muscle",
////format = "application/json",
////data = "<movement_muscle>"
////)]
//pub async fn update_movement_muscle(
//auth: AuthUserOrAP,
//mut db: DbConn,
//Json(movement_muscle): Json<Unverified<MovementMuscle>>,
//) -> HandlerResult<Json<MovementMuscle>> {
//let movement_muscle = movement_muscle
//.verify_user_ap(auth, &mut db)
//.map_err(Error::from)?;
//MovementMuscle::update(&movement_muscle, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

////#[put(
////"/movement_muscles",
////format = "application/json",
////data = "<movement_muscles>"
////)]
//pub async fn update_movement_muscles(
//auth: AuthUserOrAP,
//mut db: DbConn,
//Json(movement_muscles): Json<UnverifiedSingleOrVec<MovementMuscle>>>,
//) -> HandlerResult<Json<Vec<MovementMuscle>>> {
//let movement_muscles = movement_muscles
//.verify_user_ap(auth, &mut db)
//.map_err(Error::from)?;
//MovementMuscle::update_multiple(&movement_muscles, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

////#[get("/muscle_group")]
//pub async fn get_muscle_groups(
//_auth: AuthUserOrAP,
//mut db: DbConn,
//) -> HandlerResult<Json<Vec<MuscleGroup>>> {
//MuscleGroup::get_all(&mut db).map(Json).map_err(Into::into)
//}

pub async fn get_eorms(_auth: AuthUserOrAP, mut db: DbConn) -> HandlerResult<Json<Vec<Eorm>>> {
    Eorm::get_all(&mut db).map(Json).map_err(Into::into)
}
