// @generated automatically by Diesel CLI.

pub mod sql_types {
    #[derive(diesel::sql_types::SqlType)]
    #[diesel(postgres_type(name = "cardio_type"))]
    pub struct CardioType;

    #[derive(diesel::sql_types::SqlType)]
    #[diesel(postgres_type(name = "distance_unit"))]
    pub struct DistanceUnit;

    #[derive(diesel::sql_types::SqlType)]
    #[diesel(postgres_type(name = "metcon_type"))]
    pub struct MetconType;

    #[derive(diesel::sql_types::SqlType)]
    #[diesel(postgres_type(name = "movement_dimension"))]
    pub struct MovementDimension;

    #[derive(diesel::sql_types::SqlType)]
    #[diesel(postgres_type(name = "position"))]
    pub struct Position;

    #[derive(diesel::sql_types::SqlType)]
    #[diesel(postgres_type(name = "weekday"))]
    pub struct Weekday;
}

diesel::table! {
    use diesel::sql_types::*;

    action (id) {
        id -> Int8,
        #[max_length = 80]
        name -> Varchar,
        action_provider_id -> Int8,
        description -> Nullable<Text>,
        create_before -> Int4,
        delete_after -> Int4,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

diesel::table! {
    use diesel::sql_types::*;

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

diesel::table! {
    use diesel::sql_types::*;

    action_provider (id) {
        id -> Int8,
        #[max_length = 80]
        name -> Varchar,
        #[max_length = 120]
        password -> Varchar,
        platform_id -> Int8,
        description -> Nullable<Text>,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

diesel::table! {
    use diesel::sql_types::*;
    use super::sql_types::Weekday;

    action_rule (id) {
        id -> Int8,
        user_id -> Int8,
        action_id -> Int8,
        weekday -> Weekday,
        time -> Timestamptz,
        arguments -> Nullable<Text>,
        enabled -> Bool,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

diesel::table! {
    use diesel::sql_types::*;
    use super::sql_types::CardioType;

    cardio_blueprint (id) {
        id -> Int8,
        user_id -> Int8,
        training_plan_id -> Int8,
        #[max_length = 80]
        name -> Varchar,
        description -> Nullable<Text>,
        movement_id -> Int8,
        cardio_type -> CardioType,
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

diesel::table! {
    use diesel::sql_types::*;
    use super::sql_types::CardioType;
    use super::sql_types::Position;

    cardio_session (id) {
        id -> Int8,
        user_id -> Int8,
        cardio_blueprint_id -> Nullable<Int8>,
        movement_id -> Int8,
        cardio_type -> CardioType,
        datetime -> Timestamptz,
        distance -> Nullable<Int4>,
        ascent -> Nullable<Int4>,
        descent -> Nullable<Int4>,
        time -> Nullable<Int4>,
        calories -> Nullable<Int4>,
        track -> Nullable<Array<Position>>,
        avg_cadence -> Nullable<Int4>,
        cadence -> Nullable<Array<Int4>>,
        avg_heart_rate -> Nullable<Int4>,
        heart_rate -> Nullable<Array<Int4>>,
        route_id -> Nullable<Int8>,
        comments -> Nullable<Text>,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

diesel::table! {
    use diesel::sql_types::*;

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

diesel::table! {
    use diesel::sql_types::*;

    eorm (id) {
        id -> Int8,
        reps -> Int4,
        percentage -> Float4,
    }
}

diesel::table! {
    use diesel::sql_types::*;

    group (id) {
        id -> Int8,
        #[max_length = 80]
        name -> Varchar,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

diesel::table! {
    use diesel::sql_types::*;

    group_user (id) {
        id -> Int8,
        group_id -> Int8,
        user_id -> Int8,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

diesel::table! {
    use diesel::sql_types::*;
    use super::sql_types::MetconType;

    metcon (id) {
        id -> Int8,
        user_id -> Nullable<Int8>,
        #[max_length = 80]
        name -> Varchar,
        metcon_type -> MetconType,
        rounds -> Nullable<Int4>,
        timecap -> Nullable<Int4>,
        description -> Nullable<Text>,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

diesel::table! {
    use diesel::sql_types::*;

    metcon_item (id) {
        id -> Int8,
        training_plan_id -> Int8,
        metcon_id -> Int8,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

diesel::table! {
    use diesel::sql_types::*;
    use super::sql_types::DistanceUnit;

    metcon_movement (id) {
        id -> Int8,
        metcon_id -> Int8,
        movement_id -> Int8,
        distance_unit -> Nullable<DistanceUnit>,
        movement_number -> Int4,
        count -> Int4,
        male_weight -> Nullable<Float4>,
        female_weight -> Nullable<Float4>,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

diesel::table! {
    use diesel::sql_types::*;

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

diesel::table! {
    use diesel::sql_types::*;
    use super::sql_types::MovementDimension;

    movement (id) {
        id -> Int8,
        user_id -> Nullable<Int8>,
        #[max_length = 80]
        name -> Varchar,
        description -> Nullable<Text>,
        movement_dimension -> MovementDimension,
        cardio -> Bool,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

diesel::table! {
    use diesel::sql_types::*;

    movement_muscle (id) {
        id -> Int8,
        movement_id -> Int8,
        muscle_group_id -> Int8,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

diesel::table! {
    use diesel::sql_types::*;

    muscle_group (id) {
        id -> Int8,
        #[max_length = 80]
        name -> Varchar,
        description -> Nullable<Text>,
    }
}

diesel::table! {
    use diesel::sql_types::*;

    platform (id) {
        id -> Int8,
        #[max_length = 80]
        name -> Varchar,
        credential -> Bool,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

diesel::table! {
    use diesel::sql_types::*;

    platform_credential (id) {
        id -> Int8,
        user_id -> Int8,
        platform_id -> Int8,
        #[max_length = 80]
        username -> Varchar,
        #[max_length = 80]
        password -> Varchar,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

diesel::table! {
    use diesel::sql_types::*;
    use super::sql_types::Position;

    route (id) {
        id -> Int8,
        user_id -> Int8,
        #[max_length = 80]
        name -> Varchar,
        distance -> Int4,
        ascent -> Nullable<Int4>,
        descent -> Nullable<Int4>,
        track -> Nullable<Array<Position>>,
        marked_positions -> Nullable<Array<Position>>,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

diesel::table! {
    use diesel::sql_types::*;

    shared_cardio_session (id) {
        id -> Int8,
        group_id -> Int8,
        cardio_session_id -> Int8,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

diesel::table! {
    use diesel::sql_types::*;

    shared_diary (id) {
        id -> Int8,
        group_id -> Int8,
        diary_id -> Int8,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

diesel::table! {
    use diesel::sql_types::*;

    shared_metcon_session (id) {
        id -> Int8,
        group_id -> Int8,
        metcon_session_id -> Int8,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

diesel::table! {
    use diesel::sql_types::*;

    shared_strength_session (id) {
        id -> Int8,
        group_id -> Int8,
        strength_session_id -> Int8,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

diesel::table! {
    use diesel::sql_types::*;

    strength_blueprint (id) {
        id -> Int8,
        user_id -> Int8,
        training_plan_id -> Int8,
        #[max_length = 80]
        name -> Varchar,
        description -> Nullable<Text>,
        movement_id -> Int8,
        interval -> Nullable<Int4>,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

diesel::table! {
    use diesel::sql_types::*;

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

diesel::table! {
    use diesel::sql_types::*;

    strength_session (id) {
        id -> Int8,
        user_id -> Int8,
        strength_blueprint_id -> Nullable<Int8>,
        datetime -> Timestamptz,
        movement_id -> Int8,
        interval -> Nullable<Int4>,
        comments -> Nullable<Text>,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

diesel::table! {
    use diesel::sql_types::*;

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

diesel::table! {
    use diesel::sql_types::*;
    use super::sql_types::Weekday;

    training_plan (id) {
        id -> Int8,
        user_id -> Int8,
        #[max_length = 80]
        name -> Varchar,
        description -> Nullable<Text>,
        date -> Nullable<Date>,
        weekday -> Nullable<Weekday>,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

diesel::table! {
    use diesel::sql_types::*;

    user (id) {
        id -> Int8,
        #[max_length = 80]
        username -> Varchar,
        #[max_length = 120]
        password -> Varchar,
        #[max_length = 80]
        email -> Varchar,
        last_change -> Timestamptz,
    }
}

diesel::table! {
    use diesel::sql_types::*;

    wod (id) {
        id -> Int8,
        user_id -> Int8,
        date -> Date,
        description -> Nullable<Text>,
        last_change -> Timestamptz,
        deleted -> Bool,
    }
}

diesel::joinable!(action -> action_provider (action_provider_id));
diesel::joinable!(action_event -> action (action_id));
diesel::joinable!(action_event -> user (user_id));
diesel::joinable!(action_provider -> platform (platform_id));
diesel::joinable!(action_rule -> action (action_id));
diesel::joinable!(action_rule -> user (user_id));
diesel::joinable!(cardio_blueprint -> movement (movement_id));
diesel::joinable!(cardio_blueprint -> route (route_id));
diesel::joinable!(cardio_blueprint -> training_plan (training_plan_id));
diesel::joinable!(cardio_blueprint -> user (user_id));
diesel::joinable!(cardio_session -> cardio_blueprint (cardio_blueprint_id));
diesel::joinable!(cardio_session -> movement (movement_id));
diesel::joinable!(cardio_session -> route (route_id));
diesel::joinable!(cardio_session -> user (user_id));
diesel::joinable!(diary -> user (user_id));
diesel::joinable!(group_user -> group (group_id));
diesel::joinable!(group_user -> user (user_id));
diesel::joinable!(metcon -> user (user_id));
diesel::joinable!(metcon_item -> metcon (metcon_id));
diesel::joinable!(metcon_item -> training_plan (training_plan_id));
diesel::joinable!(metcon_movement -> metcon (metcon_id));
diesel::joinable!(metcon_movement -> movement (movement_id));
diesel::joinable!(metcon_session -> metcon (metcon_id));
diesel::joinable!(metcon_session -> user (user_id));
diesel::joinable!(movement -> user (user_id));
diesel::joinable!(movement_muscle -> movement (movement_id));
diesel::joinable!(movement_muscle -> muscle_group (muscle_group_id));
diesel::joinable!(platform_credential -> platform (platform_id));
diesel::joinable!(platform_credential -> user (user_id));
diesel::joinable!(route -> user (user_id));
diesel::joinable!(shared_cardio_session -> cardio_session (cardio_session_id));
diesel::joinable!(shared_cardio_session -> group (group_id));
diesel::joinable!(shared_diary -> diary (diary_id));
diesel::joinable!(shared_diary -> group (group_id));
diesel::joinable!(shared_metcon_session -> group (group_id));
diesel::joinable!(shared_metcon_session -> metcon_session (metcon_session_id));
diesel::joinable!(shared_strength_session -> group (group_id));
diesel::joinable!(shared_strength_session -> strength_session (strength_session_id));
diesel::joinable!(strength_blueprint -> movement (movement_id));
diesel::joinable!(strength_blueprint -> training_plan (training_plan_id));
diesel::joinable!(strength_blueprint -> user (user_id));
diesel::joinable!(strength_blueprint_set -> strength_blueprint (strength_blueprint_id));
diesel::joinable!(strength_session -> movement (movement_id));
diesel::joinable!(strength_session -> strength_blueprint (strength_blueprint_id));
diesel::joinable!(strength_session -> user (user_id));
diesel::joinable!(strength_set -> strength_session (strength_session_id));
diesel::joinable!(training_plan -> user (user_id));
diesel::joinable!(wod -> user (user_id));

diesel::allow_tables_to_appear_in_same_query!(
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
