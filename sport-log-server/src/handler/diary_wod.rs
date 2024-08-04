use axum::{extract::Query, Json};
use sport_log_types::{Diary, DiaryId, EpochResponse, Wod, WodId};

use crate::{
    auth::AuthUserOrAP,
    db::*,
    handler::{HandlerResult, IdOption, UnverifiedSingleOrVec},
    state::DbConn,
};

pub async fn create_wods(
    auth: AuthUserOrAP,
    mut db: DbConn,
    Json(wods): Json<UnverifiedSingleOrVec<Wod>>,
) -> HandlerResult<Json<EpochResponse>> {
    match wods {
        UnverifiedSingleOrVec::Single(wod) => {
            let wod = wod.verify_user_ap_create(auth)?;
            WodDb::create(&wod, &mut db).await?;
        }
        UnverifiedSingleOrVec::Vec(wods) => {
            let wods = wods.verify_user_ap_create(auth)?;
            WodDb::create_multiple(&wods, &mut db).await?;
        }
    }
    let epoch = WodDb::get_epoch_by_user(*auth, &mut db).await?;
    Ok(Json(EpochResponse { epoch }))
}

pub async fn get_wods(
    auth: AuthUserOrAP,
    Query(IdOption { id }): Query<IdOption<UnverifiedId<WodId>>>,
    mut db: DbConn,
) -> HandlerResult<Json<Vec<Wod>>> {
    match id {
        Some(id) => {
            let wod_id = id.verify_user_ap_get(auth, &mut db).await?;
            WodDb::get_by_id(wod_id, &mut db).await.map(|w| vec![w])
        }
        None => WodDb::get_by_user(*auth, &mut db).await,
    }
    .map(Json)
    .map_err(Into::into)
}

pub async fn update_wods(
    auth: AuthUserOrAP,
    mut db: DbConn,
    Json(wods): Json<UnverifiedSingleOrVec<Wod>>,
) -> HandlerResult<Json<EpochResponse>> {
    match wods {
        UnverifiedSingleOrVec::Single(wod) => {
            let wod = wod.verify_user_ap_update(auth, &mut db).await?;
            WodDb::update(&wod, &mut db).await?;
        }
        UnverifiedSingleOrVec::Vec(wods) => {
            let wods = wods.verify_user_ap_update(auth, &mut db).await?;
            WodDb::update_multiple(&wods, &mut db).await?;
        }
    }
    let epoch = WodDb::get_epoch_by_user(*auth, &mut db).await?;
    Ok(Json(EpochResponse { epoch }))
}

pub async fn create_diaries(
    auth: AuthUserOrAP,
    mut db: DbConn,
    Json(diaries): Json<UnverifiedSingleOrVec<Diary>>,
) -> HandlerResult<Json<EpochResponse>> {
    match diaries {
        UnverifiedSingleOrVec::Single(diary) => {
            let diary = diary.verify_user_ap_create(auth)?;
            DiaryDb::create(&diary, &mut db).await?;
        }
        UnverifiedSingleOrVec::Vec(diaries) => {
            let diaries = diaries.verify_user_ap_create(auth)?;
            DiaryDb::create_multiple(&diaries, &mut db).await?;
        }
    }
    let epoch = DiaryDb::get_epoch_by_user(*auth, &mut db).await?;
    Ok(Json(EpochResponse { epoch }))
}

pub async fn get_diaries(
    auth: AuthUserOrAP,
    Query(IdOption { id }): Query<IdOption<UnverifiedId<DiaryId>>>,
    mut db: DbConn,
) -> HandlerResult<Json<Vec<Diary>>> {
    match id {
        Some(id) => {
            let diary_id = id.verify_user_ap_get(auth, &mut db).await?;
            DiaryDb::get_by_id(diary_id, &mut db).await.map(|d| vec![d])
        }
        None => DiaryDb::get_by_user(*auth, &mut db).await,
    }
    .map(Json)
    .map_err(Into::into)
}

pub async fn update_diaries(
    auth: AuthUserOrAP,
    mut db: DbConn,
    Json(diaries): Json<UnverifiedSingleOrVec<Diary>>,
) -> HandlerResult<Json<EpochResponse>> {
    match diaries {
        UnverifiedSingleOrVec::Single(diary) => {
            let diary = diary.verify_user_ap_update(auth, &mut db).await?;
            DiaryDb::update(&diary, &mut db).await?;
        }
        UnverifiedSingleOrVec::Vec(diaries) => {
            let diaries = diaries.verify_user_ap_update(auth, &mut db).await?;
            DiaryDb::update_multiple(&diaries, &mut db).await?;
        }
    }
    let epoch = DiaryDb::get_epoch_by_user(*auth, &mut db).await?;
    Ok(Json(EpochResponse { epoch }))
}
