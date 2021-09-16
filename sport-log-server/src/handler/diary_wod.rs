use sport_log_types::{
    AuthUserOrAP, Create, CreateMultiple, Db, Diary, DiaryId, GetById, GetByUser, Unverified,
    UnverifiedId, Update, VerifyForUserOrAPWithDb, VerifyForUserOrAPWithoutDb, VerifyIdForUserOrAP,
    VerifyMultipleForUserOrAPWithDb, VerifyMultipleForUserOrAPWithoutDb, Wod,
};

use crate::handler::{DateTimeWrapper, IntoJson, JsonError, JsonResult};

#[post("/wod", format = "application/json", data = "<wod>")]
pub async fn create_wod(wod: Unverified<Wod>, auth: AuthUserOrAP, conn: Db) -> JsonResult<Wod> {
    let wod = wod
        .verify_user_ap_without_db(&auth)
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| Wod::create(wod, c)).await.into_json()
}

#[post("/wods", format = "application/json", data = "<wods>")]
pub async fn create_wods(
    wods: Unverified<Vec<Wod>>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Vec<Wod>> {
    let wods = wods
        .verify_user_ap_without_db(&auth)
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| Wod::create_multiple(wods, c))
        .await
        .into_json()
}

#[get("/wod/timespan/<start_datetime>/<end_datetime>")]
pub async fn get_ordered_wods_by_timespan(
    start_datetime: DateTimeWrapper,
    end_datetime: DateTimeWrapper,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Vec<Wod>> {
    conn.run(move |c| {
        Wod::get_ordered_by_user_and_timespan(*auth, *start_datetime, *end_datetime, c)
    })
    .await
    .into_json()
}

#[get("/wod")]
pub async fn get_wods(auth: AuthUserOrAP, conn: Db) -> JsonResult<Vec<Wod>> {
    conn.run(move |c| Wod::get_by_user(*auth, c))
        .await
        .into_json()
}

#[put("/wod", format = "application/json", data = "<wod>")]
pub async fn update_wod(wod: Unverified<Wod>, auth: AuthUserOrAP, conn: Db) -> JsonResult<Wod> {
    let wod = conn
        .run(move |c| wod.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| Wod::update(wod, c)).await.into_json()
}

#[put("/wods", format = "application/json", data = "<wods>")]
pub async fn update_wods(
    wods: Unverified<Vec<Wod>>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Vec<Wod>> {
    let wods = conn
        .run(move |c| wods.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| Wod::update_multiple(wods, c))
        .await
        .into_json()
}

#[post("/diary", format = "application/json", data = "<diary>")]
pub async fn create_diary(
    diary: Unverified<Diary>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Diary> {
    let diary = diary
        .verify_user_ap_without_db(&auth)
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| Diary::create(diary, c)).await.into_json()
}

#[post("/diaries", format = "application/json", data = "<diaries>")]
pub async fn create_diaries(
    diaries: Unverified<Vec<Diary>>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Vec<Diary>> {
    let diaries = diaries
        .verify_user_ap_without_db(&auth)
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| Diary::create_multiple(diaries, c))
        .await
        .into_json()
}

#[get("/diary/<diary_id>")]
pub async fn get_diary(
    diary_id: UnverifiedId<DiaryId>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Diary> {
    let diary_id = conn
        .run(move |c| diary_id.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(move |c| Diary::get_by_id(diary_id, c))
        .await
        .into_json()
}

#[get("/diary/timespan/<start_datetime>/<end_datetime>")]
pub async fn get_ordered_diarys_by_timespan(
    start_datetime: DateTimeWrapper,
    end_datetime: DateTimeWrapper,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Vec<Diary>> {
    conn.run(move |c| {
        Diary::get_ordered_by_user_and_timespan(*auth, *start_datetime, *end_datetime, c)
    })
    .await
    .into_json()
}

#[get("/diary")]
pub async fn get_diarys(auth: AuthUserOrAP, conn: Db) -> JsonResult<Vec<Diary>> {
    conn.run(move |c| Diary::get_by_user(*auth, c))
        .await
        .into_json()
}

#[put("/diary", format = "application/json", data = "<diary>")]
pub async fn update_diary(
    diary: Unverified<Diary>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Diary> {
    let diary = conn
        .run(move |c| diary.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| Diary::update(diary, c)).await.into_json()
}

#[put("/diaries", format = "application/json", data = "<diaries>")]
pub async fn update_diaries(
    diaries: Unverified<Vec<Diary>>,
    auth: AuthUserOrAP,
    conn: Db,
) -> JsonResult<Vec<Diary>> {
    let diaries = conn
        .run(move |c| diaries.verify_user_ap(&auth, c))
        .await
        .map_err(|status| JsonError {
            status,
            message: None,
        })?;
    conn.run(|c| Diary::update_multiple(diaries, c))
        .await
        .into_json()
}
