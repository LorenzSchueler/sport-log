create function trigger_set_timestamp()
    returns trigger as $$
    begin
        new.last_change = now();
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

create function archive_record_strength_session()
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
        raise notice 'soft deleting strength_set where strength_session_id = %', old.id;
        execute format('delete from %I.strength_set where strength_session_id = $1', tg_table_schema) using old.id;
        return null;
    end;
    $$ language plpgsql;

create function delete_record_strength_session()
    returns trigger as $$
    begin
        raise notice 'hard deleting strength_set_archive where strength_session_id = %', old.id;
        execute format('delete from %I.strength_set_archive where strength_session_id = $1', tg_table_schema) using old.id;
        return null;
    end;
    $$ language plpgsql;

create function check_strength_session_exists()
    returns trigger as $$
    declare 
        parent integer;
    begin
        execute format('select count(*) from strength_session where id = $1') into parent using new.strength_session_id;
        if parent = 0 then
            execute format('delete from %I.%I where id = $1', tg_table_schema, tg_table_name) using new.id;
            raise notice 'hard deleting % %', tg_table_name, new.id;
        end if;
        return null;
    end;
    $$ language plpgsql;

create function archive_record_strength_blueprint()
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
        raise notice 'soft deleting strength_blueprint_set where strength_blueprint_id = %', old.id;
        execute format('delete from %I.strength_blueprint_set where strength_blueprint_id = $1', tg_table_schema) using old.id;
        return null;
    end;
    $$ language plpgsql;

create function delete_record_strength_blueprint()
    returns trigger as $$
    begin
        raise notice 'hard deleting strength_blueprint_set_archive where strength_blueprint_id = %', old.id;
        execute format('delete from %I.strength_blueprint_set_archive where strength_blueprint_id = $1', tg_table_schema) using old.id;
        return null;
    end;
    $$ language plpgsql;

create function check_strength_blueprint_exists()
    returns trigger as $$
    declare 
        parent integer;
    begin
        execute format('select count(*) from strength_blueprint where id = $1') into parent using new.strength_blueprint_id;
        if parent = 0 then
            execute format('delete from %I.%I where id = $1', tg_table_schema, tg_table_name) using new.id;
            raise notice 'hard deleting % %', tg_table_name, new.id;
        end if;
        return null;
    end;
    $$ language plpgsql;

create function archive_record_metcon()
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
        raise notice 'soft deleting metcon_movement where metcon_id = %', old.id;
        execute format('delete from %I.metcon_movement where metcon_id = $1', tg_table_schema) using old.id;
        raise notice 'soft deleting metcon_item where metcon_id = %', old.id;
        execute format('delete from %I.metcon_item where metcon_id = $1', tg_table_schema) using old.id;
        return null;
    end;
    $$ language plpgsql;

create function delete_record_metcon()
    returns trigger as $$
    begin
        raise notice 'hard deleting metcon_movement_archive where metcon_id = %', old.id;
        execute format('delete from %I.metcon_movement_archive where metcon_id = $1', tg_table_schema) using old.id;
        raise notice 'hard deleting metcon_item_archive where metcon_id = %', old.id;
        execute format('delete from %I.metcon_item_archive where metcon_id = $1', tg_table_schema) using old.id;
        return null;
    end;
    $$ language plpgsql;

create function check_metcon_exists()
    returns trigger as $$
    declare 
        parent integer;
    begin
        execute format('select count(*) from metcon where id = $1') into parent using new.metcon_id;
        if parent = 0 then
            execute format('delete from %I.%I where id = $1', tg_table_schema, tg_table_name) using new.id;
            raise notice 'hard deleting % %', tg_table_name, new.id;
        end if;
        return null;
    end;
    $$ language plpgsql;

create function archive_record_movement()
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
        raise notice 'soft deleting movement_muscle where movement_id = %', old.id;
        execute format('delete from %I.movement_muscle where movement_id = $1', tg_table_schema) using old.id;
        return null;
    end;
    $$ language plpgsql;

create function delete_record_movement()
    returns trigger as $$
    begin
        raise notice 'hard deleting movement_muscle_archive where movement_id = %', old.id;
        execute format('delete from %I.movement_muscle_archive where movement_id = $1', tg_table_schema) using old.id;
        return null;
    end;
    $$ language plpgsql;

create function check_movement_exists()
    returns trigger as $$
    declare 
        parent integer;
    begin
        execute format('select count(*) from movement where id = $1') into parent using new.movement_id;
        if parent = 0 then
            execute format('delete from %I.%I where id = $1', tg_table_schema, tg_table_name) using new.id;
            raise notice 'hard deleting % %', tg_table_name, new.id;
        end if;
        return null;
    end;
    $$ language plpgsql;
