create table "group" (
    id serial primary key,
    name varchar(80) not null
);

create table group_user (
    id serial primary key,
    group_id integer not null references "group" on delete cascade,
    user_id integer not null references "user" on delete cascade
);

create table shared_metcon_session (
    id serial primary key,
    group_id integer not null references "group" on delete cascade,
    metcon_session_id integer not null references metcon_session on delete cascade
);

create table shared_strength_session (
    id serial primary key,
    group_id integer not null references "group" on delete cascade,
    strength_session_id integer not null references strength_session on delete cascade
);

create table shared_cardio_session (
    id serial primary key,
    group_id integer not null references "group" on delete cascade,
    cardio_session_id integer not null references cardio_session on delete cascade
);

create table shared_diary (
    id serial primary key,
    group_id integer not null references "group" on delete cascade,
    diary_id integer not null references diary on delete cascade
);