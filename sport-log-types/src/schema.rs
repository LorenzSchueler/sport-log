#![allow(unused_imports)]
table! {
    use diesel::sql_types::*;
    use crate::*;

    action (id) {
        id -> Int8,
        name -> Varchar,
        action_provider_id -> Int8,
        description -> Nullable<Text>,
        create_before -> Int4,
        delete_after -> Int4,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::*;

    action_event (id) {
        id -> Int8,
        user_id -> Int8,
        action_id -> Int8,
        datetime -> Timestamptz,
        arguments -> Nullable<Text>,
        enabled -> Bool,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::*;

    action_provider (id) {
        id -> Int8,
        name -> Varchar,
        password -> Bpchar,
        platform_id -> Int8,
        description -> Nullable<Text>,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::*;

    action_rule (id) {
        id -> Int8,
        user_id -> Int8,
        action_id -> Int8,
        weekday -> WeekdayMapping,
        time -> Timestamptz,
        arguments -> Nullable<Text>,
        enabled -> Bool,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::*;

    cardio_blueprint (id) {
        id -> Int8,
        user_id -> Int8,
        training_plan_id -> Int8,
        name -> Nullable<Varchar>,
        description -> Nullable<Text>,
        movement_id -> Int8,
        cardio_type -> CardioTypeMapping,
        distance -> Nullable<Int4>,
        ascent -> Nullable<Int4>,
        descent -> Nullable<Int4>,
        time -> Nullable<Int4>,
        calories -> Nullable<Int4>,
        avg_heart_rate -> Nullable<Int4>,
        route_id -> Nullable<Int8>,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::*;

    cardio_session (id) {
        id -> Int8,
        user_id -> Int8,
        blueprint_id -> Nullable<Int8>,
        movement_id -> Int8,
        cardio_type -> CardioTypeMapping,
        datetime -> Timestamptz,
        distance -> Nullable<Int4>,
        ascent -> Nullable<Int4>,
        descent -> Nullable<Int4>,
        time -> Nullable<Int4>,
        calories -> Nullable<Int4>,
        track -> Nullable<Array<Position>>,
        avg_cadence -> Nullable<Int4>,
        cadence -> Nullable<Array<Float4>>,
        avg_heart_rate -> Nullable<Int4>,
        heart_rate -> Nullable<Array<Float4>>,
        route_id -> Nullable<Int8>,
        comments -> Nullable<Text>,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::*;

    diary (id) {
        id -> Int8,
        user_id -> Int8,
        date -> Date,
        bodyweight -> Nullable<Float4>,
        comments -> Nullable<Text>,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::*;

    eorm (id) {
        id -> Int8,
        reps -> Int4,
        percentage -> Float4,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::*;

    group (id) {
        id -> Int8,
        name -> Varchar,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::*;

    group_user (id) {
        id -> Int8,
        group_id -> Int8,
        user_id -> Int8,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::*;

    metcon (id) {
        id -> Int8,
        user_id -> Nullable<Int8>,
        name -> Nullable<Varchar>,
        metcon_type -> MetconTypeMapping,
        rounds -> Nullable<Int4>,
        timecap -> Nullable<Int4>,
        description -> Nullable<Text>,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::*;

    metcon_item (id) {
        id -> Int8,
        training_plan_id -> Int8,
        metcon_id -> Int8,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::*;

    metcon_movement (id) {
        id -> Int8,
        metcon_id -> Int8,
        movement_id -> Int8,
        movement_number -> Int4,
        count -> Int4,
        movement_unit -> MovementUnitMapping,
        weight -> Nullable<Float4>,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::*;

    metcon_session (id) {
        id -> Int8,
        user_id -> Int8,
        metcon_id -> Int8,
        datetime -> Timestamptz,
        time -> Nullable<Int4>,
        rounds -> Nullable<Int4>,
        reps -> Nullable<Int4>,
        rx -> Bool,
        comments -> Nullable<Text>,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::*;

    movement (id) {
        id -> Int8,
        user_id -> Nullable<Int8>,
        name -> Varchar,
        description -> Nullable<Text>,
        cardio -> Bool,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::*;

    movement_muscle (id) {
        id -> Int8,
        movement_id -> Int8,
        muscle_group_id -> Int8,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::*;

    muscle_group (id) {
        id -> Int8,
        name -> Varchar,
        description -> Nullable<Text>,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::*;

    platform (id) {
        id -> Int8,
        name -> Varchar,
        credential -> Bool,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::*;

    platform_credential (id) {
        id -> Int8,
        user_id -> Int8,
        platform_id -> Int8,
        username -> Varchar,
        password -> Varchar,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::*;

    route (id) {
        id -> Int8,
        user_id -> Int8,
        name -> Varchar,
        distance -> Int4,
        ascent -> Nullable<Int4>,
        descent -> Nullable<Int4>,
        track -> Array<Position>,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::*;

    shared_cardio_session (id) {
        id -> Int8,
        group_id -> Int8,
        cardio_session_id -> Int8,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::*;

    shared_diary (id) {
        id -> Int8,
        group_id -> Int8,
        diary_id -> Int8,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::*;

    shared_metcon_session (id) {
        id -> Int8,
        group_id -> Int8,
        metcon_session_id -> Int8,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::*;

    shared_strength_session (id) {
        id -> Int8,
        group_id -> Int8,
        strength_session_id -> Int8,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::*;

    strength_blueprint (id) {
        id -> Int8,
        user_id -> Int8,
        training_plan_id -> Int8,
        name -> Nullable<Varchar>,
        description -> Nullable<Text>,
        movement_id -> Int8,
        movement_unit -> MovementUnitMapping,
        interval -> Nullable<Int4>,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::*;

    strength_blueprint_set (id) {
        id -> Int8,
        strength_blueprint_id -> Int8,
        set_number -> Int4,
        count -> Int4,
        weight -> Nullable<Float4>,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::*;

    strength_session (id) {
        id -> Int8,
        user_id -> Int8,
        blueprint_id -> Nullable<Int8>,
        datetime -> Timestamptz,
        movement_id -> Int8,
        movement_unit -> MovementUnitMapping,
        interval -> Nullable<Int4>,
        comments -> Nullable<Text>,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::*;

    strength_set (id) {
        id -> Int8,
        strength_session_id -> Int8,
        set_number -> Int4,
        count -> Int4,
        weight -> Nullable<Float4>,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::*;

    training_plan (id) {
        id -> Int8,
        user_id -> Int8,
        name -> Varchar,
        description -> Nullable<Text>,
        date -> Nullable<Date>,
        weekday -> Nullable<WeekdayMapping>,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::*;

    user (id) {
        id -> Int8,
        username -> Varchar,
        password -> Bpchar,
        email -> Varchar,
        last_change -> Timestamptz,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::*;

    wod (id) {
        id -> Int8,
        user_id -> Int8,
        date -> Date,
        description -> Nullable<Text>,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

joinable!(action -> action_provider (action_provider_id));
joinable!(action_event -> action (action_id));
joinable!(action_event -> user (user_id));
joinable!(action_provider -> platform (platform_id));
joinable!(action_rule -> action (action_id));
joinable!(action_rule -> user (user_id));
joinable!(cardio_blueprint -> movement (movement_id));
joinable!(cardio_blueprint -> route (route_id));
joinable!(cardio_blueprint -> training_plan (training_plan_id));
joinable!(cardio_blueprint -> user (user_id));
joinable!(cardio_session -> cardio_blueprint (blueprint_id));
joinable!(cardio_session -> movement (movement_id));
joinable!(cardio_session -> route (route_id));
joinable!(cardio_session -> user (user_id));
joinable!(diary -> user (user_id));
joinable!(group_user -> group (group_id));
joinable!(group_user -> user (user_id));
joinable!(metcon -> user (user_id));
joinable!(metcon_item -> metcon (metcon_id));
joinable!(metcon_item -> training_plan (training_plan_id));
joinable!(metcon_movement -> metcon (metcon_id));
joinable!(metcon_movement -> movement (movement_id));
joinable!(metcon_session -> metcon (metcon_id));
joinable!(metcon_session -> user (user_id));
joinable!(movement -> user (user_id));
joinable!(movement_muscle -> movement (movement_id));
joinable!(movement_muscle -> muscle_group (muscle_group_id));
joinable!(platform_credential -> platform (platform_id));
joinable!(platform_credential -> user (user_id));
joinable!(route -> user (user_id));
joinable!(shared_cardio_session -> cardio_session (cardio_session_id));
joinable!(shared_cardio_session -> group (group_id));
joinable!(shared_diary -> diary (diary_id));
joinable!(shared_diary -> group (group_id));
joinable!(shared_metcon_session -> group (group_id));
joinable!(shared_metcon_session -> metcon_session (metcon_session_id));
joinable!(shared_strength_session -> group (group_id));
joinable!(shared_strength_session -> strength_session (strength_session_id));
joinable!(strength_blueprint -> movement (movement_id));
joinable!(strength_blueprint -> training_plan (training_plan_id));
joinable!(strength_blueprint -> user (user_id));
joinable!(strength_blueprint_set -> strength_blueprint (strength_blueprint_id));
joinable!(strength_session -> movement (movement_id));
joinable!(strength_session -> strength_blueprint (blueprint_id));
joinable!(strength_session -> user (user_id));
joinable!(strength_set -> strength_session (strength_session_id));
joinable!(training_plan -> user (user_id));
joinable!(wod -> user (user_id));

allow_tables_to_appear_in_same_query!(
    action,
    action_event,
    action_provider,
    action_rule,
    cardio_blueprint,
    cardio_session,
    diary,
    eorm,
    group,
    group_user,
    metcon,
    metcon_item,
    metcon_movement,
    metcon_session,
    movement,
    movement_muscle,
    muscle_group,
    platform,
    platform_credential,
    route,
    shared_cardio_session,
    shared_diary,
    shared_metcon_session,
    shared_strength_session,
    strength_blueprint,
    strength_blueprint_set,
    strength_session,
    strength_set,
    training_plan,
    user,
    wod,
);
