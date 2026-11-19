-- Staff Portal · © cmeproject. All rights reserved.
-- Update 149: client incident management (report, triage, investigation, sign-off).
-- Safe to run again. Undo: undo-149.sql.
begin;
insert into public.app_modules (id, parent_id, category, label, sensitivity, delegable, sort_order, actions, grant_ready) values
  ('clients.incidents', 'clients.list', 'clients', 'Incidents', 'sensitive', true, 265, '{view,edit,approve}', true)
on conflict (id) do nothing;
update public.app_modules set actions = '{view,edit,approve}' where id = 'clients.incidents' and not ('approve' = any (actions));
update public.app_modules set status = 'active' where id = 'clients.incidents' and status = 'retired'; -- run again after an undo
do $$
declare
  v_cm uuid := (select id from public.job_titles where name = 'Case Manager' and active limit 1);
  v_io uuid := (select id from public.job_titles where name = 'Intake & Assessment Officer' and active limit 1);
  v_tl uuid := (select id from public.job_titles where name = 'Team Leader' and active limit 1);
begin
  if not exists (select 1 from public.access_baselines where module_id = 'clients.incidents' and revoked_at is null) then
    insert into public.access_baselines (access_level, module_id, actions, scope, note, by_system_admin)
    values ('manager', 'clients.incidents', '{}', 'all', 'Incidents default: managers, every client', true);
    if v_cm is not null then
      insert into public.access_baselines (job_title_id, module_id, actions, scope, note, by_system_admin)
      values (v_cm, 'clients.incidents', '{view,edit}', 'assigned', 'Incidents default: case managers, assigned clients', true);
    end if;
    if v_tl is not null then
      insert into public.access_baselines (job_title_id, module_id, actions, scope, note, by_system_admin)
      values (v_tl, 'clients.incidents', '{view,edit}', 'assigned', 'Incidents default: team leaders, assigned clients (as case managers)', true);
    end if;
    if v_io is not null then
      insert into public.access_baselines (job_title_id, module_id, actions, scope, note, by_system_admin)
      values (v_io, 'clients.incidents', '{view}', 'all', 'Incidents default: intake, view', true);
    end if;
  end if;
  -- Team Leaders: the same as Case Managers (owner, 19 Nov 2026); added on a re-run too.
  if v_tl is not null and not exists (select 1 from public.access_baselines where module_id = 'clients.incidents' and job_title_id = v_tl and revoked_at is null) then
    insert into public.access_baselines (job_title_id, module_id, actions, scope, note, by_system_admin)
    values (v_tl, 'clients.incidents', '{view,edit}', 'assigned', 'Incidents default: team leaders, assigned clients (as case managers)', true);
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
  location text not null default '' check (length(location) <= 200),
  reported_by uuid default auth.uid() references public.profiles (id),
  reported_at timestamptz not null default now(),
  kind text not null default 'other' check (kind in ('injury', 'fall', 'medication', 'behaviour', 'abuse_neglect', 'health', 'missing_person', 'property', 'complaint', 'restrictive_practice', 'near_miss', 'other')),
  severity text not null default 'medium' check (severity in ('low', 'medium', 'high', 'critical')),
  summary text not null check (length(trim(summary)) between 1 and 4000),
  immediate_action text not null default '' check (length(immediate_action) <= 2000),
  status text not null default 'new' check (status in ('new', 'investigating', 'review', 'closed')),
  -- triage
  triaged_by uuid, triaged_at timestamptz,
  investigator_id uuid references public.profiles (id),
  reportable boolean not null default false,
  reportable_category text check (reportable_category is null or reportable_category in ('death', 'serious_injury', 'abuse_neglect', 'unlawful_contact', 'sexual_misconduct', 'restrictive_practice')),
  report_due_at timestamptz,
  reported_to_regulator_at timestamptz,
  regulator_ref text not null default '' check (length(regulator_ref) <= 60),
  -- investigation
  staff_involved uuid references public.profiles (id),
  witnesses text not null default '' check (length(witnesses) <= 1000),
  findings text not null default '' check (length(findings) <= 4000),
  contributing_factors text not null default '' check (length(contributing_factors) <= 2000),
  family_told_at timestamptz,
  family_told_note text not null default '' check (length(family_told_note) <= 1000),
  sent_for_review_by uuid, sent_for_review_at timestamptz,
  -- sign-off
  outcome text not null default '' check (length(outcome) <= 4000),
  closed_by uuid, closed_at timestamptz,
  -- notices sent
  told_at timestamptz, reminded_at timestamptz, investigator_told uuid, review_told_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists client_incidents_client on public.client_incidents (client_id, occurred_at desc);
create index if not exists client_incidents_open on public.client_incidents (status) where status <> 'closed';
create index if not exists client_incidents_investigator on public.client_incidents (investigator_id) where status <> 'closed';
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

create table if not exists public.client_incident_actions (
  id uuid primary key default gen_random_uuid(),
  incident_id uuid not null references public.client_incidents (id) on delete cascade,
  action text not null check (length(trim(action)) between 1 and 500),
  owner_id uuid not null references public.profiles (id),
  due_on date not null,
  done_at timestamptz, done_by uuid,
  done_note text not null default '' check (length(done_note) <= 1000),
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  told_at timestamptz, reminded_at timestamptz
);
create index if not exists client_incident_actions_incident on public.client_incident_actions (incident_id);
create index if not exists client_incident_actions_open on public.client_incident_actions (owner_id, due_on) where done_at is null;

alter table public.client_incidents enable row level security;
alter table public.client_incident_events enable row level security;
alter table public.client_incident_actions enable row level security;
drop policy if exists "read incidents" on public.client_incidents;
create policy "read incidents" on public.client_incidents
  for select to authenticated
  using (reported_by = (select auth.uid()) or investigator_id = (select auth.uid()) or public.can('clients.incidents', 'view', client_id));
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
  using (public.can('clients.incidents', 'edit', client_id) or investigator_id = (select auth.uid()))
  with check (public.can('clients.incidents', 'edit', client_id) or investigator_id = (select auth.uid()));
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
                   or (kind = 'note' and incident_id in (select i.id from public.client_incidents i
                                                          where public.can('clients.incidents', 'edit', i.client_id) or i.investigator_id = (select auth.uid())))));
grant select, insert on public.client_incident_events to authenticated;
revoke all on public.client_incident_events from anon;

drop policy if exists "read incident actions" on public.client_incident_actions;
create policy "read incident actions" on public.client_incident_actions
  for select to authenticated
  using (owner_id = (select auth.uid()) or incident_id in (select i.id from public.client_incidents i));
drop policy if exists "add incident actions" on public.client_incident_actions;
create policy "add incident actions" on public.client_incident_actions
  for insert to authenticated
  with check (created_by = (select auth.uid())
              and incident_id in (select i.id from public.client_incidents i
                                   where i.status in ('new', 'investigating', 'review')
                                     and (public.can('clients.incidents', 'edit', i.client_id) or i.investigator_id = (select auth.uid()))));
drop policy if exists "update incident actions" on public.client_incident_actions;
create policy "update incident actions" on public.client_incident_actions
  for update to authenticated
  using (owner_id = (select auth.uid())
         or incident_id in (select i.id from public.client_incidents i
                             where public.can('clients.incidents', 'edit', i.client_id) or i.investigator_id = (select auth.uid())));
grant select, insert, update on public.client_incident_actions to authenticated;
revoke all on public.client_incident_actions from anon;

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
  v_edit boolean;
  v_approve boolean;
  v_inv_only boolean;
  v_name text;
  k text;
begin
  if tg_op = 'INSERT' then
    new.reported_by := coalesce(auth.uid(), new.reported_by);
    new.reported_at := now();
    new.status := 'new';
    new.triaged_by := null; new.triaged_at := null; new.investigator_id := null;
    new.sent_for_review_by := null; new.sent_for_review_at := null; new.closed_by := null; new.closed_at := null;
    new.findings := ''; new.contributing_factors := ''; new.outcome := ''; new.family_told_at := null;
    if new.occurred_at > now() + interval '1 hour' then
      raise exception 'An incident can''t be in the future.';
    end if;
  else
    -- The alerts job (service role) only stamps its notice columns.
    if auth.uid() is null then
      new.updated_at := now();
      return new;
    end if;
    if new.client_id <> old.client_id or new.ref <> old.ref or new.source <> old.source or new.reported_by is distinct from old.reported_by
       or new.reported_at <> old.reported_at or new.shift_id is distinct from old.shift_id then
      raise exception 'An incident stays with its client, reference and reporter.';
    end if;
    v_edit := public.can('clients.incidents', 'edit', new.client_id);
    v_approve := public.can('clients.incidents', 'approve', new.client_id);
    v_inv_only := not v_edit and old.investigator_id = auth.uid();
    if old.status = 'closed' and new.status = 'closed' and (to_jsonb(new) - 'updated_at' - 'told_at' - 'reminded_at' - 'investigator_told' - 'review_told_at') <> (to_jsonb(old) - 'updated_at' - 'told_at' - 'reminded_at' - 'investigator_told' - 'review_told_at') then
      raise exception 'A closed incident stays as it was. Reopen it to change it.';
    end if;
    -- The investigator (without Incidents: edit) fills in the investigation only.
    if v_inv_only then
      if old.status <> 'investigating' then
        raise exception 'The investigation can be changed while the incident is under investigation.';
      end if;
      foreach k in array array['kind', 'severity', 'summary', 'occurred_at', 'location', 'immediate_action', 'investigator_id', 'reportable', 'reportable_category', 'reported_to_regulator_at', 'regulator_ref', 'outcome'] loop
        if to_jsonb(new) -> k is distinct from to_jsonb(old) -> k then
          raise exception 'Only a manager can change that. The investigator fills in the investigation.';
        end if;
      end loop;
      if new.status not in ('investigating', 'review') then
        raise exception 'The investigator can send the incident for sign-off.';
      end if;
    end if;
    if new.status <> old.status then
      if old.status = 'new' and new.status = 'investigating' then
        -- Triage: the decision on reportable, and someone to investigate.
        if new.investigator_id is null then
          raise exception 'Choose who will investigate.';
        end if;
        new.triaged_by := auth.uid(); new.triaged_at := now();
        select coalesce(nullif(full_name, ''), email) into v_name from public.profiles where id = new.investigator_id;
        v_step := 'triaged it (' || new.severity || case when new.reportable then ', NDIS reportable' else ', not reportable' end || ') and asked ' || coalesce(v_name, 'a staff member') || ' to investigate';
      elsif old.status = 'investigating' and new.status = 'review' then
        if length(trim(new.findings)) = 0 then
          raise exception 'Write what the investigation found before sending it for sign-off.';
        end if;
        if new.family_told_at is null and length(trim(new.family_told_note)) = 0 then
          raise exception 'Record when the client or their family were told, or why they weren''t.';
        end if;
        new.sent_for_review_by := auth.uid(); new.sent_for_review_at := now(); new.review_told_at := null;
        v_step := 'sent it for sign-off';
      elsif old.status = 'review' and new.status = 'closed' then
        if not v_approve then
          raise exception 'Signing off an incident needs Incidents: approve.';
        end if;
        if length(trim(new.outcome)) = 0 then
          raise exception 'Write the outcome before signing off.';
        end if;
        if new.reportable and new.reported_to_regulator_at is null then
          raise exception 'This incident is reportable: record when it was reported to the NDIS Commission before closing it.';
        end if;
        if exists (select 1 from public.client_incident_actions a where a.incident_id = new.id and a.done_at is null) then
          raise exception 'Every action needs to be done before the incident is signed off.';
        end if;
        new.closed_by := auth.uid(); new.closed_at := now(); v_step := 'signed it off and closed it';
      elsif old.status = 'review' and new.status = 'investigating' then
        if not v_approve then
          raise exception 'Sending an incident back needs Incidents: approve.';
        end if;
        v_step := 'sent it back for more investigation';
      elsif old.status = 'closed' and new.status = 'investigating' then
        if not v_approve then
          raise exception 'Reopening an incident needs Incidents: approve.';
        end if;
        new.closed_by := null; new.closed_at := null; v_step := 'reopened the incident';
      else
        raise exception 'That step isn''t allowed.';
      end if;
    elsif new.status <> 'new' and new.investigator_id is null then
      raise exception 'An incident under investigation needs an investigator.';
    end if;
    if new.investigator_id is distinct from old.investigator_id and old.status <> 'new' and new.status = old.status then
      select coalesce(nullif(full_name, ''), email) into v_name from public.profiles where id = new.investigator_id;
      v_step := coalesce(v_step || '; ', '') || 'changed the investigator to ' || coalesce(v_name, 'a staff member');
    end if;
    if new.family_told_at is distinct from old.family_told_at and new.family_told_at is not null then
      v_step := coalesce(v_step || '; ', '') || 'recorded the client or family were told';
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
  if tg_op = 'UPDATE' and new.reportable and not old.reportable and old.status <> 'new' then
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

create or replace function public.guard_incident_action() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_owner text;
begin
  if tg_op = 'INSERT' then
    new.created_by := coalesce(auth.uid(), new.created_by);
    new.created_at := now(); new.done_at := null; new.done_by := null; new.told_at := null; new.reminded_at := null;
    if not exists (select 1 from public.profiles p where p.id = new.owner_id and p.active) then
      raise exception 'Choose an active staff member for the action.';
    end if;
    select coalesce(nullif(full_name, ''), email) into v_owner from public.profiles where id = new.owner_id;
    insert into public.client_incident_events (incident_id, actor, kind, body)
    values (new.incident_id, auth.uid(), 'step', 'added an action for ' || coalesce(v_owner, 'a staff member') || ', due ' || to_char(new.due_on, 'DD Mon YYYY') || ': ' || new.action);
    return new;
  end if;
  if auth.uid() is null then return new; end if; -- the alerts job stamps its notice columns
  if new.incident_id <> old.incident_id or new.created_by is distinct from old.created_by or new.created_at <> old.created_at then
    raise exception 'An action stays with its incident.';
  end if;
  if exists (select 1 from public.client_incidents i where i.id = new.incident_id and i.status = 'closed') then
    raise exception 'The incident is closed. Reopen it to change its actions.';
  end if;
  -- The owner (if they don't manage the incident) only marks it done.
  if old.owner_id = auth.uid() and not exists (select 1 from public.client_incidents i where i.id = new.incident_id
                                                 and (public.can('clients.incidents', 'edit', i.client_id) or i.investigator_id = auth.uid()))
     and (new.action <> old.action or new.owner_id <> old.owner_id or new.due_on <> old.due_on) then
    raise exception 'Only the investigator or a manager can change the action. You can mark it done.';
  end if;
  if new.owner_id <> old.owner_id then
    new.told_at := null; new.reminded_at := null;
  end if;
  if new.due_on <> old.due_on then new.reminded_at := null; end if;
  if new.done_at is not null and old.done_at is null then
    new.done_at := now(); new.done_by := auth.uid();
    insert into public.client_incident_events (incident_id, actor, kind, body)
    values (new.incident_id, auth.uid(), 'step', 'completed the action: ' || new.action || case when new.done_note <> '' then ' (' || new.done_note || ')' else '' end);
  elsif new.done_at is null and old.done_at is not null then
    new.done_by := null;
    insert into public.client_incident_events (incident_id, actor, kind, body)
    values (new.incident_id, auth.uid(), 'step', 'reopened the action: ' || new.action);
  elsif new.done_at is distinct from old.done_at then
    new.done_at := old.done_at;
  end if;
  return new;
end;
$$;
revoke execute on function public.guard_incident_action() from public, anon, authenticated;
drop trigger if exists guard_incident_action on public.client_incident_actions;
create trigger guard_incident_action before insert or update on public.client_incident_actions
  for each row execute function public.guard_incident_action();

create or replace function public.incident_from_shift_note() returns trigger
language plpgsql set search_path = '' as $$
begin
  if new.concern and (tg_op = 'INSERT' or not old.concern) and new.client_id is not null
     and not exists (select 1 from public.client_incidents i where i.shift_id = new.shift_id and i.source = 'shift_note') then
    insert into public.client_incidents (client_id, shift_id, source, occurred_at, summary, staff_involved, told_at)
    select new.client_id, new.shift_id, 'shift_note', least(s.ends_at, now()), coalesce(nullif(trim(new.concern_note), ''), 'Reported in the shift notes.'), s.worker_id, now()
      from public.shifts s where s.id = new.shift_id;
  end if;
  return null;
end;
$$;
revoke execute on function public.incident_from_shift_note() from public, anon, authenticated;
drop trigger if exists incident_from_shift_note on public.shift_service_records;
create trigger incident_from_shift_note after insert or update on public.shift_service_records
  for each row execute function public.incident_from_shift_note();

create or replace function public.run_incident_alerts() returns jsonb
language plpgsql set search_path = '' as $$
declare
  r record;
  v_new int := 0;
  v_due int := 0;
  v_inv int := 0;
  v_rev int := 0;
  v_act int := 0;
begin
  for r in
    select i.id, i.ref, i.client_id, c.name, c.client_ref from public.client_incidents i join public.car_clients c on c.id = i.client_id
     where i.told_at is null and i.status <> 'closed'
  loop
    perform public.notify(u, 'incident', 'Incident ' || r.ref || ' reported', r.name || ' (' || r.client_ref || '). Open the portal to triage it.', '/incidents/' || r.id, true)
      from (select p.id as u from public.profiles p where p.active and p.role = 'manager'
            union select c.u from public.client_care_contacts(r.client_id) c(u)) x;
    update public.client_incidents set told_at = now() where id = r.id;
    v_new := v_new + 1;
  end loop;
  for r in
    select i.id, i.ref, i.investigator_id, c.name, c.client_ref from public.client_incidents i join public.car_clients c on c.id = i.client_id
     where i.status = 'investigating' and i.investigator_id is not null and i.investigator_told is distinct from i.investigator_id
  loop
    perform public.notify(r.investigator_id, 'incident_investigate', 'You''re investigating incident ' || r.ref, r.name || ' (' || r.client_ref || ')', '/incidents/' || r.id, true);
    update public.client_incidents set investigator_told = r.investigator_id where id = r.id;
    v_inv := v_inv + 1;
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
  for r in
    select i.id, i.ref, c.name, c.client_ref from public.client_incidents i join public.car_clients c on c.id = i.client_id
     where i.status = 'review' and i.review_told_at is null
  loop
    perform public.notify(p.id, 'incident_review', 'Incident ' || r.ref || ' is ready for sign-off', r.name || ' (' || r.client_ref || ')', '/incidents/' || r.id, true)
      from public.profiles p where p.active and p.role = 'manager';
    update public.client_incidents set review_told_at = now() where id = r.id;
    v_rev := v_rev + 1;
  end loop;
  for r in
    select a.id, a.owner_id, a.action, a.due_on, a.told_at, i.id as incident_id, i.ref, i.investigator_id
      from public.client_incident_actions a join public.client_incidents i on i.id = a.incident_id
     where a.done_at is null and i.status <> 'closed'
       and (a.told_at is null or (a.reminded_at is null and a.due_on < (now() at time zone 'Australia/Sydney')::date))
  loop
    if r.told_at is null then
      perform public.notify(r.owner_id, 'incident_action', 'Action for incident ' || r.ref || ', due ' || to_char(r.due_on, 'DD Mon'), left(r.action, 200), '/incidents/' || r.incident_id, true);
      update public.client_incident_actions set told_at = now() where id = r.id;
    else
      perform public.notify(u, 'incident_action_overdue', 'Overdue action on incident ' || r.ref, left(r.action, 200), '/incidents/' || r.incident_id, true)
        from (select r.owner_id as u union select r.investigator_id where r.investigator_id is not null) x;
      update public.client_incident_actions set reminded_at = now() where id = r.id;
    end if;
    v_act := v_act + 1;
  end loop;
  return jsonb_build_object('new_incidents', v_new, 'investigators', v_inv, 'report_due', v_due, 'sign_off', v_rev, 'actions', v_act);
end;
$$;
revoke execute on function public.run_incident_alerts() from public, anon, authenticated;
grant execute on function public.run_incident_alerts() to service_role;

alter table public.registries drop constraint if exists registries_prefix_format;
alter table public.registries add constraint registries_prefix_format check (prefix ~ '^[A-Z0-9]{2,6}(-[A-Z0-9]{2,6})?$');
alter table public.register_templates drop constraint if exists register_templates_prefix_check;
alter table public.register_templates add constraint register_templates_prefix_check check (prefix ~ '^[A-Z0-9]{2,6}(-[A-Z0-9]{2,6})?$');
update public.register_templates
   set name = 'Workplace Incident Register', prefix = 'WRK-INC',
       description = 'Staff injuries, WHS hazards, near misses and property incidents. Client incidents are recorded under Incidents.'
 where key = 'incidents' and (name = 'Incident Register' or prefix = 'INC');
update public.registries
   set name = 'Workplace Incident Register',
       prefix = case when prefix = 'INC' and not exists (select 1 from public.registries r2 where r2.prefix = 'WRK-INC') then 'WRK-INC' else prefix end,
       description = 'Staff injuries, WHS hazards, near misses and property incidents. Client incidents are recorded under Incidents.'
 where name in ('Incident Register', 'Workplace Incident Register');
commit;
