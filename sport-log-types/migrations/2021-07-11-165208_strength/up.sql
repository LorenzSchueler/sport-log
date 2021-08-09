create table strength_session (
    id bigint primary key,
    user_id integer not null references "user" on delete cascade,
    datetime timestamp not null default now(),
    movement_id integer not null references movement on delete no action,
    movement_unit movement_unit not null,
    interval integer check (interval > 0),
    comments text,
    last_change timestamptz not null default now(),
    deleted boolean not null default false,
    unique (user_id, datetime, movement_id, deleted)
);

create trigger set_timestamp before update on strength_session
    for each row execute procedure trigger_set_timestamp();

insert into strength_session (id, user_id, datetime, movement_id, movement_unit, interval, comments) values
    (1, 1, '2021-08-20 16:00:00', 2, 'reps', 120, null),
    (2, 1, '2021-08-22 16:00:00', 1, 'reps', null, null);

create table strength_set (
    id bigint primary key,
    strength_session_id integer not null references strength_session on delete cascade,
    set_number integer not null check (set_number >= 1),
    count integer not null check (count >= 1), -- number of completed movement_unit
    weight real check (weight > 0),
    last_change timestamptz not null default now(),
    deleted boolean not null default false,
    unique (strength_session_id, set_number, deleted)
);

create trigger set_timestamp before update on strength_set
    for each row execute procedure trigger_set_timestamp();

insert into strength_set (id, strength_session_id, set_number, count, weight) values
    (1, 1, 1, 5, 110),
    (2, 1, 2, 5, 115),
    (3, 1, 3, 5, 120),
    (4, 1, 4, 5, 122.5),
    (5, 1, 5, 5, 125),
    (6, 2, 1, 3, 125),
    (7, 2, 2, 3, 130),
    (8, 2, 3, 3, 135),
    (9, 2, 4, 3, 130);