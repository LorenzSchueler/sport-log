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

    user (id) {
        id -> Int4,
        username -> Varchar,
        password -> Varchar,
        email -> Varchar,
    }
}

joinable!(action -> action_provider (action_provider_id));
joinable!(action_event -> action (action_id));
joinable!(action_event -> user (user_id));
joinable!(action_provider -> platform (platform_id));
joinable!(action_rule -> action (action_id));
joinable!(action_rule -> user (user_id));
joinable!(platform_credentials -> platform (platform_id));
joinable!(platform_credentials -> user (user_id));

allow_tables_to_appear_in_same_query!(
    action,
    action_event,
    action_provider,
    action_rule,
    platform,
    platform_credentials,
    user,
);
