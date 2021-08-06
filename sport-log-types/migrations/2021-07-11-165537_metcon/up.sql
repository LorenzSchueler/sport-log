create type metcon_type as enum('amrap', 'emom', 'for_time');

create table metcon (
    id serial primary key,
    user_id integer references "user" on delete cascade,
    name varchar(80),
    metcon_type metcon_type not null,
    rounds integer check (rounds >= 1),
    timecap integer check (timecap > 0), -- seconds
    description text,
    unique (user_id, name)
);
--create index on metcon (user_id, name);

insert into metcon (user_id, name, metcon_type, rounds, timecap, description) values
    (null, 'Cindy', 'amrap', null, 1200, null),
    (null, 'Murph', 'for_time', 1, null, 'wear a weight vest (20/14) lbs'),
    (1, '5k Row', 'for_time', 1, 1800, null);

create table metcon_movement (
    id serial primary key,
    metcon_id integer not null references metcon on delete cascade,
    movement_id integer not null references movement on delete no action,
    movement_number integer not null check (movement_number >= 1),
    count integer not null check (count >= 1),
    movement_unit movement_unit not null,
    weight real check (weight > 0),
    unique (metcon_id, movement_number)
);

insert into metcon_movement (metcon_id, movement_id, movement_number, count, movement_unit, weight) values
    (1, 9, 1, 5, 'reps', null),
    (1, 10, 2, 10, 'reps', null),
    (1, 11, 3, 15, 'reps', null),
    (2, 5, 1, 1, 'mile', 9),
    (2, 9, 2, 100, 'reps', 9),
    (2, 10, 3, 200, 'reps', 9),
    (2, 11, 4, 300, 'reps', 9),
    (2, 5, 5, 1, 'mile', 9),
    (3, 8, 5, 1, 'km', null);

create table metcon_session (
    id serial primary key,
    user_id integer not null references "user" on delete cascade,
    metcon_id integer not null references metcon on delete no action,
    datetime timestamp not null default now(),
    time integer check (time > 0), -- seconds
    rounds integer check (rounds >= 0),
    reps integer check (reps >= 0),
    rx boolean not null default true,
    comments text,
    unique (user_id, metcon_id, datetime)
);
--create index on metcon_session (user_id, datetime desc);

insert into metcon_session (user_id, metcon_id, datetime, time, rounds, reps, rx, comments) values
    (1, 1, '2020-08-20 16:00:00', null, 17, 8, true, null),
    (1, 2, '2020-08-23 18:00:00', 1800, null, null, false, 'without vest');
