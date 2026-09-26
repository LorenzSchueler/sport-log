create table diary (
    id bigint primary key,
    user_id bigint not null references "user" on delete cascade,
    date date not null default now()::date,
    bodyweight real check (bodyweight > 0),
    comments text,
    epoch bigint not null,
    deleted boolean not null default false
);

create unique index diary__user_id__date__key
    on diary (user_id, date) where deleted = false;

create index diary__user_id__epoch__idx
    on diary (user_id, epoch) where deleted = false;

create trigger set_epoch before insert or update on diary
    for each row execute function set_epoch();

create table diary_archive (
    primary key (id),
    foreign key (user_id) references "user" on delete cascade,
    check (deleted = true)
) inherits (diary);

create trigger delete_soft_deleted_diary
    after insert or update of deleted
    on diary
    for each row execute procedure delete_soft_deleted_record();

create trigger mark_deleted_and_archive_diary
    before delete
    on diary
    for each row execute procedure mark_deleted_and_archive_record();

create table wod (
    id bigint primary key,
    user_id bigint not null references "user" on delete cascade,
    date date not null default now()::date,
    description text,
    epoch bigint not null,
    deleted boolean not null default false
);

create unique index wod__user_id__date__key
    on wod (user_id, date) where deleted = false;

create index wod__user_id__epoch__idx
    on wod (user_id, epoch) where deleted = false;

create trigger set_epoch before insert or update on wod
    for each row execute function set_epoch();

create table wod_archive (
    primary key (id),
    foreign key (user_id) references "user" on delete cascade,
    check (deleted = true)
) inherits (wod);

create trigger delete_soft_deleted_wod
    after insert or update of deleted
    on wod
    for each row execute procedure delete_soft_deleted_record();

create trigger mark_deleted_and_archive_wod
    before delete
    on wod
    for each row execute procedure mark_deleted_and_archive_record();
