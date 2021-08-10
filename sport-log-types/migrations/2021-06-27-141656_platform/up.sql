create table platform (
    id bigint primary key,
    name varchar(80) not null check (length(name) > 2),
    last_change timestamptz not null default now(),
    deleted boolean not null default false,
    unique (name, deleted)
);

create trigger set_timestamp before update on platform
    for each row execute procedure trigger_set_timestamp();

insert into platform (id, name) values 
    (1, 'wodify'),
    (2, 'sportstracker');

create table platform_credential (
    id bigint primary key,
    user_id bigint not null references "user" on delete cascade,
    platform_id bigint not null references platform on delete cascade,
    username varchar(80) not null,
    password varchar(80) not null,
    last_change timestamptz not null default now(),
    deleted boolean not null default false,
    unique (user_id, platform_id, deleted)
);

create trigger set_timestamp before update on platform_credential
    for each row execute procedure trigger_set_timestamp();

insert into platform_credential (id, user_id, platform_id, username, password) values
    (1, 1, 1, 'woduser1', 'wodpasswd1'),
    (2, 2, 1, 'woduser2', 'wodpasswd2'),
    (3, 3, 2, 'stuser3', 'stpasswd3');