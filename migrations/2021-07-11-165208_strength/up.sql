create table strength_blueprint (
    id bigint primary key,
    user_id bigint not null references "user" on delete cascade,
    training_plan_id bigint not null references training_plan on delete cascade,
    name varchar(80),
    description text,
    movement_id bigint not null references movement on delete cascade,
    interval integer check (interval > 0), -- milliseconds
    last_change timestamptz not null default now(),
    deleted boolean not null default false
);

create index strength_blueprint__user_id__last_change__idx
    on strength_blueprint (user_id, last_change) where deleted = false;

create trigger set_timestamp before update on strength_blueprint
    for each row execute procedure trigger_set_timestamp();

create table strength_blueprint_archive (
    primary key (id),
    foreign key (user_id) references "user" on delete cascade,
    check (deleted = true)
) inherits (strength_blueprint);

create trigger archive_strength_blueprint
    after insert or update of deleted or delete
    on strength_blueprint
    for each row execute procedure archive_record_strength_blueprint();

create trigger delete_strength_blueprint_archive
    after delete
    on strength_blueprint_archive
    for each row execute procedure delete_record_strength_blueprint();

create table strength_blueprint_set (
    id bigint primary key,
    strength_blueprint_id bigint not null references strength_blueprint on delete cascade,
    set_number integer not null check (set_number >= 0),
    count integer not null check (count >= 1),
    weight real check (weight > 0),
    last_change timestamptz not null default now(),
    deleted boolean not null default false
);

create unique index strength_blueprint_set__strength_blueprint_id__set_number__key
    on strength_blueprint_set (strength_blueprint_id, set_number) 
    where deleted = false;

create trigger set_timestamp before update on strength_blueprint_set
    for each row execute procedure trigger_set_timestamp();

create table strength_blueprint_set_archive (
    primary key (id),
    check (deleted = true)
) inherits (strength_blueprint_set);

create trigger archive_strength_blueprint_set
    after insert or update of deleted or delete
    on strength_blueprint_set
    for each row execute procedure archive_record();

create trigger check_strength_blueprint_exists_trigger
    after insert 
    on strength_blueprint_set_archive
    for each row execute procedure check_strength_blueprint_exists();

create table strength_session (
    id bigint primary key,
    user_id bigint not null references "user" on delete cascade,
    strength_blueprint_id bigint references strength_blueprint on delete set null,
    datetime timestamptz not null default now(),
    movement_id bigint not null references movement on delete cascade,
    interval integer check (interval > 0), -- milliseconds
    comments text,
    last_change timestamptz not null default now(),
    deleted boolean not null default false
);

create unique index strength_session__user_id__datetime__movement_id__key
    on strength_session (user_id, datetime, movement_id) 
    where deleted = false;

create index strength_session__user_id__last_change__idx
    on strength_session (user_id, last_change) 
    where deleted = false;

create trigger set_timestamp before update on strength_session
    for each row execute procedure trigger_set_timestamp();

create table strength_session_archive (
    primary key (id),
    foreign key (user_id) references "user" on delete cascade,
    check (deleted = true)
) inherits (strength_session);

create trigger archive_strength_session
    after insert or update of deleted or delete
    on strength_session
    for each row execute procedure archive_record_strength_session();

create trigger delete_strength_session_archive
    after delete
    on strength_session_archive
    for each row execute procedure delete_record_strength_session();

create table strength_set (
    id bigint primary key,
    strength_session_id bigint not null references strength_session on delete cascade,
    set_number integer not null check (set_number >= 0),
    count integer not null check (count >= 1),
    weight real check (weight > 0),
    last_change timestamptz not null default now(),
    deleted boolean not null default false
);

create unique index strength_set_idx on strength_set (strength_session_id, set_number) 
    where deleted = false;

create trigger set_timestamp before update on strength_set
    for each row execute procedure trigger_set_timestamp();

create table strength_set_archive (
    primary key (id),
    check (deleted = true)
) inherits (strength_set);

create trigger archive_strength_set
    after insert or update of deleted or delete
    on strength_set
    for each row execute procedure archive_record();

create trigger check_strength_session_exists_trigger
    after insert 
    on strength_set_archive
    for each row execute procedure check_strength_session_exists();
