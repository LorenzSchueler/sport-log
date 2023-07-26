create type movement_dimension as enum('reps', 'time', 'energy', 'distance');

create table movement (
    id bigint primary key,
    user_id bigint references "user" on delete cascade,
    name varchar(80) not null check (length(name) >= 2),
    description text,
    movement_dimension movement_dimension not null,
    cardio boolean not null,
    last_change timestamptz not null default now(),
    deleted boolean not null default false
);

create unique index movement__user_id__name__movement_dimension__key
    on movement (user_id, name, movement_dimension) nulls not distinct where deleted = false;

create index movement__user_id__last_change__idx
    on movement (user_id, last_change) where deleted = false;

create trigger set_timestamp before update on movement
    for each row execute procedure trigger_set_timestamp();

create table movement_archive (
    primary key (id),
    foreign key (user_id) references "user" on delete cascade,
    check (deleted = true)
) inherits (movement);

create trigger archive_movement
    after insert or update of deleted or delete
    on movement
    for each row execute procedure archive_record_movement();

create trigger delete_movement_archive
    after delete
    on movement_archive
    for each row execute procedure delete_record_movement();

create table muscle_group (
    id bigint primary key,
    name varchar(80) not null check (length(name) >= 2),
    description text
);

create table movement_muscle (
    id bigint primary key,
    movement_id bigint not null references movement on delete cascade,
    muscle_group_id bigint not null references muscle_group on delete cascade,
    last_change timestamptz not null default now(),
    deleted boolean not null default false
);

create trigger set_timestamp before update on movement_muscle
    for each row execute procedure trigger_set_timestamp();

create table movement_muscle_archive (
    primary key (id),
    check (deleted = true)
) inherits (movement_muscle);

create trigger archive_movement_muscle
    after insert or update of deleted or delete
    on movement_muscle
    for each row execute procedure archive_record();

create trigger check_movement_exists_trigger
    after insert 
    on movement_muscle_archive
    for each row execute procedure check_movement_exists();

create table eorm (
    id bigserial primary key,
    reps integer not null check (reps >= 1),
    percentage real not null check (percentage > 0)
);

create unique index eorm__reps__key on eorm (reps);
