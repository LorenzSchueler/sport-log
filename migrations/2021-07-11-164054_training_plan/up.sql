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

create index training_plan__user_id__last_change__idx
    on training_plan (user_id, last_change) where deleted = false;

create trigger set_timestamp before update on training_plan
    for each row execute procedure trigger_set_timestamp();

create table training_plan_archive (
    primary key (id),
    foreign key (user_id) references "user" on delete cascade,
    check (deleted = true)
) inherits (training_plan);

create trigger archive_training_plan
    after insert or update of deleted or delete
    on training_plan
    for each row execute procedure archive_record();
