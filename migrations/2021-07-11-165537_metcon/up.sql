create type metcon_type as enum('amrap', 'emom', 'for_time');
create type distance_unit as enum('meter', 'km', 'yard', 'foot', 'mile');

create table metcon (
    id bigint primary key,
    user_id bigint references "user" on delete cascade,
    name varchar(80) not null,
    metcon_type metcon_type not null,
    rounds integer check (rounds >= 1),
    timecap integer check (timecap > 0), -- milliseconds
    description text,
    last_change timestamptz not null default now(),
    deleted boolean not null default false
);

create unique index metcon_idx on metcon (user_id, name) where deleted = false;

create trigger set_timestamp before update on metcon
    for each row execute procedure trigger_set_timestamp();

insert into metcon (id, user_id, name, metcon_type, rounds, timecap, description) values
    (1, null, 'Cindy', 'amrap', null, 1200000, null),
    (2, null, 'Murph', 'for_time', 1, null, 'wear a weight vest (20/14) lbs'),
    (3, 1, '5k Row', 'for_time', 1, 1800000, null);

create table metcon_archive (
    primary key (id),
    foreign key (user_id) references "user" on delete cascade,
    check (deleted = true)
) inherits (metcon);

create trigger archive_metcon
    after insert or update of deleted or delete
    on metcon
    for each row execute procedure archive_record_metcon();

create trigger delete_metcon_archive
    after delete
    on metcon_archive
    for each row execute procedure delete_record_metcon();

create table metcon_movement (
    id bigint primary key,
    metcon_id bigint not null references metcon on delete cascade,
    movement_id bigint not null references movement on delete cascade,
    distance_unit distance_unit,
    movement_number integer not null check (movement_number >= 0),
    count integer not null check (count >= 1),
    male_weight real check (male_weight > 0),
    female_weight real check (female_weight > 0),
    last_change timestamptz not null default now(),
    deleted boolean not null default false
);

create unique index metcon_movement_idx on metcon_movement (metcon_id, movement_number)     
    where deleted = false;

create trigger set_timestamp before update on metcon_movement
    for each row execute procedure trigger_set_timestamp();

insert into metcon_movement (id, metcon_id, movement_id, distance_unit, movement_number, count, male_weight, female_weight) values
    (1, 1, 10, null, 0, 5, null, null),
    (2, 1, 11, null, 1, 10, null, null),
    (3, 1, 12, null, 2, 15, null, null),
    (4, 2, 5, null, 0, 1, 9, 6),
    (5, 2, 10, null, 1, 100, 9, 6),
    (6, 2, 11, null, 2, 200, 9, 6),
    (7, 2, 12, null, 3, 300, 9, 6),
    (8, 2, 5, null, 4, 1, 9, 6),
    (9, 3, 8, 'km', 0, 5, null, null);

create table metcon_movement_archive (
    primary key (id),
    check (deleted = true)
) inherits (metcon_movement);

create trigger archive_metcon_movement
    after insert or update of deleted or delete
    on metcon_movement
    for each row execute procedure archive_record();

create trigger check_metcon_exists_trigger
    after insert 
    on metcon_movement_archive
    for each row execute procedure check_metcon_exists();

create table metcon_session (
    id bigint primary key,
    user_id bigint not null references "user" on delete cascade,
    metcon_id bigint not null references metcon on delete cascade,
    datetime timestamptz not null default now(),
    time integer check (time > 0), -- milliseconds
    rounds integer check (rounds >= 0),
    reps integer check (reps >= 0),
    rx boolean not null default true,
    comments text,
    last_change timestamptz not null default now(),
    deleted boolean not null default false
);

create unique index metcon_session_idx on metcon_session (user_id, metcon_id, datetime)     
    where deleted = false;

create trigger set_timestamp before update on metcon_session
    for each row execute procedure trigger_set_timestamp();

insert into metcon_session (id, user_id, metcon_id, datetime, time, rounds, reps, rx, comments) values
    (1, 1, 1, '2020-08-20 16:00:00', null, 17, 8, true, null),
    (2, 1, 2, '2020-08-23 18:00:00', 1800000, null, null, false, 'without vest');

create table metcon_session_archive (
    primary key (id),
    foreign key (user_id) references "user" on delete cascade,
    check (deleted = true)
) inherits (metcon_session);

create trigger archive_metcon_session
    after insert or update of deleted or delete
    on metcon_session
    for each row execute procedure archive_record();

create table metcon_item (
    id bigint primary key,
    training_plan_id bigint not null references training_plan on delete cascade,
    metcon_id bigint not null references metcon on delete cascade,
    last_change timestamptz not null default now(),
    deleted boolean not null default false
);

create trigger set_timestamp before update on metcon_item
    for each row execute procedure trigger_set_timestamp();

create table metcon_item_archive (
    primary key (id),
    check (deleted = true)
) inherits (metcon_item);

create trigger archive_metcon_item
    after insert or update of deleted or delete
    on metcon_item
    for each row execute procedure archive_record();

create trigger check_metcon_exists_trigger
    after insert 
    on metcon_item_archive
    for each row execute procedure check_metcon_exists();
