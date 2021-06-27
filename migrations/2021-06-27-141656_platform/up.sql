create table platform (
    id serial primary key,
    name varchar(80) not null unique
);

insert into platform (name) values ('wodify');

create table platform_credentials (
    id serial primary key,
    account_id integer not null references account on delete cascade,
    platform_id integer not null references platform on delete cascade,
    username varchar(80) not null,
    password varchar(80) not null,
    unique (account_id, platform_id)
);