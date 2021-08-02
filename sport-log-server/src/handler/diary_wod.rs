use rocket::{http::Status, serde::json::Json};

use sport_log_types::{
    AuthenticatedUser, Create, CreateMultiple, Db, Delete, DeleteMultiple, Diary, DiaryId, GetById,
    GetByUser, NewDiary, NewWod, Unverified, UnverifiedId, UnverifiedIds, Update,
    VerifyForUserWithDb, VerifyForUserWithoutDb, VerifyIdForUser, VerifyMultipleForUserWithoutDb,
    VerifyMultipleIdForUser, Wod, WodId,
};

use crate::handler::{IntoJson, NaiveDateTimeWrapper};

#[post("/wod", format = "application/json", data = "<wod>")]
pub async fn create_wod(
    wod: Unverified<NewWod>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Wod>, Status> {
    let wod = wod.verify(&auth)?;
    conn.run(|c| Wod::create(wod, c)).await.into_json()
}

#[post("/wods", format = "application/json", data = "<wods>")]
pub async fn create_wods(
    wods: Unverified<Vec<NewWod>>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Vec<Wod>>, Status> {
    let wods = wods.verify(&auth)?;
    conn.run(|c| Wod::create_multiple(wods, c))
        .await
        .into_json()
}

#[get("/wod/timespan/<start_datetime>/<end_datetime>")]
pub async fn get_ordered_wods_by_timespan(
    start_datetime: NaiveDateTimeWrapper,
    end_datetime: NaiveDateTimeWrapper,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Vec<Wod>>, Status> {
    conn.run(move |c| {
        Wod::get_ordered_by_user_and_timespan(*auth, *start_datetime, *end_datetime, c)
    })
    .await
    .into_json()
}

#[get("/wod")]
pub async fn get_wods(auth: AuthenticatedUser, conn: Db) -> Result<Json<Vec<Wod>>, Status> {
    conn.run(move |c| Wod::get_by_user(*auth, c))
        .await
        .into_json()
}

#[put("/wod", format = "application/json", data = "<wod>")]
pub async fn update_wod(
    wod: Unverified<Wod>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Wod>, Status> {
    let wod = conn.run(move |c| wod.verify(&auth, c)).await?;
    conn.run(|c| Wod::update(wod, c)).await.into_json()
}

#[delete("/wod/<wod_id>")]
pub async fn delete_wod(
    wod_id: UnverifiedId<WodId>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Status, Status> {
    conn.run(move |c| {
        Wod::delete(wod_id.verify(&auth, c)?, c)
            .map(|_| Status::NoContent)
            .map_err(|_| Status::InternalServerError)
    })
    .await
}

#[delete("/wods", format = "application/json", data = "<wod_ids>")]
pub async fn delete_wods(
    wod_ids: UnverifiedIds<WodId>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Status, Status> {
    conn.run(move |c| {
        Wod::delete_multiple(wod_ids.verify(&auth, c)?, c)
            .map(|_| Status::NoContent)
            .map_err(|_| Status::InternalServerError)
    })
    .await
}

#[post("/diary", format = "application/json", data = "<diary>")]
pub async fn create_diary(
    diary: Unverified<NewDiary>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Diary>, Status> {
    let diary = diary.verify(&auth)?;
    conn.run(|c| Diary::create(diary, c)).await.into_json()
}

#[post("/diaries", format = "application/json", data = "<diaries>")]
pub async fn create_diaries(
    diaries: Unverified<Vec<NewDiary>>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Vec<Diary>>, Status> {
    let diaries = diaries.verify(&auth)?;
    conn.run(|c| Diary::create_multiple(diaries, c))
        .await
        .into_json()
}

#[get("/diary/<diary_id>")]
pub async fn get_diary(
    diary_id: UnverifiedId<DiaryId>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Diary>, Status> {
    let diary_id = conn.run(move |c| diary_id.verify(&auth, c)).await?;
    conn.run(move |c| Diary::get_by_id(diary_id, c))
        .await
        .into_json()
}

#[get("/diary/timespan/<start_datetime>/<end_datetime>")]
pub async fn get_ordered_diarys_by_timespan(
    start_datetime: NaiveDateTimeWrapper,
    end_datetime: NaiveDateTimeWrapper,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Vec<Diary>>, Status> {
    conn.run(move |c| {
        Diary::get_ordered_by_user_and_timespan(*auth, *start_datetime, *end_datetime, c)
    })
    .await
    .into_json()
}

#[get("/diary")]
pub async fn get_diarys(auth: AuthenticatedUser, conn: Db) -> Result<Json<Vec<Diary>>, Status> {
    conn.run(move |c| Diary::get_by_user(*auth, c))
        .await
        .into_json()
}

#[put("/diary", format = "application/json", data = "<diary>")]
pub async fn update_diary(
    diary: Unverified<Diary>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Json<Diary>, Status> {
    let diary = conn.run(move |c| diary.verify(&auth, c)).await?;
    conn.run(|c| Diary::update(diary, c)).await.into_json()
}

#[delete("/diary/<diary_id>")]
pub async fn delete_diary(
    diary_id: UnverifiedId<DiaryId>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Status, Status> {
    conn.run(move |c| {
        Diary::delete(diary_id.verify(&auth, c)?, c)
            .map(|_| Status::NoContent)
            .map_err(|_| Status::InternalServerError)
    })
    .await
}

#[delete("/diaries", format = "application/json", data = "<diary_ids>")]
pub async fn delete_diaries(
    diary_ids: UnverifiedIds<DiaryId>,
    auth: AuthenticatedUser,
    conn: Db,
) -> Result<Status, Status> {
    conn.run(move |c| {
        Diary::delete_multiple(diary_ids.verify(&auth, c)?, c)
            .map(|_| Status::NoContent)
            .map_err(|_| Status::InternalServerError)
    })
    .await
}
