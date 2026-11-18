-- Staff Portal · © cmeproject. All rights reserved.
-- Update 129: shift templates; notices for declined, cancelled and unfilled
-- shifts. Safe to run again. Undo: undo-129.sql. Run update 128 first.
begin;
create table if not exists public.shift_templates (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  name text not null check (length(trim(name)) between 1 and 80),
  shift_type text not null default 'standard',
  start_time time not null,
  end_time time not null,
  break_minutes integer not null default 0 check (break_minutes between 0 and 240),
  client_id uuid references public.car_clients (id) on delete set null,
  service_id uuid references public.client_services (id) on delete set null,
  location_id uuid references public.client_locations (id) on delete set null,
  notes text not null default '' check (length(notes) <= 500),
  allowances text[] not null default '{}' check (cardinality(allowances) <= 10),
  pay_group text not null default '' check (length(pay_group) <= 60),
  needs_worker_signature boolean not null default false,
  needs_client_signature boolean not null default false,
  active boolean not null default true,
  created_by uuid references public.profiles (id) default auth.uid(),
  created_at timestamptz not null default now()
);
create unique index if not exists shift_templates_name on public.shift_templates (lower(name)) where active;
alter table public.shift_templates enable row level security;
drop policy if exists "people who roster see templates" on public.shift_templates;
create policy "people who roster see templates" on public.shift_templates
  for select to authenticated using ((select public.can('ops.roster', 'edit')));
drop policy if exists "people who roster add templates" on public.shift_templates;
create policy "people who roster add templates" on public.shift_templates
  for insert to authenticated with check ((select public.can('ops.roster', 'edit')));
drop policy if exists "people who roster change templates" on public.shift_templates;
create policy "people who roster change templates" on public.shift_templates
  for update to authenticated using ((select public.can('ops.roster', 'edit'))) with check ((select public.can('ops.roster', 'edit')));
-- No delete rule: templates are switched off, not deleted.
grant select, insert, update on public.shift_templates to authenticated;

-- The people who roster: managers, staff admins and job titles with roster edit access.
create or replace function public.roster_people()
returns setof uuid
language sql
stable
security invoker
set search_path = ''
as $$
  select u.id from public.profiles u
   where u.active and (u.role in ('manager', 'staff_admin')
         or u.job_title_id in (select b.job_title_id from public.access_baselines b
                                where b.module_id = 'ops.roster' and b.revoked_at is null and b.job_title_id is not null
                                  and (b.actions = '{}' or 'edit' = any (b.actions))))
$$;
revoke execute on function public.roster_people() from public, anon, authenticated;
grant execute on function public.roster_people() to service_role;

CREATE OR REPLACE FUNCTION public.run_roster_alerts()
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare
  r record;
  v_new int := 0;
  v_tomorrow int := 0;
  v_requests int := 0;
  v_decided int := 0;
  v_queried int := 0;
  v_declined int := 0;
  v_cancelled int := 0;
  v_unfilled int := 0;
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
  -- New requests: to the people who roster (managers, staff admins, and job titles with roster edit access).
  for r in
    select q.id, q.kind, p.full_name, p.email from public.shift_change_requests q join public.profiles p on p.id = q.requested_by
     where q.status = 'pending' and q.roster_told_at is null
  loop
    perform public.notify(u.id, 'shift_request',
      coalesce(nullif(r.full_name, ''), r.email) || case when r.kind = 'swap' then ' asked to swap a shift' else ' can''t work a shift' end,
      'Shift change requests', '/roster?requests=1', false)
      from public.profiles u
     where u.active and (u.role in ('manager', 'staff_admin')
                         or u.job_title_id in (select b.job_title_id from public.access_baselines b
                                              where b.module_id = 'ops.roster' and b.revoked_at is null and b.job_title_id is not null
                                                and (b.actions = '{}' or 'edit' = any (b.actions))));
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
  -- cmeprojects (update 129): a worker declined: tell the people who roster (once per answer).
  for r in
    select q.shift_id, q.note, q.responded_at, s.starts_at, coalesce(nullif(p.full_name, ''), p.email) as who
      from public.shift_responses q join public.shifts s on s.id = q.shift_id join public.profiles p on p.id = q.worker_id
     where q.response = 'declined' and s.status = 'published' and s.ends_at > now()
       and not exists (select 1 from public.care_alerts_sent a where a.kind = 'shift_declined' and a.item_id = q.shift_id
                        and a.due_on = (q.responded_at at time zone 'Australia/Sydney')::date)
  loop
    insert into public.care_alerts_sent (kind, item_id, due_on) values ('shift_declined', r.shift_id, (r.responded_at at time zone 'Australia/Sydney')::date)
    on conflict do nothing;
    perform public.notify(u, 'shift_declined',
      r.who || ' declined the shift on ' || to_char(r.starts_at at time zone 'Australia/Sydney', 'Dy DD Mon, HH24:MI'),
      coalesce(nullif(r.note, ''), 'Give it to someone else or make it an open shift.'), '/roster?shift=' || r.shift_id, true)
      from public.roster_people() u;
    v_declined := v_declined + 1;
  end loop;
  -- A shift the worker was told about was cancelled: tell them (once).
  for r in
    select s.id, s.worker_id, s.starts_at, c.name as client
      from public.shifts s left join public.car_clients c on c.id = s.client_id
     where s.status = 'cancelled' and s.worker_id is not null and s.ends_at > now()
       and (s.notified_at is not null or exists (select 1 from public.shift_events e where e.shift_id = s.id and e.summary = 'told the worker'))
       and not exists (select 1 from public.care_alerts_sent a where a.kind = 'shift_cancelled' and a.item_id = s.id)
  loop
    insert into public.care_alerts_sent (kind, item_id, due_on) values ('shift_cancelled', r.id, (r.starts_at at time zone 'Australia/Sydney')::date)
    on conflict do nothing;
    perform public.notify(r.worker_id, 'shift_cancelled',
      'Cancelled: your shift on ' || to_char(r.starts_at at time zone 'Australia/Sydney', 'Dy DD Mon, HH24:MI'), coalesce(r.client, 'See My shifts'), '/my-shifts', true);
    v_cancelled := v_cancelled + 1;
  end loop;
  -- Still not filled 48 hours before it starts (vacant, or the worker declined): tell the people who roster (once).
  for r in
    select s.id, s.starts_at, c.name as client
      from public.shifts s left join public.car_clients c on c.id = s.client_id
     where s.status = 'published' and s.starts_at > now() and s.starts_at <= now() + interval '48 hours'
       and (s.worker_id is null or exists (select 1 from public.shift_responses q where q.shift_id = s.id and q.response = 'declined'))
       and not exists (select 1 from public.care_alerts_sent a where a.kind = 'shift_unfilled' and a.item_id = s.id)
  loop
    insert into public.care_alerts_sent (kind, item_id, due_on) values ('shift_unfilled', r.id, (r.starts_at at time zone 'Australia/Sydney')::date)
    on conflict do nothing;
    perform public.notify(u, 'shift_unfilled',
      'Not filled yet: shift on ' || to_char(r.starts_at at time zone 'Australia/Sydney', 'Dy DD Mon, HH24:MI'), coalesce(r.client, 'Open the roster'), '/roster?shift=' || r.id, true)
      from public.roster_people() u;
    v_unfilled := v_unfilled + 1;
  end loop;
  return jsonb_build_object('shifts_notified', v_new, 'shift_reminders', v_tomorrow, 'requests_notified', v_requests, 'requests_decided', v_decided, 'timesheets_queried', v_queried, 'declined', v_declined, 'cancelled', v_cancelled, 'unfilled', v_unfilled);
end;
$function$;
revoke execute on function public.run_roster_alerts() from public, anon, authenticated;
grant execute on function public.run_roster_alerts() to service_role;
commit;
