create table diary (
    id bigint primary key,
    user_id bigint not null references "user" on delete cascade,
    date date not null default now()::date,
    bodyweight real check (bodyweight > 0),
    comments text,
    last_change timestamptz not null default now(),
    deleted boolean not null default false
);

create unique index diary__user_id__date__key
    on diary (user_id, date) where deleted = false;

create index diary__user_id__last_change__idx
    on diary (user_id, last_change) where deleted = false;

create trigger set_timestamp before update on diary
    for each row execute procedure trigger_set_timestamp();

create table diary_archive (
    primary key (id),
    foreign key (user_id) references "user" on delete cascade,
    check (deleted = true)
) inherits (diary);

create trigger archive_diary
    after insert or update of deleted or delete
    on diary
    for each row execute procedure archive_record();

create table wod (
    id bigint primary key,
    user_id bigint not null references "user" on delete cascade,
    date date not null default now()::date,
    description text,
    last_change timestamptz not null default now(),
    deleted boolean not null default false
);

create unique index wod__user_id__date__key
    on wod (user_id, date) where deleted = false;

create index wod__user_id__last_change__idx
    on wod (user_id, last_change) where deleted = false;

create trigger set_timestamp before update on wod
    for each row execute procedure trigger_set_timestamp();

create table wod_archive (
    primary key (id),
    foreign key (user_id) references "user" on delete cascade,
    check (deleted = true)
) inherits (wod);

create trigger archive_wod
    after insert or update of deleted or delete
    on wod
    for each row execute procedure archive_record();
