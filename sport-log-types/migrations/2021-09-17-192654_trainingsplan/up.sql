create table trainingsplan (
    id bigint primary key,
    user_id bigint not null references "user" on delete cascade,
    name varchar(80) not null,
    description text,
    date date,
    weekday weekday,
    last_change timestamptz not null default now(),
    deleted boolean not null default false
);

create table strength_item (
    id bigint primary key,
    trainingsplan_id bigint not null references trainingsplan on delete cascade,
    strength_blueprint_id bigint not null references strength_blueprint on delete cascade,
    last_change timestamptz not null default now(),
    deleted boolean not null default false
);

create table metcon_item (
    id bigint primary key,
    trainingsplan_id bigint not null references trainingsplan on delete cascade,
    metcon_id bigint not null references metcon on delete cascade,
    last_change timestamptz not null default now(),
    deleted boolean not null default false
);

create table cardio_item (
    id bigint primary key,
    trainingsplan_id bigint not null references trainingsplan on delete cascade,
    cardio_blueprint_id bigint not null references cardio_blueprint on delete cascade,
    last_change timestamptz not null default now(),
    deleted boolean not null default false
);
