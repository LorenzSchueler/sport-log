create table diary (
    id bigint primary key,
    user_id integer not null references "user" on delete cascade,
    date date not null default now()::date,
    bodyweight real check (bodyweight > 0),
    comments text,
    last_change timestamptz not null default now(),
    deleted boolean not null default false,
    unique (user_id, date, deleted)
);

create trigger set_timestamp before update on diary
    for each row execute procedure trigger_set_timestamp();

insert into diary (id, user_id, date, bodyweight, comments) values
    (1, 1, '2021-08-20', 78.3, null),
    (2, 1, '2021-08-21', 78.8, null),
    (3, 1, '2021-08-22', 78.2, null),
    (4, 1, '2021-08-23', 77.9, null),
    (5, 1, '2021-08-24', 78.3, null);

create table wod (
    id bigint primary key,
    user_id integer not null references "user" on delete cascade,
    date date not null default now()::date,
    description text,
    last_change timestamptz not null default now(),
    deleted boolean not null default false,
    unique (user_id, date, deleted)
);

create trigger set_timestamp before update on wod
    for each row execute procedure trigger_set_timestamp();

insert into wod (id, user_id, date, description) values
    (1, 1, '2021-08-20', E'Strength:\nBack Squat 5*5\n\nFor Time (5 rounds):\n15 cal Ski Erg\n15 Dumbbell Snatch (45/30)'),
    (2, 1, '2021-08-21', E'Murph'),
    (3, 1, '2021-08-22', E'Cindy\n20 min AMRAP:\n5 Pull-Ups\n10 Push-Ups\n15 Air Squats'),
    (4, 1, '2021-08-23', E''),
    (5, 1, '2021-08-24', E'Deadlift 8x2\nSkill: Clean & Jerk');
