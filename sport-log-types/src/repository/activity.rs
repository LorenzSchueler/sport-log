use chrono::NaiveDateTime;
use diesel::{PgConnection, QueryResult};

use crate::types::{
    Activity, CardioSessionDescription, Diary, GetByUser, MetconSessionDescription,
    StrengthSessionDescription, UserId, Wod,
};

impl Activity {
    fn join_and_order(
        diarys: Vec<Diary>,
        wods: Vec<Wod>,
        strength_session_descriptions: Vec<StrengthSessionDescription>,
        metcon_session_descriptions: Vec<MetconSessionDescription>,
        cardio_session_descriptions: Vec<CardioSessionDescription>,
    ) -> Vec<Self> {
        let mut activities = vec![];

        activities.extend(
            diarys
                .into_iter()
                .map(|diary| (diary.date.and_hms(0, 0, 0), Activity::Diary(diary))),
        );

        activities.extend(
            wods.into_iter()
                .map(|wod| (wod.date.and_hms(0, 0, 0), Activity::Wod(wod))),
        );

        activities.extend(strength_session_descriptions.into_iter().map(
            |strength_session_description| {
                (
                    strength_session_description.strength_session.datetime,
                    Activity::StrengthSession(strength_session_description),
                )
            },
        ));

        activities.extend(metcon_session_descriptions.into_iter().map(
            |metcon_session_description| {
                (
                    metcon_session_description.metcon_session.datetime,
                    Activity::MetconSession(metcon_session_description),
                )
            },
        ));

        activities.extend(cardio_session_descriptions.into_iter().map(
            |cardio_session_description| {
                (
                    cardio_session_description.cardio_session.datetime,
                    Activity::CardioSession(cardio_session_description),
                )
            },
        ));

        activities.sort_by(|a, b| b.0.cmp(&a.0));

        let activities = activities
            .into_iter()
            .map(|(_, activity)| activity)
            .collect();

        activities
    }

    pub fn get_ordered_by_user_and_timespan(
        user_id: UserId,
        start: NaiveDateTime,
        end: NaiveDateTime,
        conn: &PgConnection,
    ) -> QueryResult<Vec<Self>> {
        Ok(Self::join_and_order(
            Diary::get_ordered_by_user_and_timespan(user_id, start, end, conn)?,
            Wod::get_ordered_by_user_and_timespan(user_id, start, end, conn)?,
            StrengthSessionDescription::get_ordered_by_user_and_timespan(
                user_id, start, end, conn,
            )?,
            MetconSessionDescription::get_ordered_by_user_and_timespan(user_id, start, end, conn)?,
            CardioSessionDescription::get_ordered_by_user_and_timespan(user_id, start, end, conn)?,
        ))
    }
}

impl GetByUser for Activity {
    fn get_by_user(user_id: UserId, conn: &PgConnection) -> QueryResult<Vec<Self>> {
        Ok(Self::join_and_order(
            Diary::get_by_user(user_id, conn)?,
            Wod::get_by_user(user_id, conn)?,
            StrengthSessionDescription::get_by_user(user_id, conn)?,
            MetconSessionDescription::get_by_user(user_id, conn)?,
            CardioSessionDescription::get_by_user(user_id, conn)?,
        ))
    }
}
