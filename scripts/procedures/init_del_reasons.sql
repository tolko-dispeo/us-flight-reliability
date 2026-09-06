create or replace procedure initialize_delay_reasons()
language plpgsql
as $$
begin
    insert into delay_reason (delay_reason_id, code)
    values
        (1, 'CARRIER'),
        (2, 'WEATHER'),
        (3, 'NAS'),
        (4, 'SECURITY'),
        (5, 'LATE_AIRCRAFT')
    on CONFLICT DO NOTHING;
end;
$$;