create type weekday as enum('monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday');

create table action_provider (
    id bigint primary key,
    name varchar(80) not null check (length(name) >= 2),
    password char(96) not null,
    platform_id bigint not null references platform on delete cascade,
    description text,
    last_change timestamptz not null default now(),
    deleted boolean not null default false
);

create unique index action_provider_idx on action_provider (name) where deleted = false;

create trigger set_timestamp before update on action_provider
    for each row execute procedure trigger_set_timestamp();

insert into action_provider (id, name, password, platform_id, description) values
    (1, 'wodify-login', '$argon2id$v=19$m=4096,t=3,p=1$NZeOJg1K37UlxV5wB7yFhg$C7HNfVK9yLZTJyvJNSOhvYRfUK+nGo1rz0lIck1aO6c', 1, 
        'Wodify Login can reserve spots in classes. The action names correspond to the class types.'), -- "wodify-login-passwd"
    (2, 'wodify-wod', '$argon2id$v=19$m=4096,t=3,p=1$FscunZHcMdL3To4Zxc5z5w$InsqwdstEFdkszaokG1rk0HS0oazMm4zTynD6pjQEgw', 1,  
        'Wodify Wod can fetch the Workout of the Day and save it in your wods. The action names correspond to the class type the wod should be fetched for.'), -- "wodify-wod-passwd"
    (3, 'sportstracker-fetch', '$argon2id$v=19$m=4096,t=3,p=1$mmRowryKPKBhRSvrRZRFmg$VPInpHpMq47ZEymwSojrst+CWVOoHopBlvSIwybchAg', 2,  
        'Sportstracker Fetch can fetch the latests workouts recorded with sportstracker and save them in your cardio sessions.'); -- "sportstracker-fetch-passwd"

create table action (
    id bigint primary key,
    name varchar(80) not null check (length(name) >= 2),
    action_provider_id bigint not null references action_provider on delete cascade,
    description text,
    create_before integer not null check (create_before >= 0), -- hours
    delete_after integer not null check (delete_after >= 0), --hours
    last_change timestamptz not null default now(),
    deleted boolean not null default false
);

create unique index action_idx on action (action_provider_id, name) where deleted = false;

create trigger set_timestamp before update on action
    for each row execute procedure trigger_set_timestamp();

insert into action (id, name, action_provider_id, description, create_before, delete_after) values 
    (1, 'CrossFit', 1, 'Reserve a spot in a CrossFit class.', 168, 0), 
    (2, 'Weightlifting', 1, 'Reserve a spot in a Weightlifting class.', 168, 0), 
    (3, 'Open Fridge', 1, 'Reserve a spot in a Open Fridge class.', 168, 0),
    (4, 'CrossFit', 2, 'Fetch and save the CrossFit wod for the current day.', 168, 0), 
    (5, 'Weightlifting', 2, 'Fetch and save the Weightlifting wod for the current day.', 168, 0), 
    (6, 'Open Fridge', 2, 'Fetch and save the Open Fridge wod for the current day.', 168, 0), 
    (7, 'fetch', 3, 'Fetch and save new workouts.', 168, 0);

create table action_archive (
    primary key (id),
    check (deleted = true)
) inherits (action);

create trigger archive_action
    after update of deleted or delete
    on action
    for each row execute procedure archive_record();

create table action_rule (
    id bigint primary key,
    user_id bigint not null references "user" on delete cascade,
    action_id bigint not null references action on delete cascade,
    weekday weekday not null, 
    time timestamptz not null,
    arguments text,
    enabled boolean not null,
    last_change timestamptz not null default now(),
    deleted boolean not null default false
);

create unique index action_rule_idx on action_rule (user_id, action_id, weekday, time) 
    where deleted = false;

create trigger set_timestamp before update on action_rule
    for each row execute procedure trigger_set_timestamp();

insert into action_rule (id, user_id, action_id, weekday, time, enabled) values 
    (1, 1, 1, 'monday', '1970-01-01 09:00:00', true), 
    (2, 1, 3, 'tuesday', '1970-01-01 19:00:00', true),
    (3, 1, 4, 'monday', '1970-01-01 00:00:00', true),
    (4, 1, 4, 'tuesday', '1970-01-01 00:00:00', true),
    (5, 1, 4, 'wednesday', '1970-01-01 00:00:00', true),
    (6, 1, 4, 'thursday', '1970-01-01 00:00:00', true),
    (8, 1, 4, 'friday', '1970-01-01 00:00:00', true),
    (9, 1, 4, 'saturday', '1970-01-01 00:00:00', true),
    (10, 1, 4, 'sunday', '1970-01-01 00:00:00', true);

create table action_rule_archive (
    primary key (id),
    foreign key (user_id) references "user" on delete cascade,
    check (deleted = true)
) inherits (action_rule);

create trigger archive_action_rule
    after update of deleted or delete
    on action_rule
    for each row execute procedure archive_record();

create table action_event (
    id bigint primary key,
    user_id bigint not null references "user" on delete cascade,
    action_id bigint not null references action on delete cascade,
    datetime timestamptz not null,
    arguments text,
    enabled boolean not null,
    last_change timestamptz not null default now(),
    deleted boolean not null default false
);

create unique index action_event_idx on action_event (user_id, action_id, datetime)
    where deleted = false;

create trigger set_timestamp before update on action_event
    for each row execute procedure trigger_set_timestamp();

insert into action_event (id, user_id, action_id, datetime, enabled) values 
    (1, 1, 1, '2021-07-01 09:00:00', true), 
    (2, 1, 3, '2021-07-04 19:00:00', false), 
    (3, 2, 1, '2021-07-01 09:00:00', true), 
    (4, 2, 2, '2021-07-02 09:00:00', true), 
    (5, 2, 2, '2021-07-04 19:00:00', false),
    (6, 1, 4, '2021-08-29 00:00:00', true), 
    (7, 1, 4, '2021-08-30 00:00:00', true), 
    (8, 1, 7, '2021-07-01 09:00:00', true), 
    (9, 3, 7, '2021-07-01 11:00:00', true); 

create table action_event_archive (
    primary key (id),
    foreign key (user_id) references "user" on delete cascade,
    check (deleted = true)
) inherits (action_event);

create trigger archive_action_event
    after update of deleted or delete
    on action_event
    for each row execute procedure archive_record();
