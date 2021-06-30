create type weekday as enum('monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday');

create table action (
    id serial primary key,
    platform_id integer not null references platform on delete cascade,
    name varchar(80) not null,
    unique (platform_id, name)
);
insert into action (platform_id, name) values (1, 'crossfit'), (1, 'weightlifting'), (1, 'open fridge');

create table action_rule (
    id serial primary key,
    account_id integer not null references account on delete cascade,
    action_id integer not null references action on delete cascade,
    weekday weekday not null, 
    time time not null,
    enabled boolean not null,
    unique (account_id, action_id, weekday, time, enabled)
);
insert into action_rule (account_id, action_id, weekday, time, enabled) values (1, 1, 'monday', '09:00:00', true), (1, 3, 'tuesday', '19:00:00', true);

create table action_event (
    id serial primary key,
    account_id integer not null references account on delete cascade,
    action_id integer not null references action on delete cascade,
    datetime timestamp not null,
    enabled boolean not null,
    unique (account_id, action_id, datetime, enabled)
);
insert into action_event (account_id, action_id, datetime, enabled) values (1, 1, '2021-07-01 09:00:00', true), (1, 3, '2021-07-02 19:00:00', false);