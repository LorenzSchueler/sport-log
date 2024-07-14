create table "user" (
    id bigint primary key,
    username varchar(80) not null check (length(username) >= 2),
    password varchar(120) not null,
    email varchar(80) not null check (length(email) >= 5),
    epoch bigint not null
);

create unique index user__username__key on "user" (username);

create unique index user__email__key on "user" (email);

create trigger set_epoch before insert or update on "user"
    for each row execute function set_epoch_for_user_in_user_table();
