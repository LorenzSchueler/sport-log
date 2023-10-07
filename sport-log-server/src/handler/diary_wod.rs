use axum::{extract::Query, http::StatusCode, Json};
use sport_log_types::{Diary, DiaryId, Wod, WodId};

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
) -> HandlerResult<StatusCode> {
    match wods {
        UnverifiedSingleOrVec::Single(wod) => {
            let wod = wod.verify_user_ap_without_db(auth)?;
            WodDb::create(&wod, &mut db).await
        }
        UnverifiedSingleOrVec::Vec(wods) => {
            let wods = wods.verify_user_ap_without_db(auth)?;
            WodDb::create_multiple(&wods, &mut db).await
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

//pub async fn get_ordered_wods_by_timespan(
//auth: AuthUserOrAP,
//Path(start_datetime): Path<DateTime<Utc>>,
//Path(end_datetime): Path<DateTime<Utc>>,
//mut db: DbConn,
//) -> HandlerResult<Json<Vec<Wod>>> {
//WodDb::get_ordered_by_user_and_timespan(*auth, start_datetime, end_datetime, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

pub async fn get_wods(
    auth: AuthUserOrAP,
    Query(IdOption { id }): Query<IdOption<UnverifiedId<WodId>>>,
    mut db: DbConn,
) -> HandlerResult<Json<Vec<Wod>>> {
    match id {
        Some(id) => {
            let wod_id = id.verify_user_ap(auth, &mut db).await?;
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
) -> HandlerResult<StatusCode> {
    match wods {
        UnverifiedSingleOrVec::Single(wod) => {
            let wod = wod.verify_user_ap(auth, &mut db).await?;
            WodDb::update(&wod, &mut db).await
        }
        UnverifiedSingleOrVec::Vec(wods) => {
            let wods = wods.verify_user_ap(auth, &mut db).await?;
            WodDb::update_multiple(&wods, &mut db).await
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

pub async fn create_diaries(
    auth: AuthUserOrAP,
    mut db: DbConn,
    Json(diaries): Json<UnverifiedSingleOrVec<Diary>>,
) -> HandlerResult<StatusCode> {
    match diaries {
        UnverifiedSingleOrVec::Single(diary) => {
            let diary = diary.verify_user_ap_without_db(auth)?;
            DiaryDb::create(&diary, &mut db).await
        }
        UnverifiedSingleOrVec::Vec(diaries) => {
            let diaries = diaries.verify_user_ap_without_db(auth)?;
            DiaryDb::create_multiple(&diaries, &mut db).await
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

pub async fn get_diaries(
    auth: AuthUserOrAP,
    Query(IdOption { id }): Query<IdOption<UnverifiedId<DiaryId>>>,
    mut db: DbConn,
) -> HandlerResult<Json<Vec<Diary>>> {
    match id {
        Some(id) => {
            let diary_id = id.verify_user_ap(auth, &mut db).await?;
            DiaryDb::get_by_id(diary_id, &mut db).await.map(|d| vec![d])
        }
        None => DiaryDb::get_by_user(*auth, &mut db).await,
    }
    .map(Json)
    .map_err(Into::into)
}

//pub async fn get_ordered_diarys_by_timespan(
//auth: AuthUserOrAP,
//Path(start_datetime): Path<DateTime<Utc>>,
//Path(end_datetime): Path<DateTime<Utc>>,
//mut db: DbConn,
//) -> HandlerResult<Json<Vec<Diary>>> {
//DiaryDb::get_ordered_by_user_and_timespan(*auth, start_datetime, end_datetime, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

pub async fn update_diaries(
    auth: AuthUserOrAP,
    mut db: DbConn,
    Json(diaries): Json<UnverifiedSingleOrVec<Diary>>,
) -> HandlerResult<StatusCode> {
    match diaries {
        UnverifiedSingleOrVec::Single(diary) => {
            let diary = diary.verify_user_ap(auth, &mut db).await?;
            DiaryDb::update(&diary, &mut db).await
        }
        UnverifiedSingleOrVec::Vec(diaries) => {
            let diaries = diaries.verify_user_ap(auth, &mut db).await?;
            DiaryDb::update_multiple(&diaries, &mut db).await
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}
