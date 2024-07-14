create type cardio_type as enum('training', 'active_recovery', 'freetime');

create type "position" as (
    longitude double precision,
    latitude double precision,
    elevation double precision, -- meter above sea level
    distance double precision, -- meter since start
    time integer -- milliseconds since start
);

create table route (
    id bigint primary key,
    user_id bigint not null references "user" on delete cascade,
    name varchar(80) not null check (length(name) >= 2),
    distance integer check (distance > 0),
    ascent integer check (ascent >= 0),
    descent integer check (descent >= 0),
    track "position"[],
    marked_positions "position"[],
    epoch bigint not null,
    deleted boolean not null default false
);

create unique index route__user_id__name__key
    on route (user_id, name) where deleted = false;

create index route__user_id__epoch__idx
    on route (user_id, epoch) where deleted = false;

create trigger set_epoch before insert or update on route
    for each row execute function set_epoch_for_user();

create table route_archive (
    primary key (id),
    foreign key (user_id) references "user" on delete cascade,
    check (deleted = true)
) inherits (route);

create trigger archive_route
    after insert or update of deleted or delete
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
    time integer check (time > 0), -- milliseconds
    calories integer check (calories >= 0),
    track "position"[],
    avg_cadence integer check (avg_cadence > 0), 
    cadence integer[], -- = millisecs since start
    avg_heart_rate integer check (avg_heart_rate > 0),
    heart_rate integer[], -- = millisecs since start
    route_id bigint references route on delete set null,
    comments text,
    epoch bigint not null,
    deleted boolean not null default false
);

create index cardio_session__user_id__epoch__idx
    on cardio_session (user_id, epoch) 
    where deleted = false;

create trigger set_epoch before insert or update on cardio_session
    for each row execute function set_epoch_for_user();

create table cardio_session_archive (
    primary key (id),
    foreign key (user_id) references "user" on delete cascade,
    check (deleted = true)
) inherits (cardio_session);

create trigger archive_cardio_session
    after insert or update of deleted or delete
    on cardio_session
    for each row execute procedure archive_record();
