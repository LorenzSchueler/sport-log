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
        end if;
        return null;
    end;
    $$ language plpgsql;
