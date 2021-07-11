create type movement_category as enum('strength', 'cardio');
create type movement_unit as enum('reps', 'cal', 'meter', 'km', 'yard', 'foot', 'mile');

create table movement (
    id serial primary key,
    user_id integer not null references "user" on delete cascade,
    name varchar(80) not null unique,
    description text,
    category movement_category not null,
    unique (user_id, name)
);
--create index on movement (user_id, name);

create table e1rm (
    id serial primary key,
    reps integer not null unique,
    percentage float not null
);