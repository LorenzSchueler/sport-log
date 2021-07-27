use chrono::NaiveDateTime;
use diesel::{PgConnection, QueryResult};

use crate::types::{
    Activity, CardioSessionDescription, Diary, MetconSessionDescription,
    StrengthSessionDescription, UserId, Wod,
};

impl Activity {
    pub fn get_ordered_by_user_and_timespan(
        user_id: UserId,
        start: NaiveDateTime,
        end: NaiveDateTime,
        conn: &PgConnection,
    ) -> QueryResult<Vec<Self>> {
        let mut activities = vec![];

        activities.extend(
            Diary::get_ordered_by_user_and_timespan(user_id, start, end, conn)?
                .into_iter()
                .map(|diary| (diary.date.and_hms(0, 0, 0), Activity::Diary(diary))),
        );

        activities.extend(
            Wod::get_ordered_by_user_and_timespan(user_id, start, end, conn)?
                .into_iter()
                .map(|wod| (wod.date.and_hms(0, 0, 0), Activity::Wod(wod))),
        );

        activities.extend(
            StrengthSessionDescription::get_ordered_by_user_and_timespan(
                user_id, start, end, conn,
            )?
            .into_iter()
            .map(|strength_session_description| {
                (
                    strength_session_description.strength_session.datetime,
                    Activity::StrengthSession(strength_session_description),
                )
            }),
        );

        activities.extend(
            MetconSessionDescription::get_ordered_by_user_and_timespan(user_id, start, end, conn)?
                .into_iter()
                .map(|metcon_session_description| {
                    (
                        metcon_session_description.metcon_session.datetime,
                        Activity::MetconSession(metcon_session_description),
                    )
                }),
        );

        activities.extend(
            CardioSessionDescription::get_ordered_by_user_and_timespan(user_id, start, end, conn)?
                .into_iter()
                .map(|cardio_session_description| {
                    (
                        cardio_session_description.cardio_session.datetime,
                        Activity::CardioSession(cardio_session_description),
                    )
                }),
        );

        activities.sort_by(|a, b| b.0.cmp(&a.0));

        let activities = activities
            .into_iter()
            .map(|(_, activity)| activity)
            .collect();

        Ok(activities)
    }
}
