set role sport_admin;

drop trigger set_timestamp on "user";
drop trigger set_timestamp on platform;
drop trigger set_timestamp on platform_credential;
drop trigger set_timestamp on action_provider;
drop trigger set_timestamp on action;
drop trigger set_timestamp on action_rule;
drop trigger set_timestamp on action_event;
drop trigger set_timestamp on diary;
drop trigger set_timestamp on wod;
drop trigger set_timestamp on movement;
drop trigger delete_movement_archive on movement_archive;
drop trigger check_movement_exists_trigger on movement_muscle_archive;
drop trigger set_timestamp on strength_session;
drop trigger delete_strength_session_archive on strength_session_archive;
drop trigger check_strength_session_exists_trigger on strength_set_archive;
drop trigger set_timestamp on strength_set;
drop trigger set_timestamp on metcon;
drop trigger delete_metcon_archive on metcon_archive;
drop trigger check_metcon_exists_trigger on metcon_movement_archive;
drop trigger set_timestamp on metcon_movement;
drop trigger set_timestamp on metcon_session;
drop trigger set_timestamp on route;
drop trigger set_timestamp on cardio_session;

drop table movement_muscle_archive;
drop table movement_muscle;
drop table muscle_group;
drop table shared_diary;
drop table shared_cardio_session;
drop table shared_strength_session;
drop table shared_metcon_session;
drop table group_user;
drop table "group";

create function set_epoch() 
    returns trigger as $$
    declare
        max_epoch bigint;
    begin
        execute format('select max(epoch) + 1 from %I.%I', tg_table_schema, tg_table_name)
        into max_epoch;

        new.epoch := coalesce(max_epoch, 1);
        return new;
    end;
    $$ language plpgsql;

create function set_epoch_for_user() 
    returns trigger as $$
    declare
        max_epoch bigint;
    begin
        if new.user_id is null then
            execute format('select max(epoch) + 1 from %I.%I where user_id is null', tg_table_schema, tg_table_name)
            into max_epoch;
        else
            execute format('select max(epoch) + 1 from %I.%I where user_id = $1', tg_table_schema, tg_table_name)
            using new.user_id
            into max_epoch;
        end if;

        new.epoch := coalesce(max_epoch, 1);
        return new;
    end;
    $$ language plpgsql;

create function set_epoch_for_user_in_user_table() 
    returns trigger as $$
    declare
        max_epoch bigint;
    begin
        execute format('select max(epoch) + 1 from %I.%I where id = $1', tg_table_schema, tg_table_name)
        using new.id
        into max_epoch;

        new.epoch := coalesce(max_epoch, 1);
        return new;
    end;
    $$ language plpgsql;

create or replace function archive_record()
    returns trigger as $$
    begin
        if (tg_op = 'INSERT' and new.deleted = true) then
            execute format('delete from %I.%I where id = $1', tg_table_schema, tg_table_name) using new.id;
            return old;
        end if;
        -- when a soft-delete happens...
        if (tg_op = 'UPDATE' and new.deleted = true) then
            execute format('delete from %I.%I where id = $1', tg_table_schema, tg_table_name) using old.id;
            return old;
        end if;
        -- when a hard-delete or a cascaded delete happens
        if (tg_op = 'DELETE') then
            if (old.deleted = false) then 
                old.deleted := true;
            end if;
            execute format('insert into %I.%I select $1.*', tg_table_schema, tg_table_name || '_archive')
            using old;
            raise notice 'soft deleting % %', tg_table_name, old.id;
        end if;
        return null;
    exception when foreign_key_violation then 
        raise notice 'hard deleting % %', tg_table_name, old.id;
        return null;
    end;
    $$ language plpgsql;

create or replace trigger archive_movement
    after insert or update of deleted or delete
    on movement
    for each row execute procedure archive_record();

create or replace trigger archive_metcon
    after insert or update of deleted or delete
    on metcon
    for each row execute procedure archive_record();

create or replace trigger archive_strength_session
    after insert or update of deleted or delete
    on strength_session
    for each row execute procedure archive_record();

drop function check_movement_exists;
drop function delete_record_movement;
drop function archive_record_movement;
drop function check_metcon_exists;
drop function delete_record_metcon;
drop function archive_record_metcon;
drop function check_strength_session_exists;
drop function delete_record_strength_session;
drop function archive_record_strength_session;
drop function trigger_set_timestamp;

alter table "user" add epoch bigint not null default 1;
create trigger set_epoch before insert or update on "user"
    for each row execute function set_epoch_for_user_in_user_table();

alter table platform drop column last_change;
alter table platform add epoch bigint not null default 1;
create trigger set_epoch before insert or update on platform
    for each row execute function set_epoch();

drop index platform_credential__user_id__last_change__idx;
alter table platform_credential drop column last_change;
alter table platform_credential add epoch bigint not null default 1;
create index platform_credential__user_id__epoch__idx
    on platform_credential (user_id, epoch) where deleted = false;
create trigger set_epoch before insert or update on platform_credential
    for each row execute function set_epoch_for_user();

alter table action_provider drop column last_change;
alter table action_provider add epoch bigint not null default 1;
create trigger set_epoch before insert or update on action_provider
    for each row execute function set_epoch();

alter table action drop column last_change;
alter table action add epoch bigint not null default 1;
create trigger set_epoch before insert or update on action
    for each row execute function set_epoch();

drop index action_rule__user_id__last_change__idx;
alter table action_rule drop column last_change;
alter table action_rule add epoch bigint not null default 1;
create index action_rule__user_id__epoch__idx
    on action_rule (user_id, epoch) 
    where deleted = false;
create trigger set_epoch before insert or update on action_rule
    for each row execute function set_epoch_for_user();

drop index action_event__user_id__last_change__idx;
alter table action_event drop column last_change;
alter table action_event add epoch bigint not null default 1;
create index action_event__user_id__epoch__idx
    on action_event (user_id, epoch) 
    where deleted = false;
create trigger set_epoch before insert or update on action_event
    for each row execute function set_epoch_for_user();

drop index diary__user_id__last_change__idx;
alter table diary drop column last_change;
alter table diary add epoch bigint not null default 1;
create index diary__user_id__epoch__idx
    on diary (user_id, epoch) 
    where deleted = false;
create trigger set_epoch before insert or update on diary
    for each row execute function set_epoch_for_user();

drop index wod__user_id__last_change__idx;
alter table wod drop column last_change;
alter table wod add epoch bigint not null default 1;
create index wod__user_id__epoch__idx
    on wod (user_id, epoch) 
    where deleted = false;
create trigger set_epoch before insert or update on wod
    for each row execute function set_epoch_for_user();

drop index movement__user_id__last_change__idx;
alter table movement drop column last_change;
alter table movement add epoch bigint not null default 1;
create index movement__user_id__epoch__idx
    on movement (user_id, epoch) 
    where deleted = false;
create trigger set_epoch before insert or update on movement
    for each row execute function set_epoch_for_user();

drop index strength_session__user_id__last_change__idx;
alter table strength_session drop column last_change;
alter table strength_session add epoch bigint not null default 1;
create index strength_session__user_id__epoch__idx
    on strength_session (user_id, epoch) 
    where deleted = false;
create trigger set_epoch before insert or update on strength_session
    for each row execute function set_epoch_for_user();

alter table strength_set drop column last_change;
alter table strength_set add epoch bigint not null default 1;
alter table strength_set add column user_id bigint;
update strength_set
    set user_id = ss.user_id
    from strength_session ss
    where strength_set.strength_session_id = ss.id;
alter table strength_set alter column user_id set not null;
alter table strength_set
    add constraint strength_set_user_id_fkey
    foreign key (user_id) references "user"(id) on delete cascade;
create index strength_set__user_id__epoch__idx
    on strength_set (user_id, epoch) 
    where deleted = false;
create trigger set_epoch before insert or update on strength_set
    for each row execute function set_epoch_for_user();

drop index metcon__user_id__last_change__idx;
alter table metcon drop column last_change;
alter table metcon add epoch bigint not null default 1;
create index metcon__user_id__epoch__idx
    on metcon (user_id, epoch) 
    where deleted = false;
create trigger set_epoch before insert or update on metcon
    for each row execute function set_epoch_for_user();

alter table metcon_movement drop column last_change;
alter table metcon_movement add epoch bigint not null default 1;
alter table metcon_movement add column user_id bigint;
update metcon_movement
    set user_id = ss.user_id
    from metcon ss
    where metcon_movement.metcon_id = ss.id;
alter table metcon_movement
    add constraint metcon_movement_user_id_fkey
    foreign key (user_id) references "user"(id) on delete cascade;
create index metcon_movement__user_id__epoch__idx
    on metcon_movement (user_id, epoch) 
    where deleted = false;
create trigger set_epoch before insert or update on metcon_movement
    for each row execute function set_epoch_for_user();

drop index metcon_session__user_id__last_change__idx;
alter table metcon_session drop column last_change;
alter table metcon_session add epoch bigint not null default 1;
create index metcon_session__user_id__epoch__idx
    on metcon_session (user_id, epoch) 
    where deleted = false;
create trigger set_epoch before insert or update on metcon_session
    for each row execute function set_epoch_for_user();

drop index route__user_id__last_change__idx;
alter table route drop column last_change;
alter table route add epoch bigint not null default 1;
create index route__user_id__epoch__idx
    on route (user_id, epoch) 
    where deleted = false;
create trigger set_epoch before insert or update on route
    for each row execute function set_epoch_for_user();

drop index cardio_session__user_id__last_change__idx;
alter table cardio_session drop column last_change;
alter table cardio_session add epoch bigint not null default 1;
create index cardio_session__user_id__epoch__idx
    on cardio_session (user_id, epoch) 
    where deleted = false;
create trigger set_epoch before insert or update on cardio_session
    for each row execute function set_epoch_for_user();
