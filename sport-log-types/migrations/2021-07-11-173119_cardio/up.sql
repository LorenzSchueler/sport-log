create type cardio_type as enum('training', 'active_recovery', 'freetime');

create type "position" as (
    longitude double precision, --numeric(8, 5)
    latitude double precision, --numeric(9, 6)
    elevation real, -- numeric(5, 1) or round to int
    distance integer, -- meter since start
    time integer -- seconds since start
);

create table route (
    id serial primary key,
    user_id integer not null references "user" on delete cascade,
    name varchar(80) not null check (length(name) >= 2),
    distance integer not null check (distance > 0),
    ascent integer check (ascent >= 0),
    descent integer check (descent >= 0),
    track "position"[],
    unique (user_id, name)
);
--create index on route (user_id, name);

insert into route (user_id, name, distance, ascent, descent, track) values
    (1, 'around the lake', 26500, 43, 43, null);

create table cardio_session (
    id serial primary key,
    user_id integer not null references "user" on delete cascade,
    movement_id integer not null references movement on delete no action,
    cardio_type cardio_type not null,
    datetime timestamp not null default now(),
    distance integer check (distance > 0),
    ascent integer check (ascent >= 0),
    descent integer check (descent >= 0),
    time integer check (time > 0), -- seconds
    calories integer check (calories >= 0),
    track "position"[],
    avg_cycles integer check (avg_cycles > 0), 
    cycles real[], -- = secs since start
    avg_heart_rate integer check (avg_heart_rate > 0),
    heart_rate real[], -- = secs since start
    route_id integer references route on delete set null,
    comments text,
    unique (user_id, movement_id, datetime)
);
--create index on cardio_session (user_id, datetime desc);

insert into cardio_session (user_id, movement_id, cardio_type, datetime, 
        distance, ascent, descent, time, calories, track, avg_cycles, 
        cycles, avg_heart_rate, heart_rate, route_id, comments) values
    (1, 5, 'training', '2021-08-22 10:25:34', 
        26742, 35, 43, 9134, null, null, 167, 
        null, 156, null, 1, null);