create table account (
    id serial primary key,
    username varchar(80) not null unique,
    password varchar(80) not null,
    email varchar(80) not null
);
create index on account (username);

insert into account (username, password, email) values 
    ('user1', 'passwd1', 'email1'), 
    ('user2', 'passwd2', 'email2'), 
    ('user3', 'passwd3', 'email3');