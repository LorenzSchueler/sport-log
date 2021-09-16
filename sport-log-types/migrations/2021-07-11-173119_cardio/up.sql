create type cardio_type as enum('training', 'active_recovery', 'freetime');

create type "position" as (
    longitude double precision,
    latitude double precision,
    elevation integer, -- meter above sea level
    distance integer, -- meter since start
    time integer -- seconds since start
);

create table route (
    id bigint primary key,
    user_id bigint not null references "user" on delete cascade,
    name varchar(80) not null check (length(name) >= 2),
    distance integer not null check (distance > 0),
    ascent integer check (ascent >= 0),
    descent integer check (descent >= 0),
    track "position"[] not null,
    last_change timestamptz not null default now(),
    deleted boolean not null default false
);

create unique index route_idx on route (user_id, name) where deleted = false;

create trigger set_timestamp before update on route
    for each row execute procedure trigger_set_timestamp();

create table route_archive (
    primary key (id),
    foreign key (user_id) references "user" on delete cascade,
    check (deleted = true)
) inherits (route);

create trigger archive_route
    after update of deleted or delete
    on route
    for each row execute procedure archive_record();

create table cardio_session (
    id bigint primary key,
    user_id bigint not null references "user" on delete cascade,
    movement_id bigint not null references movement on delete cascade,
    cardio_type cardio_type not null,
    datetime timestamptz not null default now(),
    distance integer check (distance > 0),
    ascent integer check (ascent >= 0),
    descent integer check (descent >= 0),
    time integer check (time > 0), -- seconds
    calories integer check (calories >= 0),
    track "position"[],
    avg_cadence integer check (avg_cadence > 0), 
    cadence real[], -- = secs since start
    avg_heart_rate integer check (avg_heart_rate > 0),
    heart_rate real[], -- = secs since start
    route_id bigint references route on delete set null,
    comments text,
    last_change timestamptz not null default now(),
    deleted boolean not null default false
);

create unique index cardio_session_idx on cardio_session (user_id, movement_id, datetime) 
    where deleted = false;

create trigger set_timestamp before update on cardio_session
    for each row execute procedure trigger_set_timestamp();

insert into cardio_session (id, user_id, movement_id, cardio_type, datetime, 
        distance, ascent, descent, time, calories, track, avg_cadence, 
        cadence, avg_heart_rate, heart_rate, route_id, comments) values
    (1, 1, 5, 'training', '2021-08-22 10:25:34', 
        26742, 35, 43, 9134, null, null, 167, 
        null, 156, null, null, null);

create table cardio_session_archive (
    primary key (id),
    foreign key (user_id) references "user" on delete cascade,
    check (deleted = true)
) inherits (cardio_session);

create trigger archive_cardio_session
    after update of deleted or delete
    on cardio_session
    for each row execute procedure archive_record();
