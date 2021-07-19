create type cardio_type as enum('training', 'active_recovery', 'freetime');

create type "position" as (
    longitude double precision, --numeric(8, 5)
    latitude double precision, --numeric(9, 6)
    elevation real, --numeric(5, 1)
    time interval
);

create table route (
    id serial primary key,
    user_id integer not null references "user" on delete cascade,
    name varchar(80) not null unique,
    distance integer not null,
    ascent integer,
    descent integer,
    track "position"[]
);
--create index on route (user_id, name);

create table cardio_session (
    id serial primary key,
    user_id integer not null references "user" on delete cascade,
    movement_id integer not null references movement on delete no action,
    cardio_type cardio_type not null,
    datetime timestamp not null default now(),
    distance integer,
    ascent integer,
    descent integer,
    time integer, -- seconds
    calories integer,
    track "position"[],
    avg_cycles integer, 
    cycles real[], -- = secs since start
    avg_heart_rate integer,
    heart_rate real[], -- = secs since start
    route_id integer references route on delete set null,
    comments text
);
--create index on cardio_session (user_id, datetime desc);