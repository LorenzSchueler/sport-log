# TODO

- make sure on update own id used
    - ___.user_id = *auth && load_by_id_from_db.user_id = *auth
    - all verify on non-New non-Id types (= for all updates)
    - use attribute macro for simple verification
        - #[verify(usr, ap, adm)]
        - #[verify_db(usr, ap, adm)]
- into_inner only in mod verify not in handler