create type movement_unit as enum('reps', 'cal', 'meter', 'km', 'yard', 'foot', 'mile');

create table movement (
    id bigint primary key,
    user_id bigint references "user" on delete cascade,
    name varchar(80) not null,
    description text,
    cardio boolean not null,
    last_change timestamptz not null default now(),
    deleted boolean not null default false
);

create unique index movement_idx on movement (user_id, name) where deleted = false;

create trigger set_timestamp before update on movement
    for each row execute procedure trigger_set_timestamp();

insert into movement (id, user_id, name, description, cardio) values
    (1, null, 'Back Squat', null, false),
    (2, null, 'Front Squat', null, false),
    (3, null, 'Over Head Squat', null, false),
    (4, 1, 'Yoke Carry', null, false),
    (5, null, 'Running', 'road running without significant altitude change', true),
    (6, null, 'Trailrunning', null, true),
    (7, null, 'Swimming Freestyle', 'indoor freestyle swimming', true),
    (8, 1, 'Rowing', null, true),
    (9, null, 'Pull-Up', null, false),
    (10, null, 'Push-Up', null, false),
    (11, null, 'Air Squat', null, false);

create table movement_archive (
    primary key (id),
    foreign key (user_id) references "user" on delete cascade,
    check (deleted = true)
) inherits (movement);

create trigger archive_movement
    after update of deleted or delete
    on movement
    for each row execute procedure archive_record();

create table eorm (
    id bigserial primary key,
    reps integer not null check (reps >= 1),
    percentage real not null check (percentage > 0),
    unique (reps)
);

insert into eorm (reps, percentage) values
    (1, 1.0),
    (2, 0.97),
    (3, 0.94),
    (4, 0.92),
    (5, 0.89),
    (6, 0.86),
    (7, 0.83),
    (8, 0.81),
    (9, 0.78),
    (10, 0.75),
    (11, 0.73),
    (12, 0.71),
    (13, 0.70),
    (14, 0.68),
    (15, 0.67),
    (16, 0.65),
    (17, 0.64),
    (18, 0.63),
    (19, 0.61),
    (20, 0.60),
    (21, 0.59),
    (22, 0.58),
    (23, 0.57),
    (24, 0.56),
    (25, 0.55),
    (26, 0.54),
    (27, 0.53),
    (28, 0.52),
    (29, 0.51),
    (30, 0.50);