create table account (
    id serial primary key,
    username varchar(80) not null unique,
    password varchar(80) not null,
    email varchar(80) not null
);
create index on account (username);