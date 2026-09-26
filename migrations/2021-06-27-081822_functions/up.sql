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

-- next epoch of a record that is archived without a set_epoch trigger (hard or cascaded delete)
create function next_epoch(table_schema name, table_name name, record jsonb)
    returns bigint as $$
    declare
        max_epoch bigint;
    begin
        if not record ? 'user_id' then
            execute format('select max(epoch) + 1 from %I.%I', table_schema, table_name)
            into max_epoch;
        elsif record ->> 'user_id' is null then
            execute format('select max(epoch) + 1 from %I.%I where user_id is null', table_schema, table_name)
            into max_epoch;
        else
            execute format('select max(epoch) + 1 from %I.%I where user_id = $1', table_schema, table_name)
            using (record ->> 'user_id')::bigint
            into max_epoch;
        end if;

        return coalesce(max_epoch, 1);
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

-- after insert or update: a soft-deleted row is deleted, which runs mark_deleted_and_archive_record and cascades to referencing rows
create function delete_soft_deleted_record()
    returns trigger as $$
    begin
        if new.deleted then
            execute format('delete from %I.%I where id = $1', tg_table_schema, tg_table_name) using new.id;
        end if;
        return null;
    end;
    $$ language plpgsql;

-- before delete: set deleted and a new epoch (unless already soft deleted) and move the row to its archive table
create function mark_deleted_and_archive_record()
    returns trigger as $$
    begin
        -- a hard or cascaded delete still needs a new epoch
        if not old.deleted then
            old.deleted := true;
            old.epoch := next_epoch(tg_table_schema, tg_table_name, to_jsonb(old));
        end if;
        execute format('insert into %I.%I select $1.*', tg_table_schema, tg_table_name || '_archive') using old;
        raise notice 'soft deleting % %', tg_table_name, old.id;
        return old;
    exception when foreign_key_violation then 
        raise notice 'hard deleting % %', tg_table_name, old.id;
        return old;
    end;
    $$ language plpgsql;
