create type metcon_type as enum('amrap', 'emom', 'for_time', 'ladder');

create table metcon (
    id serial primary key,
    user_id integer not null references "user" on delete cascade,
    name varchar(80) unique,
    metcon_type metcon_type not null,
    rounds integer,
    timecap integer -- seconds
);
--create index on metcon (user_id, name);

create table metcon_movement (
    id serial primary key,
    movement_id integer not null references movement on delete no action,
    metcon_id integer not null references metcon on delete cascade,
    count integer not null,
    unit movement_unit not null,
    weight real
);

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