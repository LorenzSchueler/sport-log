create table strength_session (
    id bigint primary key,
    user_id bigint not null references "user" on delete cascade,
    datetime timestamptz not null default now(),
    movement_id bigint not null references movement on delete cascade,
    movement_unit movement_unit not null,
    interval integer check (interval > 0),
    comments text,
    last_change timestamptz not null default now(),
    deleted boolean not null default false
);

create unique index strength_session_idx on strength_session (user_id, datetime, movement_id) 
    where deleted = false;

create trigger set_timestamp before update on strength_session
    for each row execute procedure trigger_set_timestamp();

insert into strength_session (id, user_id, datetime, movement_id, movement_unit, interval, comments) values
    (1, 1, '2021-08-20 16:00:00', 2, 'reps', 120, null),
    (2, 1, '2021-08-22 16:00:00', 1, 'reps', null, null);

create table strength_session_archive (
    primary key (id),
    foreign key (user_id) references "user",
    check (deleted = true)
) inherits (strength_session);

create trigger archive_strength_session
    after update of deleted or delete
    on strength_session
    for each row execute procedure archive_record();

create table strength_set (
    id bigint primary key,
    strength_session_id bigint not null references strength_session on delete cascade,
    set_number integer not null check (set_number >= 0),
    count integer not null check (count >= 1), -- number of completed movement_unit
    weight real check (weight > 0),
    last_change timestamptz not null default now(),
    deleted boolean not null default false
);

create unique index strength_set_idx on strength_set (strength_session_id, set_number) 
    where deleted = false;

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

create table strength_set_archive (
    primary key (id),
    foreign key (strength_session_id) references strength_session,
    check (deleted = true)
) inherits (strength_set);

create trigger archive_strength_set
    after update of deleted or delete
    on strength_set
    for each row execute procedure archive_record();
