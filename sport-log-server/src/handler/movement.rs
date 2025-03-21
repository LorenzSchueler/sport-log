use axum::{Json, extract::Query};
use sport_log_types::{EpochResponse, Movement, MovementId};

use crate::{
    auth::*,
    db::*,
    handler::{HandlerResult, IdOption, UnverifiedSingleOrVec},
    state::DbConn,
};

pub async fn create_movements(
    auth: AuthUserOrAP,
    mut db: DbConn,
    Json(movements): Json<UnverifiedSingleOrVec<Movement>>,
) -> HandlerResult<Json<EpochResponse>> {
    match movements {
        UnverifiedSingleOrVec::Single(movement) => {
            let movement = movement.verify_user_ap_create(auth)?;
            MovementDb::create(&movement, &mut db).await?;
        }
        UnverifiedSingleOrVec::Vec(movements) => {
            let movements = movements.verify_user_ap_create(auth)?;
            MovementDb::create_multiple(&movements, &mut db).await?;
        }
    }
    let epoch = MovementDb::get_epoch_by_user_optional(*auth, &mut db).await?;
    Ok(Json(EpochResponse { epoch }))
}

pub async fn get_movements(
    auth: AuthUserOrAP,
    Query(IdOption { id }): Query<IdOption<UnverifiedId<MovementId>>>,
    mut db: DbConn,
) -> HandlerResult<Json<Vec<Movement>>> {
    match id {
        Some(id) => {
            let movement_id = id.verify_user_ap_get(auth, &mut db).await?;
            MovementDb::get_by_id(movement_id, &mut db)
                .await
                .map(|m| vec![m])
        }
        None => MovementDb::get_by_user(*auth, &mut db).await,
    }
    .map(Json)
    .map_err(Into::into)
}

pub async fn update_movements(
    auth: AuthUserOrAP,
    mut db: DbConn,
    Json(movements): Json<UnverifiedSingleOrVec<Movement>>,
) -> HandlerResult<Json<EpochResponse>> {
    match movements {
        UnverifiedSingleOrVec::Single(movement) => {
            let movement = movement.verify_user_ap_update(auth, &mut db).await?;
            MovementDb::update(&movement, &mut db).await?;
        }
        UnverifiedSingleOrVec::Vec(movements) => {
            let movements = movements.verify_user_ap_update(auth, &mut db).await?;
            MovementDb::update_multiple(&movements, &mut db).await?;
        }
    }
    let epoch = MovementDb::get_epoch_by_user_optional(*auth, &mut db).await?;
    Ok(Json(EpochResponse { epoch }))
}
