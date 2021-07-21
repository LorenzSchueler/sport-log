create table "user" (
    id serial primary key,
    username varchar(80) not null unique,
    password char(96) not null,
    email varchar(80) not null
);
create index on "user" (username);

insert into "user" (username, password, email) values 
    ('user1', 'passwd1', 'email1'), 
    ('user2', 'passwd2', 'email2'), 
    ('user3', 'passwd3', 'email3');