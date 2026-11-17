-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 122; HR block step 6, owner's order): rostering, first
-- version.
--
--   * New part "Rostering" (normal). Managers, staff admins and the Payroll &
--     Rostering role: every shift, add and change. Everyone sees their own
--     published shifts, and open shifts they can put their hand up for.
--   * A shift: worker (or none: an open shift), start and end (up to 16
--     hours), unpaid break, notes for the worker, and optionally the client,
--     the client's service and an approved location of that client (the
--     service's scheme comes with it). Draft, published or cancelled.
--   * The database refuses: a worker on approved leave at that time, two
--     shifts for one worker at the same time, a deactivated worker or one who
--     hasn't started, and a service or location of another client.
--   * Warnings the roster screen shows (not refused): outside their weekly
--     availability, over 38 hours in the week, checks expired.
--   * Workers are told when a shift is published or changed for them, and the
--     day before (from the server only). Nothing is deleted: shifts are
--     cancelled.

insert into public.app_modules (id, parent_id, category, label, sensitivity, delegable, sort_order, actions) values
  ('ops.roster', null, 'operations', 'Rostering', 'normal', true, 75, '{view,edit}')
on conflict (id) do nothing;

create table if not exists public.shifts (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  worker_id uuid references public.profiles (id) on delete restrict,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  break_minutes int not null default 0 check (break_minutes between 0 and 240),
  client_id uuid references public.car_clients (id) on delete restrict,
  service_id uuid references public.client_services (id) on delete restrict,
  location_id uuid references public.client_locations (id) on delete restrict,
  notes text not null default '' check (length(notes) <= 500),
  status text not null default 'draft' check (status in ('draft', 'published', 'cancelled')),
  notified_at timestamptz,
  reminded_on date,
  created_by uuid default auth.uid() references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_by uuid references public.profiles (id),
  updated_at timestamptz not null default now(),
  check (ends_at > starts_at and ends_at - starts_at <= interval '16 hours')
);
create index if not exists shifts_worker on public.shifts (worker_id, starts_at) where status <> 'cancelled';
create index if not exists shifts_starts on public.shifts (starts_at) where status <> 'cancelled';
create index if not exists shifts_client on public.shifts (client_id, starts_at) where status <> 'cancelled';

create table if not exists public.shift_interest (
  shift_id uuid not null references public.shifts (id) on delete restrict,
  user_id uuid not null references public.profiles (id) on delete restrict default auth.uid(),
  org_id uuid not null default public.default_org_id(),
  created_at timestamptz not null default now(),
  primary key (shift_id, user_id)
);

alter table public.shifts enable row level security;
alter table public.shift_interest enable row level security;

drop policy if exists "see shifts" on public.shifts;
create policy "see shifts" on public.shifts
  for select to authenticated
  using ((select public.can('ops.roster', 'view'))
         or (status = 'published' and worker_id = (select auth.uid()))
         or (status = 'published' and worker_id is null and starts_at > now() and (select public.is_member())));
drop policy if exists "add shifts" on public.shifts;
create policy "add shifts" on public.shifts
  for insert to authenticated with check ((select public.can('ops.roster', 'edit')));
drop policy if exists "change shifts" on public.shifts;
create policy "change shifts" on public.shifts
  for update to authenticated
  using ((select public.can('ops.roster', 'edit')))
  with check ((select public.can('ops.roster', 'edit')));
-- No delete rule.
grant select, insert, update on public.shifts to authenticated;

drop policy if exists "see shift interest" on public.shift_interest;
create policy "see shift interest" on public.shift_interest
  for select to authenticated using (user_id = (select auth.uid()) or (select public.can('ops.roster', 'view')));
drop policy if exists "put your hand up" on public.shift_interest;
create policy "put your hand up" on public.shift_interest
  for insert to authenticated
  with check (user_id = (select auth.uid())
              and shift_id in (select s.id from public.shifts s where s.status = 'published' and s.worker_id is null and s.starts_at > now()));
grant select, insert on public.shift_interest to authenticated;

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
revoke execute on function public.guard_shift() from public, anon, authenticated;
drop trigger if exists guard_shift on public.shifts;
create trigger guard_shift before insert or update on public.shifts
  for each row execute function public.guard_shift();

-- People who roster see approved leave dates and types (never the reasons),
-- so a shift isn't given to someone on leave.
drop policy if exists "people who roster see leave dates" on public.leave_periods;
create policy "people who roster see leave dates" on public.leave_periods
  for select to authenticated using ((select public.can('ops.roster', 'view')));

-- Tell workers about published or changed shifts, and the day before.
-- Server only (the roster screen calls it after publishing; the hourly timer too).
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

-- Switched over from the start: managers, staff admins and Payroll & Rostering.
update public.app_modules set grant_ready = true where id = 'ops.roster' and not grant_ready;
insert into public.access_baselines (access_level, module_id, actions, scope, note)
select l::public.app_role, 'ops.roster', '{}', 'all', 'Rostering default: people who manage staff'
  from unnest(array['manager', 'staff_admin']) l
 where not exists (select 1 from public.access_baselines b where b.module_id = 'ops.roster' and b.revoked_at is null and b.access_level = l::public.app_role);
insert into public.access_baselines (job_title_id, module_id, actions, scope, note)
select j.id, 'ops.roster', '{view,edit}', 'all', 'Rostering default: Payroll & Rostering'
  from public.job_titles j
 where j.name = 'Payroll & Rostering' and j.active
   and not exists (select 1 from public.access_baselines b where b.module_id = 'ops.roster' and b.revoked_at is null and b.job_title_id = j.id);
insert into public.function_group_modules (function_group_id, module_id)
select g.id, 'ops.roster' from public.function_groups g where g.key in ('hr_workforce', 'management_admin')
on conflict do nothing;
