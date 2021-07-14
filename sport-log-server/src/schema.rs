#![allow(unused_imports)]
table! {
    use diesel::sql_types::*;
    use crate::model::*;

    action (id) {
        id -> Int4,
        name -> Varchar,
        action_provider_id -> Int4,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::model::*;

    action_event (id) {
        id -> Int4,
        user_id -> Int4,
        action_id -> Int4,
        datetime -> Timestamp,
        enabled -> Bool,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::model::*;

    action_provider (id) {
        id -> Int4,
        name -> Varchar,
        password -> Varchar,
        platform_id -> Int4,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::model::*;

    action_rule (id) {
        id -> Int4,
        user_id -> Int4,
        action_id -> Int4,
        weekday -> WeekdayMapping,
        time -> Time,
        enabled -> Bool,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::model::*;

    cardio_session (id) {
        id -> Int4,
        user_id -> Int4,
        movement_id -> Int4,
        cardio_type -> CardioTypeMapping,
        datetime -> Timestamp,
        distance -> Nullable<Int4>,
        ascent -> Nullable<Int4>,
        descent -> Nullable<Int4>,
        time -> Nullable<Interval>,
        calories -> Nullable<Int4>,
        track -> Nullable<Array<Position>>,
        avg_cycles -> Nullable<Int4>,
        cycles -> Nullable<Array<Float4>>,
        avg_heart_rate -> Nullable<Int4>,
        heart_rate -> Nullable<Array<Float4>>,
        route_id -> Nullable<Int4>,
        comments -> Nullable<Text>,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::model::*;

    diary (id) {
        id -> Int4,
        user_id -> Int4,
        date -> Date,
        bodyweight -> Nullable<Float4>,
        comments -> Nullable<Text>,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::model::*;

    eorm (id) {
        id -> Int4,
        reps -> Int4,
        percentage -> Float4,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::model::*;

    group (id) {
        id -> Int4,
        name -> Varchar,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::model::*;

    group_user (id) {
        id -> Int4,
        group_id -> Int4,
        user_id -> Int4,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::model::*;

    metcon (id) {
        id -> Int4,
        user_id -> Int4,
        name -> Nullable<Varchar>,
        metcon_type -> MetconTypeMapping,
        rounds -> Nullable<Int4>,
        timecap -> Nullable<Interval>,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::model::*;

    metcon_movements (id) {
        id -> Int4,
        movement_id -> Int4,
        metcon_id -> Int4,
        count -> Int4,
        unit -> MovementUnitMapping,
        weight -> Nullable<Float4>,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::model::*;

    metcon_session (id) {
        id -> Int4,
        user_id -> Int4,
        metcon_id -> Int4,
        datetime -> Timestamp,
        time -> Nullable<Interval>,
        rounds -> Nullable<Int4>,
        reps -> Nullable<Int4>,
        rx -> Bool,
        comments -> Nullable<Text>,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::model::*;

    movement (id) {
        id -> Int4,
        user_id -> Int4,
        name -> Varchar,
        description -> Nullable<Text>,
        category -> MovementCategoryMapping,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::model::*;

    platform (id) {
        id -> Int4,
        name -> Varchar,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::model::*;

    platform_credentials (id) {
        id -> Int4,
        user_id -> Int4,
        platform_id -> Int4,
        username -> Varchar,
        password -> Varchar,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::model::*;

    route (id) {
        id -> Int4,
        user_id -> Int4,
        name -> Varchar,
        distance -> Int4,
        ascent -> Nullable<Int4>,
        descent -> Nullable<Int4>,
        track -> Nullable<Array<Position>>,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::model::*;

    shared_cardio_session (id) {
        id -> Int4,
        group_id -> Int4,
        cardio_session_id -> Int4,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::model::*;

    shared_diary (id) {
        id -> Int4,
        group_id -> Int4,
        diary_id -> Int4,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::model::*;

    shared_metcon_session (id) {
        id -> Int4,
        group_id -> Int4,
        metcon_session_id -> Int4,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::model::*;

    shared_strength_session (id) {
        id -> Int4,
        group_id -> Int4,
        strength_session_id -> Int4,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::model::*;

    strength_session (id) {
        id -> Int4,
        user_id -> Int4,
        datetime -> Timestamp,
        movement_id -> Int4,
        movement_unit -> MovementUnitMapping,
        interval -> Nullable<Int4>,
        comments -> Nullable<Text>,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::model::*;

    strength_set (id) {
        id -> Int4,
        strength_session_id -> Int4,
        count -> Int4,
        weight -> Nullable<Float4>,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::model::*;

    user (id) {
        id -> Int4,
        username -> Varchar,
        password -> Varchar,
        email -> Varchar,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::model::*;

    wod (id) {
        id -> Int4,
        user_id -> Int4,
        datetime -> Timestamp,
        description -> Nullable<Text>,
    }
}

joinable!(action -> action_provider (action_provider_id));
joinable!(action_event -> action (action_id));
joinable!(action_event -> user (user_id));
joinable!(action_provider -> platform (platform_id));
joinable!(action_rule -> action (action_id));
joinable!(action_rule -> user (user_id));
joinable!(cardio_session -> movement (movement_id));
joinable!(cardio_session -> route (route_id));
joinable!(cardio_session -> user (user_id));
joinable!(diary -> user (user_id));
joinable!(group_user -> group (group_id));
joinable!(group_user -> user (user_id));
joinable!(metcon -> user (user_id));
joinable!(metcon_movements -> metcon (metcon_id));
joinable!(metcon_movements -> movement (movement_id));
joinable!(metcon_session -> metcon (metcon_id));
joinable!(metcon_session -> user (user_id));
joinable!(movement -> user (user_id));
joinable!(platform_credentials -> platform (platform_id));
joinable!(platform_credentials -> user (user_id));
joinable!(route -> user (user_id));
joinable!(shared_cardio_session -> cardio_session (cardio_session_id));
joinable!(shared_cardio_session -> group (group_id));
joinable!(shared_diary -> diary (diary_id));
joinable!(shared_diary -> group (group_id));
joinable!(shared_metcon_session -> group (group_id));
joinable!(shared_metcon_session -> metcon_session (metcon_session_id));
joinable!(shared_strength_session -> group (group_id));
joinable!(shared_strength_session -> strength_session (strength_session_id));
joinable!(strength_session -> movement (movement_id));
joinable!(strength_session -> user (user_id));
joinable!(strength_set -> strength_session (strength_session_id));
joinable!(wod -> user (user_id));

allow_tables_to_appear_in_same_query!(
    action,
    action_event,
    action_provider,
    action_rule,
    cardio_session,
    diary,
    eorm,
    group,
    group_user,
    metcon,
    metcon_movements,
    metcon_session,
    movement,
    platform,
    platform_credentials,
    route,
    shared_cardio_session,
    shared_diary,
    shared_metcon_session,
    shared_strength_session,
    strength_session,
    strength_set,
    user,
    wod,
);
