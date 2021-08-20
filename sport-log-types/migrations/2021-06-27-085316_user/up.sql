create function trigger_set_timestamp()
    returns trigger as $$
    begin
        new.last_change = now();
        return new;
    end;
    $$ language plpgsql;

create table "user" (
    id bigint primary key,
    username varchar(80) not null check (length(username) >= 2),
    password char(96) not null,
    email varchar(80) not null,
    last_change timestamptz not null default now(),
    unique (username),
    unique (email)
);

create trigger set_timestamp before update on "user"
    for each row execute procedure trigger_set_timestamp();

create index on "user" (username);

insert into "user" (id, username, password, email) values 
    (1, 'user1', '$argon2id$v=19$m=4096,t=3,p=1$PurNCF1Y9tu+ETV/3yHSqA$mrMyoQ7YQbf+s9/30Bfma8VPlykLnC17dN2wG3zl9qc', 'email1'), -- "user1-passwd"
    (2, 'user2', '$argon2id$v=19$m=4096,t=3,p=1$PQlR/f+Tei/QCJdHoUOzKA$c8JnKvYFUkueiCxIIlNIHnCnpgIlqRtZ3v/Mip1v2kc', 'email2'), -- "user2-passwd"
    (3, 'user3', '$argon2id$v=19$m=4096,t=3,p=1$wT9O5qKLHQ2Z3+qKxx+wmg$GdEcLBbBOIqNDy/hdITV13FyvK2egPAG43bKB13cTsM', 'email3'); -- "user3-passwd"