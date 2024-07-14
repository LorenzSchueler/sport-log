create table strength_session (
    id bigint primary key,
    user_id bigint not null references "user" on delete cascade,
    datetime timestamptz not null default now(),
    movement_id bigint not null references movement on delete cascade,
    interval integer check (interval > 0), -- milliseconds
    comments text,
    epoch bigint not null,
    deleted boolean not null default false
);

create index strength_session__user_id__epoch__idx
    on strength_session (user_id, epoch) 
    where deleted = false;

create trigger set_epoch before insert or update on strength_session
    for each row execute function set_epoch_for_user();

create table strength_session_archive (
    primary key (id),
    foreign key (user_id) references "user" on delete cascade,
    check (deleted = true)
) inherits (strength_session);

create trigger archive_strength_session
    after insert or update of deleted or delete
    on strength_session
    for each row execute procedure archive_record();

create table strength_set (
    id bigint primary key,
    user_id bigint not null references "user" on delete cascade,
    strength_session_id bigint not null references strength_session on delete cascade,
    set_number integer not null check (set_number >= 0),
    count integer not null check (count >= 1),
    weight real check (weight > 0),
    epoch bigint not null,
    deleted boolean not null default false
);

create unique index strength_set__strength_session_id__set_number__key on strength_set (strength_session_id, set_number) 
    where deleted = false;

create index strength_set__user_id__epoch__idx
    on strength_set (user_id, epoch) 
    where deleted = false;

create trigger set_epoch before insert or update on strength_set
    for each row execute function set_epoch_for_user();

create table strength_set_archive (
    primary key (id),
    check (deleted = true)
) inherits (strength_set);

create trigger archive_strength_set
    after insert or update of deleted or delete
    on strength_set
    for each row execute procedure archive_record();
