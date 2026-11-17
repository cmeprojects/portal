-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 123: removes rostering round 2 (timesheets, change requests, the
-- shift log, repeating series, the check-dates function and the package
-- switch) and puts the update 122 shift checks and reminders back. Shifts
-- themselves are kept. Safe to run again.
begin;
drop trigger if exists log_shift on public.shifts;
drop function if exists public.log_shift();
drop table if exists public.shift_change_requests;
drop function if exists public.guard_change_request();
drop table if exists public.shift_timesheets;
drop function if exists public.guard_timesheet();
drop table if exists public.shift_events;
drop function if exists public.au_time(timestamptz);
drop function if exists public.au_day(timestamptz);
drop index if exists public.shifts_series;
alter table public.shifts drop column if exists series_id;
create or replace function public.guard_shift()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_scheme text;
begin
  if tg_op = 'INSERT' then
    new.created_by := auth.uid();
    new.created_at := now();
    new.notified_at := null;
    new.reminded_on := null;
  else
    -- Only the "told them" marks changed (the server's reminders): nothing to check.
    if (new.worker_id, new.starts_at, new.ends_at, new.break_minutes, new.client_id, new.service_id, new.location_id, new.notes, new.status, new.created_by, new.created_at)
       is not distinct from (old.worker_id, old.starts_at, old.ends_at, old.break_minutes, old.client_id, old.service_id, old.location_id, old.notes, old.status, old.created_by, old.created_at) then
      new.updated_by := old.updated_by;
      new.updated_at := old.updated_at;
      return new;
    end if;
    if (new.created_by, new.created_at) is distinct from (old.created_by, old.created_at) then
      raise exception 'Who added a shift stays as it was.';
    end if;
    if old.status = 'cancelled' and new is distinct from old then
      raise exception 'A cancelled shift stays cancelled. Add a new one.';
    end if;
    -- Changed for the worker: tell them again.
    if (new.worker_id, new.starts_at, new.ends_at, new.status, new.location_id) is distinct from (old.worker_id, old.starts_at, old.ends_at, old.status, old.location_id) then
      new.notified_at := null;
      new.reminded_on := null;
    end if;
  end if;
  new.updated_by := auth.uid();
  new.updated_at := now();
  if new.status = 'cancelled' then
    return new;
  end if;
  if new.service_id is not null and not exists (select 1 from public.client_services s where s.id = new.service_id and s.client_id = new.client_id) then
    raise exception 'That service belongs to another client.';
  end if;
  if new.location_id is not null and not exists (select 1 from public.client_locations l where l.id = new.location_id and l.client_id = new.client_id and l.approved) then
    raise exception 'Choose an approved location of this client.';
  end if;
  if new.worker_id is not null then
    if not exists (select 1 from public.profiles p where p.id = new.worker_id and p.active and p.role not in ('new_starter', 'system_admin', 'external')) then
      raise exception 'That worker can''t be rostered (not active, or onboarding not finished).';
    end if;
    if exists (select 1 from public.leave_periods l
                where l.user_id = new.worker_id
                  and l.start_date <= (new.ends_at at time zone 'Australia/Sydney')::date
                  and l.end_date >= (new.starts_at at time zone 'Australia/Sydney')::date) then
      raise exception 'That worker is on approved leave then.';
    end if;
    if exists (select 1 from public.shifts s
                where s.worker_id = new.worker_id and s.id <> new.id and s.status <> 'cancelled'
                  and s.starts_at < new.ends_at and s.ends_at > new.starts_at) then
      raise exception 'That worker already has a shift at that time.';
    end if;
  end if;
  return new;
end;
$$;
create or replace function public.run_roster_alerts()
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  r record;
  v_new int := 0;
  v_tomorrow int := 0;
  v_today date := public.local_today();
begin
  for r in
    select s.id, s.worker_id, s.starts_at, s.ends_at, c.name as client
      from public.shifts s left join public.car_clients c on c.id = s.client_id
     where s.status = 'published' and s.worker_id is not null and s.notified_at is null and s.ends_at > now()
  loop
    perform public.notify(r.worker_id, 'shift_published',
      'Shift ' || to_char(r.starts_at at time zone 'Australia/Sydney', 'Dy DD Mon, HH24:MI') || '–' || to_char(r.ends_at at time zone 'Australia/Sydney', 'HH24:MI'),
      coalesce(r.client, 'See My shifts'), '/my-shifts', true);
    update public.shifts set notified_at = now() where id = r.id;
    v_new := v_new + 1;
  end loop;
  for r in
    select s.id, s.worker_id, s.starts_at, c.name as client
      from public.shifts s left join public.car_clients c on c.id = s.client_id
     where s.status = 'published' and s.worker_id is not null
       and (s.starts_at at time zone 'Australia/Sydney')::date = v_today + 1 and s.reminded_on is null
  loop
    perform public.notify(r.worker_id, 'shift_tomorrow',
      'Tomorrow: shift at ' || to_char(r.starts_at at time zone 'Australia/Sydney', 'HH24:MI'), coalesce(r.client, 'See My shifts'), '/my-shifts', false);
    update public.shifts set reminded_on = v_today where id = r.id;
    v_tomorrow := v_tomorrow + 1;
  end loop;
  return jsonb_build_object('shifts_notified', v_new, 'shift_reminders', v_tomorrow);
end;
$$;
revoke execute on function public.run_roster_alerts() from public, anon, authenticated;
grant execute on function public.run_roster_alerts() to service_role;
drop function if exists public.roster_check_dates(uuid);
delete from public.features where key = 'rostering';
commit;
