#![allow(unused_imports)]
table! {
    use diesel::sql_types::*;
    use crate::model::*;

    account (id) {
        id -> Int4,
        username -> Varchar,
        password -> Varchar,
        email -> Varchar,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::model::*;

    action (id) {
        id -> Int4,
        platform_id -> Int4,
        name -> Varchar,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::model::*;

    action_event (id) {
        id -> Int4,
        account_id -> Int4,
        action_id -> Int4,
        datetime -> Timestamp,
        enabled -> Bool,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::model::*;

    action_rule (id) {
        id -> Int4,
        account_id -> Int4,
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
        account_id -> Int4,
        platform_id -> Int4,
        username -> Varchar,
        password -> Varchar,
    }
}

joinable!(action -> platform (platform_id));
joinable!(action_event -> account (account_id));
joinable!(action_event -> action (action_id));
joinable!(action_rule -> account (account_id));
joinable!(action_rule -> action (action_id));
joinable!(platform_credentials -> account (account_id));
joinable!(platform_credentials -> platform (platform_id));

allow_tables_to_appear_in_same_query!(
    account,
    action,
    action_event,
    action_rule,
    platform,
    platform_credentials,
);
