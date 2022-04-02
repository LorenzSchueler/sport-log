create table "user" (
    id bigint primary key,
    username varchar(80) not null check (length(username) >= 2),
    password char(96) not null,
    email varchar(80) not null check (length(email) >= 5),
    last_change timestamptz not null default now()
);

create unique index user__username__key on "user" (username);

create unique index user__email__key on "user" (email);

create trigger set_timestamp before update on "user"
    for each row execute procedure trigger_set_timestamp();
