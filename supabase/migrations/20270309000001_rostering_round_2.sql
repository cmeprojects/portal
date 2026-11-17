-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 123; owner approved the preview, 18 Nov 2026):
-- rostering round 2, one premium package.
--
--   * Premium package "Rostering" (key rostering): the roster, My shifts,
--     timesheets, shift change requests, a client's shifts and the hours on
--     the Staff list. Only the system admin switches it; when off, everything
--     is hidden and the database refuses changes (nothing is deleted).
--   * Expired "before work" checks (for example NDIS Worker Screening): the
--     worker can't be given a shift. People who roster see staff check names
--     and expiry dates only (never files, numbers or notes), through one
--     read-only function the owner approved: roster_check_dates().
--   * Repeating shifts: shifts made together share a series (series_id).
--   * Timesheets: the worker confirms their actual start, finish and break
--     (plus allowances, mileage, expense); people who roster approve, query
--     or correct (a correction needs a reason). Approved ones stay as they are
--     unless someone who rosters changes them again.
--   * Shift change requests (swap or can't work): from the worker for their own
--     upcoming shift; people who roster approve or decline. Approving a swap
--     moves the shift (the usual checks apply).
--   * Log: every change to a shift, its timesheet or a request is written in
--     plain words ("changed the finish time from 3pm to 4pm").
--   * Reminders (server only): the roster team hears about new requests; the
--     worker hears when a request is decided or a timesheet is queried.

insert into public.features (key, label, description, enabled, sort_order, premium, included) values
  ('rostering', 'Rostering',
   'The roster, open shifts, My shifts, timesheets, shift change requests and hours on the Staff list.',
   true, 45, true, true)
on conflict (key) do nothing;

-- Staff check names and expiry dates for people who roster (approved by the owner).
create or replace function public.roster_check_dates(p_user uuid default null)
returns table (user_id uuid, title text, expires_on date, before_work boolean)
language sql
stable
security definer
set search_path = ''
as $$
  select distinct on (r.user_id, r.item_id) r.user_id, i.title, r.expires_on, i.before_work
    from public.compliance_records r
    join public.compliance_items i on i.id = r.item_id and i.active
    join public.profiles p on p.id = r.user_id and p.active
   where public.can('ops.roster', 'view')
     and r.expires_on is not null
     and r.status in ('accepted', 'done')
     and (p_user is null or r.user_id = p_user)
   order by r.user_id, r.item_id, r.expires_on desc
$$;
revoke execute on function public.roster_check_dates(uuid) from public, anon;
grant execute on function public.roster_check_dates(uuid) to authenticated;

alter table public.shifts add column if not exists series_id uuid;
create index if not exists shifts_series on public.shifts (series_id) where series_id is not null;

-- The shift guard again, with the package switch and expired "before work" checks.
create or replace function public.guard_shift()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    if auth.uid() is not null and not public.feature_enabled('rostering') then
      raise exception 'Rostering is switched off' using errcode = '42501';
    end if;
    new.created_by := auth.uid();
    new.created_at := now();
    new.notified_at := null;
    new.reminded_on := null;
  else
    if (new.worker_id, new.starts_at, new.ends_at, new.break_minutes, new.client_id, new.service_id, new.location_id, new.notes, new.status, new.created_by, new.created_at, new.series_id)
       is not distinct from (old.worker_id, old.starts_at, old.ends_at, old.break_minutes, old.client_id, old.service_id, old.location_id, old.notes, old.status, old.created_by, old.created_at, old.series_id) then
      new.updated_by := old.updated_by;
      new.updated_at := old.updated_at;
      return new;
    end if;
    if auth.uid() is not null and not public.feature_enabled('rostering') then
      raise exception 'Rostering is switched off' using errcode = '42501';
    end if;
    if (new.created_by, new.created_at) is distinct from (old.created_by, old.created_at) then
      raise exception 'Who added a shift stays as it was.';
    end if;
    if old.status = 'cancelled' and new is distinct from old then
      raise exception 'A cancelled shift stays cancelled. Add a new one.';
    end if;
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
    if exists (select 1 from public.roster_check_dates(new.worker_id) c
                where c.before_work and c.expires_on < (new.starts_at at time zone 'Australia/Sydney')::date) then
      raise exception 'That worker has an expired check needed before work (%). Renew it first.',
        (select string_agg(c.title, ', ') from public.roster_check_dates(new.worker_id) c
          where c.before_work and c.expires_on < (new.starts_at at time zone 'Australia/Sydney')::date);
    end if;
  end if;
  return new;
end;
$$;

-- The plain-words log ---------------------------------------------------------
create table if not exists public.shift_events (
  id bigint generated always as identity primary key,
  org_id uuid not null default public.default_org_id(),
  shift_id uuid not null references public.shifts (id) on delete restrict,
  actor uuid default auth.uid() references public.profiles (id),
  happened_at timestamptz not null default now(),
  summary text not null check (length(summary) between 1 and 1000)
);
create index if not exists shift_events_shift on public.shift_events (shift_id, happened_at);
alter table public.shift_events enable row level security;
drop policy if exists "people who roster read the log" on public.shift_events;
create policy "people who roster read the log" on public.shift_events
  for select to authenticated using ((select public.can('ops.roster', 'view')));
drop policy if exists "the log is written by the system" on public.shift_events;
create policy "the log is written by the system" on public.shift_events
  for insert to authenticated with check (actor is not distinct from (select auth.uid()));
grant select, insert on public.shift_events to authenticated;

create or replace function public.au_time(p timestamptz)
returns text
language sql
stable
set search_path = ''
as $$
  select lower(trim(leading '0' from to_char(p at time zone 'Australia/Sydney', 'HH12:MIam')))
$$;
create or replace function public.au_day(p timestamptz)
returns text
language sql
stable
set search_path = ''
as $$
  select to_char(p at time zone 'Australia/Sydney', 'Dy DD Mon')
$$;

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
drop trigger if exists log_shift on public.shifts;
create trigger log_shift after insert or update on public.shifts
  for each row execute function public.log_shift();

-- Timesheets -----------------------------------------------------------------
create table if not exists public.shift_timesheets (
  shift_id uuid primary key references public.shifts (id) on delete restrict,
  org_id uuid not null default public.default_org_id(),
  worker_id uuid not null references public.profiles (id) on delete restrict,
  actual_start timestamptz not null,
  actual_end timestamptz not null,
  break_minutes int not null default 0 check (break_minutes between 0 and 240),
  allowances text[] not null default '{}' check (cardinality(allowances) <= 5),
  km numeric(7,1) not null default 0 check (km between 0 and 2000),
  expense numeric(8,2) not null default 0 check (expense between 0 and 10000),
  note text not null default '' check (length(note) <= 500),
  change_reason text not null default '' check (length(change_reason) <= 500),
  status text not null default 'submitted' check (status in ('submitted', 'queried', 'approved')),
  submitted_at timestamptz not null default now(),
  decided_by uuid references public.profiles (id),
  decided_at timestamptz,
  told_at timestamptz,
  check (actual_end > actual_start and actual_end - actual_start <= interval '20 hours')
);
create index if not exists shift_timesheets_status on public.shift_timesheets (status);
alter table public.shift_timesheets enable row level security;
drop policy if exists "see timesheets" on public.shift_timesheets;
create policy "see timesheets" on public.shift_timesheets
  for select to authenticated using (worker_id = (select auth.uid()) or (select public.can('ops.roster', 'view')));
drop policy if exists "send timesheets" on public.shift_timesheets;
create policy "send timesheets" on public.shift_timesheets
  for insert to authenticated
  with check ((worker_id = (select auth.uid())
               and shift_id in (select s.id from public.shifts s where s.worker_id = (select auth.uid()) and s.status = 'published' and s.starts_at <= now() + interval '1 hour'))
              or (select public.can('ops.roster', 'edit')));
drop policy if exists "change timesheets" on public.shift_timesheets;
create policy "change timesheets" on public.shift_timesheets
  for update to authenticated
  using ((worker_id = (select auth.uid()) and status <> 'approved') or (select public.can('ops.roster', 'edit')))
  with check ((worker_id = (select auth.uid())) or (select public.can('ops.roster', 'edit')));
grant select, insert, update on public.shift_timesheets to authenticated;

create or replace function public.guard_timesheet()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_editor boolean := public.can('ops.roster', 'edit');
  parts text[] := '{}';
begin
  -- Only the "worker told" mark changed (the server's reminders): nothing to check.
  if tg_op = 'UPDATE' and (new.actual_start, new.actual_end, new.break_minutes, new.allowances, new.km, new.expense, new.note, new.change_reason, new.status, new.decided_by, new.decided_at)
     is not distinct from (old.actual_start, old.actual_end, old.break_minutes, old.allowances, old.km, old.expense, old.note, old.change_reason, old.status, old.decided_by, old.decided_at) then
    return new;
  end if;
  if auth.uid() is not null and not public.feature_enabled('rostering') then
    raise exception 'Rostering is switched off' using errcode = '42501';
  end if;
  new.worker_id := (select s.worker_id from public.shifts s where s.id = new.shift_id);
  if new.worker_id is null then
    raise exception 'That shift has no worker.';
  end if;
  if tg_op = 'INSERT' then
    if new.worker_id = auth.uid() and not v_editor then
      new.status := 'submitted';
    end if;
    new.submitted_at := now();
    new.decided_by := null;
    new.decided_at := null;
    insert into public.shift_events (shift_id, actor, summary)
    values (new.shift_id, auth.uid(), 'sent the timesheet: ' || public.au_time(new.actual_start) || ' to ' || public.au_time(new.actual_end)
            || case when new.break_minutes > 0 then ', ' || new.break_minutes || ' minute break' else '' end);
    return new;
  end if;
  -- The worker: their own times only, back to "submitted".
  if not v_editor then
    if new.status <> old.status and new.status <> 'submitted' then
      raise exception 'Only people who roster approve or query timesheets.';
    end if;
    new.status := 'submitted';
    new.decided_by := old.decided_by;
    new.decided_at := old.decided_at;
  end if;
  if (new.actual_start, new.actual_end, new.break_minutes) is distinct from (old.actual_start, old.actual_end, old.break_minutes) then
    if v_editor and old.worker_id <> auth.uid() and length(trim(new.change_reason)) = 0 then
      raise exception 'Say why the times changed: it goes in the shift log.';
    end if;
    if public.au_time(new.actual_start) <> public.au_time(old.actual_start) then
      parts := parts || ('changed the clock-in time from ' || public.au_time(old.actual_start) || ' to ' || public.au_time(new.actual_start));
    end if;
    if public.au_time(new.actual_end) <> public.au_time(old.actual_end) then
      parts := parts || ('changed the clock-out time from ' || public.au_time(old.actual_end) || ' to ' || public.au_time(new.actual_end));
    end if;
    if new.break_minutes <> old.break_minutes then
      parts := parts || ('changed the break from ' || old.break_minutes || ' to ' || new.break_minutes || ' minutes');
    end if;
  end if;
  if new.km <> old.km then parts := parts || ('set mileage to ' || new.km || ' km'); end if;
  if new.expense <> old.expense then parts := parts || ('set the expense to $' || to_char(new.expense, 'FM999990.00')); end if;
  if new.allowances is distinct from old.allowances then parts := parts || ('set allowances: ' || coalesce(nullif(array_to_string(new.allowances, ', '), ''), 'none')); end if;
  if new.status <> old.status then
    parts := parts || case new.status when 'approved' then 'approved the timesheet' when 'queried' then 'queried the timesheet (the worker is asked)' else 'sent the timesheet again' end;
    if new.status in ('approved', 'queried') then
      new.decided_by := auth.uid();
      new.decided_at := now();
      new.told_at := null;
    end if;
  end if;
  if cardinality(parts) > 0 then
    insert into public.shift_events (shift_id, actor, summary)
    values (new.shift_id, auth.uid(), array_to_string(parts, ', ') || case when length(trim(new.change_reason)) > 0 and new.change_reason is distinct from old.change_reason then ' ("' || new.change_reason || '")' else '' end);
  end if;
  return new;
end;
$$;
revoke execute on function public.guard_timesheet() from public, anon, authenticated;
drop trigger if exists guard_timesheet on public.shift_timesheets;
create trigger guard_timesheet before insert or update on public.shift_timesheets
  for each row execute function public.guard_timesheet();

-- Shift change requests --------------------------------------------------------
create table if not exists public.shift_change_requests (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  shift_id uuid not null references public.shifts (id) on delete restrict,
  requested_by uuid not null default auth.uid() references public.profiles (id),
  kind text not null check (kind in ('swap', 'cannot_work')),
  swap_with uuid references public.profiles (id),
  reason text not null check (length(reason) between 1 and 500),
  status text not null default 'pending' check (status in ('pending', 'approved', 'declined', 'withdrawn')),
  decided_by uuid references public.profiles (id),
  decided_at timestamptz,
  created_at timestamptz not null default now(),
  roster_told_at timestamptz,
  worker_told_at timestamptz,
  check (kind <> 'swap' or swap_with is not null)
);
create index if not exists shift_change_requests_pending on public.shift_change_requests (status) where status = 'pending';
alter table public.shift_change_requests enable row level security;
drop policy if exists "see change requests" on public.shift_change_requests;
create policy "see change requests" on public.shift_change_requests
  for select to authenticated using (requested_by = (select auth.uid()) or (select public.can('ops.roster', 'view')));
drop policy if exists "ask for a change" on public.shift_change_requests;
create policy "ask for a change" on public.shift_change_requests
  for insert to authenticated
  with check (requested_by = (select auth.uid())
              and shift_id in (select s.id from public.shifts s where s.worker_id = (select auth.uid()) and s.status = 'published' and s.starts_at > now()));
drop policy if exists "decide change requests" on public.shift_change_requests;
create policy "decide change requests" on public.shift_change_requests
  for update to authenticated
  using ((select public.can('ops.roster', 'edit')) or (requested_by = (select auth.uid()) and status = 'pending'))
  with check ((select public.can('ops.roster', 'edit')) or requested_by = (select auth.uid()));
grant select, insert, update on public.shift_change_requests to authenticated;

create or replace function public.guard_change_request()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  nm text;
begin
  if auth.uid() is not null and not public.feature_enabled('rostering') then
    raise exception 'Rostering is switched off' using errcode = '42501';
  end if;
  if tg_op = 'INSERT' then
    if exists (select 1 from public.shift_change_requests r where r.shift_id = new.shift_id and r.status = 'pending') then
      raise exception 'There''s already a request waiting for this shift.';
    end if;
    if new.swap_with = new.requested_by then
      raise exception 'Choose someone else to swap with.';
    end if;
    new.status := 'pending';
    new.created_at := now();
    new.decided_by := null;
    new.decided_at := null;
    select coalesce(nullif(full_name, ''), email) into nm from public.profiles where id = new.swap_with;
    insert into public.shift_events (shift_id, actor, summary)
    values (new.shift_id, auth.uid(), case when new.kind = 'swap' then 'asked to swap with ' || coalesce(nm, 'someone') else 'said they can''t work it' end || ' ("' || new.reason || '")');
    return new;
  end if;
  if (new.shift_id, new.requested_by, new.kind, new.swap_with, new.reason, new.created_at) is distinct from (old.shift_id, old.requested_by, old.kind, old.swap_with, old.reason, old.created_at) then
    raise exception 'A request stays as it was asked.';
  end if;
  if old.status <> 'pending' and new.status <> old.status then
    raise exception 'This request has been decided.';
  end if;
  if new.status <> old.status then
    if new.status = 'withdrawn' and new.requested_by <> auth.uid() then
      raise exception 'Only the person who asked can withdraw it.';
    end if;
    if new.status in ('approved', 'declined') and not public.can('ops.roster', 'edit') then
      raise exception 'Only people who roster decide requests.';
    end if;
    new.decided_by := auth.uid();
    new.decided_at := now();
    new.worker_told_at := null;
    insert into public.shift_events (shift_id, actor, summary)
    values (new.shift_id, auth.uid(), case new.status when 'approved' then 'approved the request' when 'declined' then 'declined the request' else 'withdrew the request' end);
    -- Approving a swap moves the shift (the shift checks apply); "can't work" opens it.
    if new.status = 'approved' then
      update public.shifts set worker_id = case when new.kind = 'swap' then new.swap_with else null end where id = new.shift_id;
    end if;
  end if;
  return new;
end;
$$;
revoke execute on function public.guard_change_request() from public, anon, authenticated;
drop trigger if exists guard_change_request on public.shift_change_requests;
create trigger guard_change_request before insert or update on public.shift_change_requests
  for each row execute function public.guard_change_request();

-- Reminders: the roster team, requests and timesheets (server only) ------------
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
  v_requests int := 0;
  v_decided int := 0;
  v_queried int := 0;
  v_today date := public.local_today();
begin
  if not public.feature_live('rostering') then
    return jsonb_build_object('rostering', 'off');
  end if;
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
  -- New requests: to the people who roster (managers, staff admins, Payroll & Rostering).
  for r in
    select q.id, q.kind, p.full_name, p.email from public.shift_change_requests q join public.profiles p on p.id = q.requested_by
     where q.status = 'pending' and q.roster_told_at is null
  loop
    perform public.notify(u.id, 'shift_request',
      coalesce(nullif(r.full_name, ''), r.email) || case when r.kind = 'swap' then ' asked to swap a shift' else ' can''t work a shift' end,
      'Shift change requests', '/roster?requests=1', false)
      from public.profiles u
     where u.active and (u.role in ('manager', 'staff_admin')
                         or u.job_title_id in (select j.id from public.job_titles j where j.name = 'Payroll & Rostering'));
    update public.shift_change_requests set roster_told_at = now() where id = r.id;
    v_requests := v_requests + 1;
  end loop;
  for r in
    select q.id, q.requested_by, q.status from public.shift_change_requests q
     where q.status in ('approved', 'declined') and q.worker_told_at is null
  loop
    perform public.notify(r.requested_by, 'shift_request_decided', 'Your shift change request was ' || r.status, 'See My shifts', '/my-shifts', true);
    update public.shift_change_requests set worker_told_at = now() where id = r.id;
    v_decided := v_decided + 1;
  end loop;
  for r in
    select t.shift_id, t.worker_id from public.shift_timesheets t where t.status = 'queried' and t.told_at is null
  loop
    perform public.notify(r.worker_id, 'timesheet_queried', 'A timesheet needs another look', 'See My shifts', '/my-shifts', true);
    update public.shift_timesheets set told_at = now() where shift_id = r.shift_id;
    v_queried := v_queried + 1;
  end loop;
  return jsonb_build_object('shifts_notified', v_new, 'shift_reminders', v_tomorrow, 'requests_notified', v_requests, 'requests_decided', v_decided, 'timesheets_queried', v_queried);
end;
$$;
revoke execute on function public.run_roster_alerts() from public, anon, authenticated;
grant execute on function public.run_roster_alerts() to service_role;
