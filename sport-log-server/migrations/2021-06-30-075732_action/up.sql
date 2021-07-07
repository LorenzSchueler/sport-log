create type weekday as enum('monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday');

create table action_provider (
    id serial primary key,
    name varchar(80) not null unique,
    password varchar(80) not null,
    platform_id integer not null references platform on delete cascade
);
insert into action_provider (name, password, platform_id) values
    ('wodify-login', 'wodify-login-passwd', 1),
    ('wodify-wod', 'wodify-wod-passwd', 1),
    ('sportstracker-fetch', 'sportstracker-fetch-passwd', 2);

create table action (
    id serial primary key,
    name varchar(80) not null,
    action_provider_id integer not null references action_provider on delete cascade,
    unique (action_provider_id, name)
);
insert into action (name, action_provider_id) values 
    ('Crossfit', 1), 
    ('Weightlifting', 1), 
    ('Open Fridge', 1),
    ('fetch', 3);

create table action_rule (
    id serial primary key,
    user_id integer not null references "user" on delete cascade,
    action_id integer not null references action on delete cascade,
    weekday weekday not null, 
    time time not null,
    enabled boolean not null,
    unique (user_id, action_id, weekday, time, enabled)
);
insert into action_rule (user_id, action_id, weekday, time, enabled) values 
    (1, 1, 'monday', '09:00:00', true), 
    (1, 3, 'tuesday', '19:00:00', true);

create table action_event (
    id serial primary key,
    user_id integer not null references "user" on delete cascade,
    action_id integer not null references action on delete cascade,
    datetime timestamp not null,
    enabled boolean not null,
    unique (user_id, action_id, datetime, enabled)
);
insert into action_event (user_id, action_id, datetime, enabled) values 
    (1, 1, '2021-07-01 09:00:00', true), 
    (1, 1, '2021-07-02 09:00:00', true), 
    (1, 1, '2021-07-03 09:00:00', true), 
    (1, 3, '2021-07-04 19:00:00', false), 
    (2, 1, '2021-07-01 09:00:00', true), 
    (2, 2, '2021-07-02 09:00:00', true), 
    (2, 1, '2021-07-03 09:00:00', true), 
    (2, 2, '2021-07-04 19:00:00', false);
