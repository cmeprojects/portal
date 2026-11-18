-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 128: removes rostering round 3. Shifts, their times, workers and
-- the plain-words log lines stay; the new columns, responses, signatures,
-- internal notes and trip links are removed. Safe to run again.
begin;
alter table public.car_trips drop column if exists shift_id;
drop table if exists public.shift_notes;
drop table if exists public.shift_signatures;
drop function if exists public.guard_shift_signature();
drop trigger if exists reset_shift_response on public.shifts;
drop function if exists public.reset_shift_response();
drop table if exists public.shift_responses;
drop function if exists public.log_shift_response();
create or replace function public.log_shift()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  parts text[] := '{}';
  nm text;
begin
  if tg_op = 'INSERT' then
    parts := array['added the shift' || case when new.series_id is not null then ' (repeating)' else '' end
                   || case when new.status = 'published' then ' and published it' else ' as a draft' end];
  else
    if new.worker_id is distinct from old.worker_id then
      select coalesce(nullif(full_name, ''), email) into nm from public.profiles where id = new.worker_id;
      parts := parts || case when new.worker_id is null then 'made it an open shift' else 'gave the shift to ' || coalesce(nm, 'a worker') end;
    end if;
    if (new.starts_at at time zone 'Australia/Sydney')::date <> (old.starts_at at time zone 'Australia/Sydney')::date then
      parts := parts || ('moved it from ' || public.au_day(old.starts_at) || ' to ' || public.au_day(new.starts_at));
    end if;
    if public.au_time(new.starts_at) <> public.au_time(old.starts_at) then
      parts := parts || ('changed the start time from ' || public.au_time(old.starts_at) || ' to ' || public.au_time(new.starts_at));
    end if;
    if public.au_time(new.ends_at) <> public.au_time(old.ends_at) then
      parts := parts || ('changed the finish time from ' || public.au_time(old.ends_at) || ' to ' || public.au_time(new.ends_at));
    end if;
    if new.break_minutes <> old.break_minutes then
      parts := parts || ('changed the break from ' || old.break_minutes || ' to ' || new.break_minutes || ' minutes');
    end if;
    if new.client_id is distinct from old.client_id then parts := parts || 'changed the client'::text; end if;
    if new.location_id is distinct from old.location_id then parts := parts || 'changed the location'::text; end if;
    if new.notes is distinct from old.notes then parts := parts || 'updated the instructions'::text; end if;
    if new.status <> old.status then
      parts := parts || case new.status when 'published' then 'published it (the worker is told)' when 'cancelled' then 'cancelled the shift' else 'moved it back to draft' end;
    end if;
  end if;
  if cardinality(parts) > 0 then
    insert into public.shift_events (shift_id, actor, summary) values (new.id, auth.uid(), array_to_string(parts, ', '));
  end if;
  return null;
end;
$$;
revoke execute on function public.log_shift() from public, anon, authenticated;
drop function if exists public.shift_source(public.shifts);
drop policy if exists "workers read their shift events" on public.shift_events;
drop policy if exists "the log is written by the system" on public.shift_events;
create policy "the log is written by the system" on public.shift_events
  for insert to authenticated
  with check (not (actor is distinct from (select auth.uid())));
alter table public.shift_events drop constraint if exists shift_events_kind_check;
alter table public.shift_events drop constraint if exists shift_events_source_check;
alter table public.shift_events drop column if exists reason;
alter table public.shift_events drop column if exists source;
alter table public.shift_events drop column if exists new_value;
alter table public.shift_events drop column if exists old_value;
alter table public.shift_events drop column if exists field;
alter table public.shift_events drop column if exists kind;
drop trigger if exists guard_shift_client on public.shifts;
drop function if exists public.guard_shift_client();
drop index if exists public.shifts_vehicle;
drop index if exists public.shifts_ref;
alter table public.shifts drop constraint if exists shifts_shift_type_check;
alter table public.shifts drop constraint if exists shifts_pay_group_check;
alter table public.shifts drop constraint if exists shifts_allowances_check;
alter table public.shifts drop column if exists needs_client_signature;
alter table public.shifts drop column if exists needs_worker_signature;
alter table public.shifts drop column if exists allowances;
alter table public.shifts drop column if exists pay_group;
alter table public.shifts drop column if exists vehicle_id;
alter table public.shifts drop column if exists shift_type;
alter table public.shifts drop column if exists ref;
drop sequence if exists public.shift_ref_seq;
commit;
