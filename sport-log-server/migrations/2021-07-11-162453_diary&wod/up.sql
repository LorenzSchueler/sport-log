create table diary (
    id serial primary key,
    user_id integer not null references "user" on delete cascade,
    date date not null default now()::date,
    bodyweight real,
    comments text,
    unique (user_id, date)
);
--create index on diary (account_id, date desc);

create table wod (
    id serial primary key,
    user_id integer not null references "user" on delete cascade,
    datetime timestamp not null default now(),
    description text,
    unique (user_id, datetime)
);
--create index on wod (user_id, datetime desc);
