table! {
    account (id) {
        id -> Int4,
        username -> Varchar,
        password -> Varchar,
        email -> Varchar,
    }
}

table! {
    platform (id) {
        id -> Int4,
        name -> Varchar,
    }
}

table! {
    platform_credentials (id) {
        id -> Int4,
        account_id -> Int4,
        platform_id -> Int4,
        username -> Varchar,
        password -> Varchar,
    }
}

joinable!(platform_credentials -> account (account_id));
joinable!(platform_credentials -> platform (platform_id));

allow_tables_to_appear_in_same_query!(
    account,
    platform,
    platform_credentials,
);
