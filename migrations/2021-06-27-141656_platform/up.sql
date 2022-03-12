create table platform (
    id bigint primary key,
    name varchar(80) not null check (length(name) > 2),
    credential boolean not null,
    last_change timestamptz not null default now(),
    deleted boolean not null default false
);

create unique index platform_idx on platform (name) where deleted = false;

create trigger set_timestamp before update on platform
    for each row execute procedure trigger_set_timestamp();

create table platform_archive (
    primary key (id),
    check (deleted = true)
) inherits (platform);

create trigger archive_platform
    after insert or update of deleted or delete
    on platform
    for each row execute procedure archive_record();

create table platform_credential (
    id bigint primary key,
    user_id bigint not null references "user" on delete cascade,
    platform_id bigint not null references platform on delete cascade,
    username varchar(80) not null,
    password varchar(80) not null,
    last_change timestamptz not null default now(),
    deleted boolean not null default false
);

create unique index platform_credential_idx on platform_credential (user_id, platform_id) where deleted = false;

create trigger set_timestamp before update on platform_credential
    for each row execute procedure trigger_set_timestamp();

create table platform_credential_archive (
    primary key (id),
    foreign key (user_id) references "user" on delete cascade,
    check (deleted = true)
) inherits (platform_credential);

create trigger archive_platform_credential
    after insert or update of deleted or delete
    on platform_credential
    for each row execute procedure archive_record();
