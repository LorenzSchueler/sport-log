// @generated automatically by Diesel CLI.

pub mod sql_types {
    //https://github.com/diesel-rs/diesel/blob/db6730c9a79135728ec4f87fabdb745d71cb4578/diesel_derives/src/sql_type.rs
    use std::sync::atomic::{AtomicU32, Ordering};

    use diesel::pg::PgTypeMetadata;

    pub static CUSTOM_TYPES: [&(&str, AtomicU32, AtomicU32); 6] = [
        &CARDIO_TYPE,
        &DISTANCE_UNIT,
        &METCON_TYPE,
        &MOVEMENT_DIMENSION,
        &POSITION,
        &WEEKDAY,
    ];

    pub struct CardioType;

    static CARDIO_TYPE: (&str, AtomicU32, AtomicU32) =
        ("cardio_type", AtomicU32::new(0), AtomicU32::new(0));

    impl diesel::sql_types::SqlType for CardioType {
        type IsNull = diesel::sql_types::is_nullable::NotNull;
    }

    impl diesel::sql_types::SingleValue for CardioType {}

    impl diesel::sql_types::HasSqlType<CardioType> for diesel::pg::Pg {
        fn metadata(_: &mut Self::MetadataLookup) -> PgTypeMetadata {
            PgTypeMetadata::new(
                CARDIO_TYPE.1.load(Ordering::Acquire),
                CARDIO_TYPE.2.load(Ordering::Acquire),
            )
        }
    }

    pub struct DistanceUnit;

    static DISTANCE_UNIT: (&str, AtomicU32, AtomicU32) =
        ("distance_unit", AtomicU32::new(0), AtomicU32::new(0));

    impl diesel::sql_types::SqlType for DistanceUnit {
        type IsNull = diesel::sql_types::is_nullable::NotNull;
    }

    impl diesel::sql_types::SingleValue for DistanceUnit {}

    impl diesel::sql_types::HasSqlType<DistanceUnit> for diesel::pg::Pg {
        fn metadata(_: &mut Self::MetadataLookup) -> PgTypeMetadata {
            PgTypeMetadata::new(
                DISTANCE_UNIT.1.load(Ordering::Acquire),
                DISTANCE_UNIT.2.load(Ordering::Acquire),
            )
        }
    }

    pub struct MetconType;

    static METCON_TYPE: (&str, AtomicU32, AtomicU32) =
        ("metcon_type", AtomicU32::new(0), AtomicU32::new(0));

    impl diesel::sql_types::SqlType for MetconType {
        type IsNull = diesel::sql_types::is_nullable::NotNull;
    }

    impl diesel::sql_types::SingleValue for MetconType {}

    impl diesel::sql_types::HasSqlType<MetconType> for diesel::pg::Pg {
        fn metadata(_: &mut Self::MetadataLookup) -> PgTypeMetadata {
            PgTypeMetadata::new(
                METCON_TYPE.1.load(Ordering::Acquire),
                METCON_TYPE.2.load(Ordering::Acquire),
            )
        }
    }

    pub struct MovementDimension;

    static MOVEMENT_DIMENSION: (&str, AtomicU32, AtomicU32) =
        ("movement_dimension", AtomicU32::new(0), AtomicU32::new(0));

    impl diesel::sql_types::SqlType for MovementDimension {
        type IsNull = diesel::sql_types::is_nullable::NotNull;
    }

    impl diesel::sql_types::SingleValue for MovementDimension {}

    impl diesel::sql_types::HasSqlType<MovementDimension> for diesel::pg::Pg {
        fn metadata(_: &mut Self::MetadataLookup) -> PgTypeMetadata {
            PgTypeMetadata::new(
                MOVEMENT_DIMENSION.1.load(Ordering::Acquire),
                MOVEMENT_DIMENSION.2.load(Ordering::Acquire),
            )
        }
    }

    pub struct Position;

    static POSITION: (&str, AtomicU32, AtomicU32) =
        ("position", AtomicU32::new(0), AtomicU32::new(0));

    impl diesel::sql_types::SqlType for Position {
        type IsNull = diesel::sql_types::is_nullable::NotNull;
    }

    impl diesel::sql_types::SingleValue for Position {}

    impl diesel::sql_types::HasSqlType<Position> for diesel::pg::Pg {
        fn metadata(_: &mut Self::MetadataLookup) -> PgTypeMetadata {
            PgTypeMetadata::new(
                POSITION.1.load(Ordering::Acquire),
                POSITION.2.load(Ordering::Acquire),
            )
        }
    }

    pub struct Weekday;

    static WEEKDAY: (&str, AtomicU32, AtomicU32) =
        ("weekday", AtomicU32::new(0), AtomicU32::new(0));

    impl diesel::sql_types::SqlType for Weekday {
        type IsNull = diesel::sql_types::is_nullable::NotNull;
    }

    impl diesel::sql_types::SingleValue for Weekday {}

    impl diesel::sql_types::HasSqlType<Weekday> for diesel::pg::Pg {
        fn metadata(_: &mut Self::MetadataLookup) -> PgTypeMetadata {
            PgTypeMetadata::new(
                WEEKDAY.1.load(Ordering::Acquire),
                WEEKDAY.2.load(Ordering::Acquire),
            )
        }
    }
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
    use super::sql_types::Position;

    cardio_session (id) {
        id -> Int8,
        user_id -> Int8,
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
        distance -> Nullable<Int4>,
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

    strength_session (id) {
        id -> Int8,
        user_id -> Int8,
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
diesel::joinable!(cardio_session -> movement (movement_id));
diesel::joinable!(cardio_session -> route (route_id));
diesel::joinable!(cardio_session -> user (user_id));
diesel::joinable!(diary -> user (user_id));
diesel::joinable!(group_user -> group (group_id));
diesel::joinable!(group_user -> user (user_id));
diesel::joinable!(metcon -> user (user_id));
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
diesel::joinable!(strength_session -> movement (movement_id));
diesel::joinable!(strength_session -> user (user_id));
diesel::joinable!(strength_set -> strength_session (strength_session_id));
diesel::joinable!(wod -> user (user_id));

diesel::allow_tables_to_appear_in_same_query!(
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
    strength_session,
    strength_set,
    user,
    wod,
);
