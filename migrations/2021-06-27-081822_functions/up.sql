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

create function archive_record()
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
