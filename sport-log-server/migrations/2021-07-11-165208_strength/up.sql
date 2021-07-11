create table strength_session (
    id serial primary key,
    user_id integer not null references "user" on delete cascade,
    datetime timestamp not null default now(),
    interval integer,
    comments text
);
--create index on strength_session (user_id, datetime desc);

create table strength_set (
    id serial primary key,
    strength_session_id integer not null references strength_session on delete cascade,
    reps integer not null,
    weight float
    --effort effort
);