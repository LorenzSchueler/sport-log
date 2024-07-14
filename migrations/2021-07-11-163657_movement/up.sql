create type movement_dimension as enum('reps', 'time', 'energy', 'distance');

create table movement (
    id bigint primary key,
    user_id bigint references "user" on delete cascade,
    name varchar(80) not null check (length(name) >= 2),
    description text,
    movement_dimension movement_dimension not null,
    cardio boolean not null,
    epoch bigint not null,
    deleted boolean not null default false
);

create unique index movement__user_id__name__movement_dimension__key
    on movement (user_id, name, movement_dimension) nulls not distinct where deleted = false;

create index movement__user_id__epoch__idx
    on movement (user_id, epoch) where deleted = false;

create trigger set_epoch before insert or update on movement
    for each row execute function set_epoch_for_user();

create table movement_archive (
    primary key (id),
    foreign key (user_id) references "user" on delete cascade,
    check (deleted = true)
) inherits (movement);

create trigger archive_movement
    after insert or update of deleted or delete
    on movement
    for each row execute procedure archive_record();

create table eorm (
    id bigserial primary key,
    reps integer not null check (reps >= 1),
    percentage real not null check (percentage > 0)
);

create unique index eorm__reps__key on eorm (reps);
