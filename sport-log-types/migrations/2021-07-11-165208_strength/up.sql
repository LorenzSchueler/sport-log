create table strength_session (
    id serial primary key,
    user_id integer not null references "user" on delete cascade,
    datetime timestamp not null default now(),
    movement_id integer not null references movement on delete no action,
    movement_unit movement_unit not null,
    interval integer,
    comments text
);
--create index on strength_session (user_id, datetime desc);

insert into strength_session (user_id, datetime, movement_id, movement_unit, interval, comments) values
    (1, '2021-08-20 16:00:00', 2, 'reps', 120, null),
    (1, '2021-08-22 16:00:00', 1, 'reps', 105, null);

create table strength_set (
    id serial primary key,
    strength_session_id integer not null references strength_session on delete cascade,
    set_number integer not null,
    count integer not null, -- number of completed movement_unit
    weight real,
    unique (strength_session_id, set_number)
);

insert into strength_set (strength_session_id, set_number, count, weight) values
    (1, 1, 5, 110),
    (1, 2, 5, 115),
    (1, 3, 5, 120),
    (1, 4, 5, 122.5),
    (1, 5, 5, 125),
    (2, 1, 3, 125),
    (2, 2, 3, 130),
    (2, 3, 3, 135),
    (2, 4, 3, 130);