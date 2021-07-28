create table diary (
    id serial primary key,
    user_id integer not null references "user" on delete cascade,
    date date not null default now()::date,
    bodyweight real,
    comments text,
    unique (user_id, date)
);
--create index on diary (user_id, date desc);

insert into diary (user_id, date, bodyweight, comments) values
    (1, '2021-08-20', 78.3, null),
    (1, '2021-08-21', 78.8, null),
    (1, '2021-08-22', 78.2, null),
    (1, '2021-08-23', 77.9, null),
    (1, '2021-08-24', 78.3, null);

create table wod (
    id serial primary key,
    user_id integer not null references "user" on delete cascade,
    date date not null default now()::date,
    description text,
    unique (user_id, date)
);
--create index on wod (user_id, datetime desc);

insert into wod (user_id, date, description) values
    (1, '2021-08-20', E'Strength:\nBack Squat 5*5\n\nFor Time (5 rounds):\n15 cal Ski Erg\n15 Dumbbell Snatch (45/30)'),
    (1, '2021-08-21', E'Murph'),
    (1, '2021-08-22', E'Cindy\n20 min AMRAP:\n5 Pull-Ups\n10 Push-Ups\n15 Air Squats'),
    (1, '2021-08-23', E''),
    (1, '2021-08-24', E'Deadlift 8x2\nSkill: Clean & Jerk');
