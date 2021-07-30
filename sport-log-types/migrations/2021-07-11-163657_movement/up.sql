create type movement_category as enum('strength', 'cardio');
create type movement_unit as enum('reps', 'cal', 'meter', 'km', 'yard', 'foot', 'mile');

create table movement (
    id serial primary key,
    user_id integer references "user" on delete cascade,
    name varchar(80) not null unique,
    description text,
    category movement_category not null,
    unique (user_id, name)
);
--create index on movement (user_id, name);
insert into movement (user_id, name, description, category) values
    (null, 'Back Squat', null, 'strength'),
    (null, 'Front Squat', null, 'strength'),
    (null, 'Over Head Squat', null, 'strength'),
    (1, 'Yoke Carry', null, 'strength'),
    (null, 'Running', 'road running without significant altitude change', 'cardio'),
    (null, 'Trailrunning', null, 'cardio'),
    (null, 'Swimming Freestyle', 'indoor freestyle swimming', 'cardio'),
    (1, 'Rowing', null, 'cardio'),
    (null, 'Pull-Up', null, 'strength'),
    (null, 'Push-Up', null, 'strength'),
    (null, 'Air Squat', null, 'strength');

create table eorm (
    id serial primary key,
    reps integer not null unique check (reps >= 1),
    percentage real not null check (percentage > 0)
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