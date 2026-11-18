-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 132): plain wording in the shift log (owner): "assigned" and
-- "re-assigned", "published this shift", "<name>'s clock-in signature", dates
-- like "Tue 8 Jun", and no finish-time line when only the day moves. Past
-- lines stay as written (the roster rewords the old ones when it shows them).
-- Safe to run again.
create or replace function public.au_day(p timestamptz)
returns text
language sql
stable
set search_path = ''
as $$
  select to_char(p at time zone 'Australia/Sydney', 'Dy FMDD Mon')
$$;

create or replace function public.log_shift()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_src text := public.shift_source(new);
  nm text;
begin
  if tg_op = 'INSERT' then
    insert into public.shift_events (shift_id, actor, kind, summary, source)
    values (new.id, auth.uid(), 'event',
            case when new.status = 'published' then 'added and published this shift' else 'added this shift as a draft' end
            || case when new.series_id is not null then ' (repeating)' else '' end, v_src);
    if new.worker_id is not null then
      select coalesce(nullif(full_name, ''), email) into nm from public.profiles where id = new.worker_id;
      insert into public.shift_events (shift_id, actor, kind, summary, source) values (new.id, auth.uid(), 'event', 'assigned this shift to ' || coalesce(nm, 'a worker'), v_src);
    end if;
    return null;
  end if;

  -- Events (what happened).
  if new.status <> old.status then
    insert into public.shift_events (shift_id, actor, kind, summary, field, old_value, new_value, source)
    values (new.id, auth.uid(), 'event',
            case new.status when 'published' then 'published this shift' when 'cancelled' then 'cancelled this shift' else 'moved this shift back to draft' end,
            'Status', initcap(old.status), initcap(new.status), v_src);
  end if;
  if new.worker_id is distinct from old.worker_id then
    insert into public.shift_events (shift_id, actor, kind, summary, field, old_value, new_value, source)
    values (new.id, auth.uid(), 'event',
            case when new.worker_id is null then 'made this an open shift, so staff can put their hand up'
                 when old.worker_id is null then 'assigned this shift to ' || coalesce((select coalesce(nullif(full_name, ''), email) from public.profiles where id = new.worker_id), 'a worker')
                 else 're-assigned this shift from ' || coalesce((select coalesce(nullif(full_name, ''), email) from public.profiles where id = old.worker_id), 'a worker')
                      || ' to ' || coalesce((select coalesce(nullif(full_name, ''), email) from public.profiles where id = new.worker_id), 'a worker') end,
            'Worker',
            coalesce((select coalesce(nullif(full_name, ''), email) from public.profiles where id = old.worker_id), 'Vacant'),
            coalesce((select coalesce(nullif(full_name, ''), email) from public.profiles where id = new.worker_id), 'Vacant'), v_src);
  end if;
  if new.notified_at is distinct from old.notified_at and new.notified_at is not null then
    insert into public.shift_events (shift_id, actor, kind, summary, source) values (new.id, auth.uid(), 'event', 'told the worker', 'system');
  end if;

  -- Field changes (before and after).
  if (new.starts_at at time zone 'Australia/Sydney')::date <> (old.starts_at at time zone 'Australia/Sydney')::date then
    insert into public.shift_events (shift_id, actor, kind, summary, field, old_value, new_value, source)
    values (new.id, auth.uid(), 'change', 'moved this shift from ' || public.au_day(old.starts_at) || ' to ' || public.au_day(new.starts_at), 'Date', public.au_day(old.starts_at), public.au_day(new.starts_at), v_src);
  end if;
  if public.au_time(new.starts_at) <> public.au_time(old.starts_at) then
    insert into public.shift_events (shift_id, actor, kind, summary, field, old_value, new_value, source)
    values (new.id, auth.uid(), 'change', 'changed the start time from ' || public.au_time(old.starts_at) || ' to ' || public.au_time(new.starts_at), 'Start time', public.au_time(old.starts_at), public.au_time(new.starts_at), v_src);
  end if;
  if public.au_time(new.ends_at) <> public.au_time(old.ends_at) then
    insert into public.shift_events (shift_id, actor, kind, summary, field, old_value, new_value, source)
    values (new.id, auth.uid(), 'change', 'changed the finish time from ' || public.au_time(old.ends_at) || ' to ' || public.au_time(new.ends_at), 'Finish time', public.au_time(old.ends_at), public.au_time(new.ends_at), v_src);
  end if;
  if new.break_minutes <> old.break_minutes then
    insert into public.shift_events (shift_id, actor, kind, summary, field, old_value, new_value, source)
    values (new.id, auth.uid(), 'change', 'changed the break from ' || old.break_minutes || ' to ' || new.break_minutes || ' minutes', 'Break', old.break_minutes || ' min', new.break_minutes || ' min', v_src);
  end if;
  if new.client_id is distinct from old.client_id then
    insert into public.shift_events (shift_id, actor, kind, summary, field, old_value, new_value, source)
    values (new.id, auth.uid(), 'change', 'changed the client', 'Client',
            coalesce((select name from public.car_clients where id = old.client_id), 'No client'), coalesce((select name from public.car_clients where id = new.client_id), 'No client'), v_src);
  end if;
  if new.location_id is distinct from old.location_id then
    insert into public.shift_events (shift_id, actor, kind, summary, field, old_value, new_value, source)
    values (new.id, auth.uid(), 'change', 'changed the location', 'Location',
            coalesce((select address from public.client_locations where id = old.location_id), 'Not set'), coalesce((select address from public.client_locations where id = new.location_id), 'Not set'), v_src);
  end if;
  if new.service_id is distinct from old.service_id then
    insert into public.shift_events (shift_id, actor, kind, summary, field, old_value, new_value, source)
    values (new.id, auth.uid(), 'change', 'changed the service', 'Service',
            coalesce((select label from public.client_services where id = old.service_id), 'Not set'), coalesce((select label from public.client_services where id = new.service_id), 'Not set'), v_src);
  end if;
  if new.notes is distinct from old.notes then
    insert into public.shift_events (shift_id, actor, kind, summary, field, old_value, new_value, source)
    values (new.id, auth.uid(), 'change', 'updated the worker instructions', 'Worker instructions', left(coalesce(old.notes, ''), 300), left(coalesce(new.notes, ''), 300), v_src);
  end if;
  if new.shift_type is distinct from old.shift_type then
    insert into public.shift_events (shift_id, actor, kind, summary, field, old_value, new_value, source)
    values (new.id, auth.uid(), 'change', 'changed the shift type', 'Shift type', replace(initcap(old.shift_type), '_', ' '), replace(initcap(new.shift_type), '_', ' '), v_src);
  end if;
  if new.vehicle_id is distinct from old.vehicle_id then
    insert into public.shift_events (shift_id, actor, kind, summary, field, old_value, new_value, source)
    values (new.id, auth.uid(), 'change', 'changed the car', 'Vehicle',
            coalesce((select name || ' (' || rego || ')' from public.cars where id = old.vehicle_id), 'None'), coalesce((select name || ' (' || rego || ')' from public.cars where id = new.vehicle_id), 'None'), v_src);
  end if;
  if new.pay_group is distinct from old.pay_group then
    insert into public.shift_events (shift_id, actor, kind, summary, field, old_value, new_value, source)
    values (new.id, auth.uid(), 'change', 'changed the pay group', 'Pay group', nullif(old.pay_group, ''), nullif(new.pay_group, ''), v_src);
  end if;
  if new.allowances is distinct from old.allowances then
    insert into public.shift_events (shift_id, actor, kind, summary, field, old_value, new_value, source)
    values (new.id, auth.uid(), 'change', 'changed the allowances', 'Allowances', coalesce(nullif(array_to_string(old.allowances, ', '), ''), 'None'), coalesce(nullif(array_to_string(new.allowances, ', '), ''), 'None'), v_src);
  end if;
  if new.series_id is distinct from old.series_id then
    insert into public.shift_events (shift_id, actor, kind, summary, field, old_value, new_value, source)
    values (new.id, auth.uid(), 'change', case when new.series_id is null then 'took this shift out of its repeating series' else 'made this shift part of a repeating series' end,
            'Repeats', case when old.series_id is null then 'No' else 'Yes' end, case when new.series_id is null then 'No' else 'Yes' end, v_src);
  end if;
  if (new.needs_worker_signature, new.needs_client_signature) is distinct from (old.needs_worker_signature, old.needs_client_signature) then
    insert into public.shift_events (shift_id, actor, kind, summary, field, old_value, new_value, source)
    values (new.id, auth.uid(), 'change', 'changed the signatures needed', 'Signatures needed',
            concat_ws(', ', case when old.needs_worker_signature then 'worker' end, case when old.needs_client_signature then 'client' end),
            concat_ws(', ', case when new.needs_worker_signature then 'worker' end, case when new.needs_client_signature then 'client' end), v_src);
  end if;
  return null;
end;
$$;
create or replace function public.guard_shift_signature()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    new.captured_by := auth.uid();
    new.signed_at := now();
    new.voided_at := null;
    new.voided_by := null;
    new.void_reason := null;
    insert into public.shift_events (shift_id, actor, kind, summary, field, new_value, source)
    values (new.shift_id, auth.uid(), 'event', 'recorded ' || new.signer_name || case new.kind when 'worker_in' then '''s clock-in signature' when 'worker_out' then '''s clock-out signature' when 'client' then '''s signature (client)' else '''s signature (client''s representative)' end, 'Signature', new.signer_name,
            case when exists (select 1 from public.shifts s where s.id = new.shift_id and s.worker_id = auth.uid()) then 'worker' else 'portal' end);
    return new;
  end if;
  if (to_jsonb(new) - 'voided_at' - 'voided_by' - 'void_reason') <> (to_jsonb(old) - 'voided_at' - 'voided_by' - 'void_reason') then
    raise exception 'A signature can''t be changed. Void it with a reason and record a new one.';
  end if;
  if old.voided_at is not null then
    raise exception 'That signature is already voided.';
  end if;
  if new.voided_at is null or length(trim(coalesce(new.void_reason, ''))) = 0 then
    raise exception 'Give a reason to void a signature.';
  end if;
  new.voided_at := now();
  new.voided_by := auth.uid();
  insert into public.shift_events (shift_id, actor, kind, summary, field, old_value, reason, source)
  values (new.shift_id, auth.uid(), 'event', 'voided ' || old.signer_name || case new.kind when 'worker_in' then '''s clock-in signature' when 'worker_out' then '''s clock-out signature' else '''s signature' end, 'Signature', old.signer_name, new.void_reason, 'portal');
  return new;
end;
$$;
revoke execute on function public.log_shift() from public, anon, authenticated;
revoke execute on function public.guard_shift_signature() from public, anon, authenticated;
