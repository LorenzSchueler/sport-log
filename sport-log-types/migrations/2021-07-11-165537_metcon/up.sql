create type metcon_type as enum('amrap', 'emom', 'for_time', 'ladder');

create table metcon (
    id serial primary key,
    user_id integer references "user" on delete cascade,
    name varchar(80) unique,
    metcon_type metcon_type not null,
    rounds integer,
    timecap integer, -- seconds
    description text
);
--create index on metcon (user_id, name);

insert into metcon (user_id, name, metcon_type, rounds, timecap, description) values
    (null, 'Cindy', 'amrap', null, 1200, null),
    (null, 'Murph', 'for_time', 1, null, 'wear a weight vest (20/14) lbs'),
    (1, '5k Row', 'for_time', 1, 1800, null);

create table metcon_movement (
    id serial primary key,
    movement_id integer not null references movement on delete no action,
    metcon_id integer not null references metcon on delete cascade,
    count integer not null,
    movement_unit movement_unit not null,
    weight real
);

insert into metcon_movement (movement_id, metcon_id, count, movement_unit, weight) values
    (9, 1, 5, 'reps', null),
    (10, 1, 10, 'reps', null),
    (11, 1, 15, 'reps', null),
    (5, 1, 1, 'mile', 9),
    (9, 1, 100, 'reps', 9),
    (10, 1, 200, 'reps', 9),
    (11, 1, 300, 'reps', 9),
    (5, 1, 1, 'mile', 9),
    (8, 3, 5, 'km', null);

create table metcon_session (
    id serial primary key,
    user_id integer not null references "user" on delete cascade,
    metcon_id integer not null references metcon on delete no action,
    datetime timestamp not null default now(),
    time integer, -- seconds
    rounds integer,
    reps integer,
    rx boolean not null default true,
    comments text
);
--create index on metcon_session (user_id, datetime desc);

insert into metcon_session (user_id, metcon_id, datetime, time, rounds, reps, rx, comments) values
    (1, 1, '2020-08-20 16:00:00', null, 17, 8, true, null),
    (1, 2, '2020-08-23 18:00:00', 1800, null, null, false, 'without vest');
