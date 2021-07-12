create table strength_session (
    id serial primary key,
    user_id integer not null references "user" on delete cascade,
    datetime timestamp not null default now(),
    movement_id integer not null references movement on delete no action,
    movement_unit movement_unit not null,
    interval integer,
    comments text
);
--create index on strength_session (user_id, datetime desc);

create table strength_set (
    id serial primary key,
    strength_session_id integer not null references strength_session on delete cascade,
    count integer not null, -- accourding to session movement_unit
    weight float
    --effort effort
);