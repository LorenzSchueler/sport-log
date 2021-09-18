create table training_plan (
    id bigint primary key,
    user_id bigint not null references "user" on delete cascade,
    name varchar(80) not null,
    description text,
    date date,
    weekday weekday,
    last_change timestamptz not null default now(),
    deleted boolean not null default false
);
