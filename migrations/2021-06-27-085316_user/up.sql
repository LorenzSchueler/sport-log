create table "user" (
    id bigint primary key,
    username varchar(80) not null check (length(username) >= 2),
    password char(96) not null,
    email varchar(80) not null,
    last_change timestamptz not null default now(),
    unique (username),
    unique (email)
);

create trigger set_timestamp before update on "user"
    for each row execute procedure trigger_set_timestamp();

create index on "user" (username);
