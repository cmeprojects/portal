-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 149): incident management. An incident or issue becomes
-- its own record (INC-000001): created automatically when a worker ticks
-- "incident or issue" in their shift notes, or reported by staff. It moves
-- new -> acknowledged -> investigating -> closed, with a timeline of every step
-- and note. NDIS reportable incidents carry their category and a reporting
-- deadline (24 hours; 5 business days for unauthorised restrictive practice
-- with no harm), and record when and how they were reported to the Commission.
-- New part "Incidents" (Access page): managers every client, Case Managers
-- their assigned clients, Intake & Assessment Officers view. The worker who
-- reported one sees it. Nothing is deleted. No new security definer function.
-- Safe to run again.

insert into public.app_modules (id, parent_id, category, label, sensitivity, delegable, sort_order, actions, grant_ready) values
  ('clients.incidents', 'clients.list', 'clients', 'Incidents', 'sensitive', true, 265, '{view,edit}', true)
on conflict (id) do nothing;
update public.app_modules set status = 'active' where id = 'clients.incidents' and status = 'retired'; -- run again after an undo
do $$
declare
  v_cm uuid := (select id from public.job_titles where name = 'Case Manager' and active limit 1);
  v_io uuid := (select id from public.job_titles where name = 'Intake & Assessment Officer' and active limit 1);
begin
  if not exists (select 1 from public.access_baselines where module_id = 'clients.incidents' and revoked_at is null) then
    insert into public.access_baselines (access_level, module_id, actions, scope, note, by_system_admin)
    values ('manager', 'clients.incidents', '{}', 'all', 'Incidents default: managers, every client', true);
    if v_cm is not null then
      insert into public.access_baselines (job_title_id, module_id, actions, scope, note, by_system_admin)
      values (v_cm, 'clients.incidents', '{view,edit}', 'assigned', 'Incidents default: case managers, assigned clients', true);
    end if;
    if v_io is not null then
      insert into public.access_baselines (job_title_id, module_id, actions, scope, note, by_system_admin)
      values (v_io, 'clients.incidents', '{view}', 'all', 'Incidents default: intake, view', true);
    end if;
  end if;
end $$;

create sequence if not exists public.client_incident_ref_seq;
create table if not exists public.client_incidents (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  ref text not null default ('INC-' || lpad(nextval('public.client_incident_ref_seq')::text, 6, '0')) unique,
  client_id uuid not null references public.car_clients (id),
  shift_id uuid references public.shifts (id) on delete set null,
  source text not null default 'staff' check (source in ('shift_note', 'staff')),
  occurred_at timestamptz not null default now(),
  reported_by uuid default auth.uid() references public.profiles (id),
  reported_at timestamptz not null default now(),
  kind text not null default 'other' check (kind in ('injury', 'fall', 'medication', 'behaviour', 'abuse_neglect', 'health', 'missing_person', 'property', 'complaint', 'restrictive_practice', 'other')),
  severity text not null default 'medium' check (severity in ('low', 'medium', 'high', 'critical')),
  summary text not null check (length(trim(summary)) between 1 and 4000),
  immediate_action text not null default '' check (length(immediate_action) <= 2000),
  status text not null default 'new' check (status in ('new', 'acknowledged', 'investigating', 'closed')),
  reportable boolean not null default false,
  reportable_category text check (reportable_category is null or reportable_category in ('death', 'serious_injury', 'abuse_neglect', 'unlawful_contact', 'sexual_misconduct', 'restrictive_practice')),
  report_due_at timestamptz,
  reported_to_regulator_at timestamptz,
  regulator_ref text not null default '' check (length(regulator_ref) <= 60),
  acknowledged_by uuid, acknowledged_at timestamptz,
  outcome text not null default '' check (length(outcome) <= 4000),
  closed_by uuid, closed_at timestamptz,
  told_at timestamptz, reminded_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists client_incidents_client on public.client_incidents (client_id, occurred_at desc);
create index if not exists client_incidents_open on public.client_incidents (status) where status <> 'closed';
create unique index if not exists client_incidents_one_per_shift_note on public.client_incidents (shift_id) where source = 'shift_note';

create table if not exists public.client_incident_events (
  id bigint generated always as identity primary key,
  incident_id uuid not null references public.client_incidents (id) on delete cascade,
  actor uuid default auth.uid(),
  kind text not null default 'note' check (kind in ('note', 'step')),
  body text not null check (length(trim(body)) between 1 and 4000),
  created_at timestamptz not null default now()
);
create index if not exists client_incident_events_incident on public.client_incident_events (incident_id, created_at);

alter table public.client_incidents enable row level security;
alter table public.client_incident_events enable row level security;
drop policy if exists "read incidents" on public.client_incidents;
create policy "read incidents" on public.client_incidents
  for select to authenticated
  using (reported_by = (select auth.uid()) or public.can('clients.incidents', 'view', client_id));
drop policy if exists "report incidents" on public.client_incidents;
create policy "report incidents" on public.client_incidents
  for insert to authenticated
  with check (reported_by = (select auth.uid())
              and (public.can('clients.incidents', 'edit', client_id)
                   -- a worker's own shift note (the shift's client or a resident on it)
                   or (source = 'shift_note' and shift_id in (select s.id from public.shifts s where s.worker_id = (select auth.uid())))));
drop policy if exists "manage incidents" on public.client_incidents;
create policy "manage incidents" on public.client_incidents
  for update to authenticated
  using (public.can('clients.incidents', 'edit', client_id))
  with check (public.can('clients.incidents', 'edit', client_id));
grant select, insert, update on public.client_incidents to authenticated;
revoke all on public.client_incidents from anon;
grant usage on sequence public.client_incident_ref_seq to authenticated;

drop policy if exists "read incident timeline" on public.client_incident_events;
create policy "read incident timeline" on public.client_incident_events
  for select to authenticated
  using (incident_id in (select i.id from public.client_incidents i));
drop policy if exists "add incident notes" on public.client_incident_events;
create policy "add incident notes" on public.client_incident_events
  for insert to authenticated
  with check (actor = (select auth.uid())
              and (pg_trigger_depth() > 0
                   or (kind = 'note' and incident_id in (select i.id from public.client_incidents i where public.can('clients.incidents', 'edit', i.client_id)))));
grant select, insert on public.client_incident_events to authenticated;
revoke all on public.client_incident_events from anon;

-- Five business days (Monday to Friday) after a moment.
create or replace function public.plus_business_days(p_from timestamptz, p_days int) returns timestamptz
language plpgsql immutable set search_path = '' as $$
declare
  v timestamptz := p_from;
  n int := 0;
begin
  while n < p_days loop
    v := v + interval '1 day';
    if extract(isodow from v at time zone 'Australia/Sydney') < 6 then n := n + 1; end if;
  end loop;
  return v;
end;
$$;

create or replace function public.guard_incident() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_step text;
begin
  if tg_op = 'INSERT' then
    new.reported_by := coalesce(auth.uid(), new.reported_by);
    new.reported_at := now();
    new.status := 'new';
    new.acknowledged_by := null; new.acknowledged_at := null; new.closed_by := null; new.closed_at := null;
    if new.occurred_at > now() + interval '1 hour' then
      raise exception 'An incident can''t be in the future.';
    end if;
  else
    if new.client_id <> old.client_id or new.ref <> old.ref or new.source <> old.source or new.reported_by is distinct from old.reported_by or new.reported_at <> old.reported_at then
      raise exception 'An incident stays with its client, reference and reporter.';
    end if;
    if old.status = 'closed' and new.status = 'closed' and (to_jsonb(new) - 'updated_at' - 'told_at' - 'reminded_at') <> (to_jsonb(old) - 'updated_at' - 'told_at' - 'reminded_at') then
      raise exception 'A closed incident stays as it was. Reopen it to change it.';
    end if;
    if new.status <> old.status then
      if new.status = 'acknowledged' and old.status = 'new' then
        new.acknowledged_by := auth.uid(); new.acknowledged_at := now(); v_step := 'acknowledged the incident';
      elsif new.status = 'investigating' and old.status in ('new', 'acknowledged') then
        if old.acknowledged_at is null then new.acknowledged_by := auth.uid(); new.acknowledged_at := now(); end if;
        v_step := 'started an investigation';
      elsif new.status = 'closed' then
        if length(trim(new.outcome)) = 0 then
          raise exception 'Write the outcome before closing the incident.';
        end if;
        if new.reportable and new.reported_to_regulator_at is null then
          raise exception 'This incident is reportable: record when it was reported to the NDIS Commission before closing it.';
        end if;
        new.closed_by := auth.uid(); new.closed_at := now(); v_step := 'closed the incident';
      elsif old.status = 'closed' then
        new.closed_by := null; new.closed_at := null; v_step := 'reopened the incident';
      else
        raise exception 'That step isn''t allowed.';
      end if;
    end if;
  end if;
  -- Reportable: a category and its deadline (from when staff became aware).
  if new.reportable then
    if new.reportable_category is null then
      raise exception 'Choose the reportable incident category.';
    end if;
    new.report_due_at := case when new.reportable_category = 'restrictive_practice'
                              then public.plus_business_days(new.reported_at, 5)
                              else new.reported_at + interval '24 hours' end;
  else
    new.reportable_category := null; new.report_due_at := null;
  end if;
  if tg_op = 'UPDATE' and new.reported_to_regulator_at is distinct from old.reported_to_regulator_at and new.reported_to_regulator_at is not null then
    v_step := coalesce(v_step || '; ', '') || 'recorded it was reported to the NDIS Commission' || case when new.regulator_ref <> '' then ' (' || new.regulator_ref || ')' else '' end;
  end if;
  if tg_op = 'UPDATE' and new.reportable and not old.reportable then
    v_step := coalesce(v_step || '; ', '') || 'marked it reportable';
  end if;
  new.updated_at := now();
  if tg_op = 'UPDATE' and v_step is not null then
    insert into public.client_incident_events (incident_id, actor, kind, body) values (new.id, auth.uid(), 'step', v_step);
  end if;
  return new;
end;
$$;
revoke execute on function public.guard_incident() from public, anon, authenticated;
drop trigger if exists guard_incident on public.client_incidents;
create trigger guard_incident before insert or update on public.client_incidents
  for each row execute function public.guard_incident();

create or replace function public.log_incident_created() returns trigger
language plpgsql set search_path = '' as $$
begin
  insert into public.client_incident_events (incident_id, actor, kind, body)
  values (new.id, auth.uid(), 'step', case when new.source = 'shift_note' then 'reported it in their shift notes' else 'reported the incident' end);
  return null;
end;
$$;
revoke execute on function public.log_incident_created() from public, anon, authenticated;
drop trigger if exists log_incident_created on public.client_incidents;
create trigger log_incident_created after insert on public.client_incidents
  for each row execute function public.log_incident_created();

-- A shift note with "incident or issue" becomes an incident (once per shift note).
-- The shift-note notice already tells managers and the case manager, so it's marked told.
create or replace function public.incident_from_shift_note() returns trigger
language plpgsql set search_path = '' as $$
begin
  if new.concern and (tg_op = 'INSERT' or not old.concern) and new.client_id is not null
     and not exists (select 1 from public.client_incidents i where i.shift_id = new.shift_id and i.source = 'shift_note') then
    insert into public.client_incidents (client_id, shift_id, source, occurred_at, summary, told_at)
    select new.client_id, new.shift_id, 'shift_note', least(s.ends_at, now()), coalesce(nullif(trim(new.concern_note), ''), 'Reported in the shift notes.'), now()
      from public.shifts s where s.id = new.shift_id;
  end if;
  return null;
end;
$$;
revoke execute on function public.incident_from_shift_note() from public, anon, authenticated;
drop trigger if exists incident_from_shift_note on public.shift_service_records;
create trigger incident_from_shift_note after insert or update on public.shift_service_records
  for each row execute function public.incident_from_shift_note();

-- Notices (run by the server each hour and straight after a report): new incidents
-- reported by staff, and reportable ones due within 2 hours or overdue (once each).
create or replace function public.run_incident_alerts() returns jsonb
language plpgsql set search_path = '' as $$
declare
  r record;
  v_new int := 0;
  v_due int := 0;
begin
  for r in
    select i.id, i.ref, i.client_id, c.name, c.client_ref from public.client_incidents i join public.car_clients c on c.id = i.client_id
     where i.told_at is null and i.status <> 'closed'
  loop
    perform public.notify(u, 'incident', 'Incident ' || r.ref || ' reported', r.name || ' (' || r.client_ref || '). Open the portal to read it.', '/incidents/' || r.id, true)
      from (select p.id as u from public.profiles p where p.active and p.role = 'manager'
            union select c.u from public.client_care_contacts(r.client_id) c(u)) x;
    update public.client_incidents set told_at = now() where id = r.id;
    v_new := v_new + 1;
  end loop;
  for r in
    select i.id, i.ref, i.client_id, i.report_due_at, c.name, c.client_ref from public.client_incidents i join public.car_clients c on c.id = i.client_id
     where i.reportable and i.reported_to_regulator_at is null and i.status <> 'closed' and i.reminded_at is null
       and i.report_due_at < now() + interval '2 hours'
  loop
    perform public.notify(u, 'incident_report_due', 'Report ' || r.ref || ' to the NDIS Commission' || case when r.report_due_at < now() then ' (overdue)' else ' by ' || to_char(r.report_due_at at time zone 'Australia/Sydney', 'HH24:MI DD Mon') end, r.name || ' (' || r.client_ref || ')', '/incidents/' || r.id, true)
      from (select p.id as u from public.profiles p where p.active and p.role = 'manager'
            union select c.u from public.client_care_contacts(r.client_id) c(u)) x;
    update public.client_incidents set reminded_at = now() where id = r.id;
    v_due := v_due + 1;
  end loop;
  return jsonb_build_object('new_incidents', v_new, 'report_due', v_due);
end;
$$;
revoke execute on function public.run_incident_alerts() from public, anon, authenticated;
grant execute on function public.run_incident_alerts() to service_role;
