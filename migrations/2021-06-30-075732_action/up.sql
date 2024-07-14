create type weekday as enum('monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday');

create table action_provider (
    id bigint primary key,
    name varchar(80) not null check (length(name) >= 2),
    password varchar(120) not null,
    platform_id bigint not null references platform on delete cascade,
    description text,
    epoch bigint not null,
    deleted boolean not null default false
);

create unique index action_provider__name__key on action_provider (name) where deleted = false;

create trigger set_epoch before insert or update on action_provider
    for each row execute function set_epoch();

create table action_provider_archive (
    primary key (id),
    check (deleted = true)
) inherits (action_provider);

create trigger archive_action_provider
    after insert or update of deleted or delete
    on action_provider
    for each row execute procedure archive_record();

create table action (
    id bigint primary key,
    name varchar(80) not null check (length(name) >= 2),
    action_provider_id bigint not null references action_provider on delete cascade,
    description text,
    create_before integer not null check (create_before >= 0), -- milliseconds
    delete_after integer not null check (delete_after >= 0), --milliseconds
    epoch bigint not null,
    deleted boolean not null default false
);

create unique index action__action_provider_id__key
    on action (action_provider_id, name) where deleted = false;

create trigger set_epoch before insert or update on action
    for each row execute function set_epoch();

create table action_archive (
    primary key (id),
    check (deleted = true)
) inherits (action);

create trigger archive_action
    after insert or update of deleted or delete
    on action
    for each row execute procedure archive_record();

create table action_rule (
    id bigint primary key,
    user_id bigint not null references "user" on delete cascade,
    action_id bigint not null references action on delete cascade,
    weekday weekday not null, 
    time timestamptz not null,
    arguments text,
    enabled boolean not null,
    epoch bigint not null,
    deleted boolean not null default false
);

create unique index action_rule__user_id__action_id__weekday__time__key
    on action_rule (user_id, action_id, weekday, time) 
    where deleted = false;

create index action_rule__user_id__epoch__idx
    on action_rule (user_id, epoch) 
    where deleted = false;

create trigger set_epoch before insert or update on action_rule
    for each row execute function set_epoch_for_user();

create table action_rule_archive (
    primary key (id),
    foreign key (user_id) references "user" on delete cascade,
    check (deleted = true)
) inherits (action_rule);

create trigger archive_action_rule
    after insert or update of deleted or delete
    on action_rule
    for each row execute procedure archive_record();

create table action_event (
    id bigint primary key,
    user_id bigint not null references "user" on delete cascade,
    action_id bigint not null references action on delete cascade,
    datetime timestamptz not null,
    arguments text,
    enabled boolean not null,
    epoch bigint not null,
    deleted boolean not null default false
);

create unique index action_event__user_id__action_id__datetime__key
    on action_event (user_id, action_id, datetime)
    where deleted = false;

create index action_event__user_id__epoch__idx
    on action_event (user_id, epoch)
    where deleted = false;

create trigger set_epoch before insert or update on action_event
    for each row execute function set_epoch_for_user();

create table action_event_archive (
    primary key (id),
    foreign key (user_id) references "user" on delete cascade,
    check (deleted = true)
) inherits (action_event);

create trigger archive_action_event
    after insert or update of deleted or delete
    on action_event
    for each row execute procedure archive_record();
