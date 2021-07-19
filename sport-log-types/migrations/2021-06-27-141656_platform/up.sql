create table platform (
    id serial primary key,
    name varchar(80) not null unique
);
insert into platform (name) values 
    ('wodify'),
    ('sportstracker');

create table platform_credentials (
    id serial primary key,
    user_id integer not null references "user" on delete cascade,
    platform_id integer not null references platform on delete cascade,
    username varchar(80) not null,
    password varchar(80) not null,
    unique (user_id, platform_id)
);
insert into platform_credentials (user_id, platform_id, username, password) values
    (1, 1, 'woduser1', 'wodpasswd1'),
    (2, 1, 'woduser2', 'wodpasswd2'),
    (3, 2, 'stuser3', 'stpasswd3');