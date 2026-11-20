-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 155): the client audit trail. Builds on what is there:
-- the change log (audit_log, which can't be changed or deleted) and the
-- existing client change trigger (log_client_change), which until now only
-- said "added" or "changed". Now each entry also says which fields changed,
-- who did it (and their role at the time), where from, and the outcome, and
-- removals are recorded. The before and after values go in a companion table
-- that only the system admin can read. The trigger now also covers the client
-- record itself, staff assignments, service locations and the communication
-- log. The trail is shown in the client's profile (Activity tab) to the
-- system admin, Manager Administrators and people who assign staff to that
-- client. Opening the trail is recorded too.
-- No new security definer function (log_client_change already was one; it is
-- updated in place). Nothing is deleted. Safe to run again.

-- 1. Before and after values: the system admin only. Written by the trigger.
create table if not exists public.client_audit_values (
  audit_id bigint primary key references public.audit_log (id),
  client_id uuid not null,
  changes jsonb not null,
  created_at timestamptz not null default now()
);
create index if not exists client_audit_values_client on public.client_audit_values (client_id);
alter table public.client_audit_values enable row level security;
drop policy if exists "system admin reads client changes" on public.client_audit_values;
create policy "system admin reads client changes" on public.client_audit_values
  for select to authenticated using ((select public.is_system_admin()));
grant select on public.client_audit_values to authenticated;
revoke all on public.client_audit_values from anon;
drop trigger if exists client_audit_values_append_only on public.client_audit_values;
create trigger client_audit_values_append_only before update or delete on public.client_audit_values
  for each row execute function public.block_audit_changes();

-- 2. The client change trigger: fields, values, role, source, outcome; removals too.
create or replace function public.log_client_change() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  v_row jsonb := to_jsonb(case when tg_op = 'DELETE' then old else new end);
  v_old jsonb := case when tg_op = 'INSERT' then '{}'::jsonb else to_jsonb(old) end;
  v_client uuid := case when tg_table_name = 'car_clients' then (v_row ->> 'id')::uuid else (v_row ->> 'client_id')::uuid end;
  v_skip text[] := array['updated_at', 'updated_by', 'org_id', 'created_at', 'created_by', 'status_changed_at', 'status_changed_by'];
  v_changes jsonb := '{}'::jsonb;
  v_key text;
  v_val jsonb;
  v_action text;
  v_id bigint;
  v_headers jsonb := nullif(current_setting('request.headers', true), '')::jsonb;
  v_claims jsonb := nullif(current_setting('request.jwt.claims', true), '')::jsonb;
  -- Keep values short, and never keep anything secret-looking or a drawn signature.
  v_trim jsonb;
begin
  if tg_op = 'UPDATE' and tg_table_name <> 'car_clients' and (to_jsonb(new) ->> 'client_id') is distinct from (to_jsonb(old) ->> 'client_id') then
    raise exception 'This stays with its client. Add a new one for another client.';
  end if;
  -- Before the row is written: stamp who changed it and when (where the table
  -- has those columns). The entry itself is written after the row is saved, so
  -- an "add, or update if it's there" save isn't mistaken for an addition.
  if tg_when = 'BEFORE' then
    if tg_op = 'DELETE' then
      return old;
    end if;
    new := jsonb_populate_record(new, jsonb_build_object('updated_at', now(), 'updated_by', auth.uid()));
    return new;
  end if;

  for v_key, v_val in select key, value from jsonb_each(case when tg_op = 'DELETE' then v_old else v_row end) loop
    continue when v_key = any (v_skip) or v_key = 'client_id' or v_key ~* '(password|token|secret|signature_(data|image|svg|png))';
    if tg_op = 'UPDATE' then
      continue when (v_old -> v_key) is not distinct from v_val;
    elsif v_val is null or v_val = 'null'::jsonb or v_val = '""'::jsonb or v_val = '[]'::jsonb or v_val = '{}'::jsonb then
      continue;
    end if;
    v_trim := case when jsonb_typeof(v_val) = 'string' and length(v_val #>> '{}') > 300 then to_jsonb(left(v_val #>> '{}', 300) || '…')
                   when jsonb_typeof(v_val) in ('object', 'array') and length(v_val::text) > 600 then to_jsonb('(long value, not kept)'::text)
                   else v_val end;
    v_changes := v_changes || jsonb_build_object(v_key,
      case when tg_op = 'UPDATE' then
        jsonb_build_array(case when jsonb_typeof(v_old -> v_key) = 'string' and length(v_old ->> v_key) > 300 then to_jsonb(left(v_old ->> v_key, 300) || '…')
                               when jsonb_typeof(v_old -> v_key) in ('object', 'array') and length((v_old -> v_key)::text) > 600 then to_jsonb('(long value, not kept)'::text)
                               else v_old -> v_key end, v_trim)
      when tg_op = 'INSERT' then jsonb_build_array(null, v_trim)
      else jsonb_build_array(v_trim, null) end);
  end loop;

  -- Saving without changing anything isn't recorded.
  if tg_op = 'UPDATE' and v_changes = '{}'::jsonb then
    return null;
  end if;

  v_action := tg_table_name || case
    when tg_op = 'DELETE' then '_removed'
    when tg_op = 'INSERT' and tg_table_name = 'client_documents' and (v_row ->> 'replaces_id') is not null then '_replaced'
    when tg_op = 'INSERT' then '_added'
    when v_changes ? 'archived_at' and (v_row ->> 'archived_at') is not null then '_archived'
    when v_changes ? 'archived_at' then '_restored'
    else '_changed' end;

  insert into public.audit_log (actor_id, action, entity, entity_id, details)
  values (auth.uid(), v_action, 'client', v_client::text, jsonb_build_object(
    'client', (select client_ref from public.car_clients where id = v_client),
    'item', coalesce(v_row ->> 'kind', v_row ->> 'label', v_row ->> 'title', v_row ->> 'name', v_row ->> 'file_name', ''),
    'table', tg_table_name,
    'record', coalesce(v_row ->> 'id', v_client::text),
    'fields', (select coalesce(jsonb_agg(k order by k), '[]'::jsonb) from jsonb_object_keys(v_changes) k),
    'version', v_row -> 'version',
    'role', (select role::text from public.profiles where id = auth.uid()),
    'source', case when auth.uid() is null then 'automation' when v_headers is null then 'database' else 'portal' end,
    'session', v_claims ->> 'session_id',
    'outcome', 'success'))
  returning id into v_id;
  if v_changes <> '{}'::jsonb then
    insert into public.client_audit_values (audit_id, client_id, changes) values (v_id, v_client, v_changes);
  end if;
  return null;
end;
$$;
revoke execute on function public.log_client_change() from public, anon, authenticated;

-- 3. The entry is written after each add, change or removal, on the tables
-- already covered and the ones not yet covered. (The existing before-triggers
-- keep stamping who changed it.)
do $$
declare t text;
begin
  foreach t in array array['client_agreements', 'client_alert_notes', 'client_alerts', 'client_care_goals', 'client_care_plans', 'client_comms',
    'client_details', 'client_documents', 'client_external_access', 'client_funding', 'client_people', 'client_practitioner_notes',
    'client_reviews', 'client_services', 'client_worker_instructions', 'client_assignments', 'client_locations', 'client_communications', 'car_clients'] loop
    continue when to_regclass('public.' || t) is null; -- a part not set up yet (for example update 147)
    execute format('drop trigger if exists log_client_removed on public.%I', t); -- an earlier draft
    execute format('drop trigger if exists log_client_audit on public.%I', t);
    execute format('create trigger log_client_audit after insert or update or delete on public.%I for each row execute function public.log_client_change()', t);
  end loop;
  foreach t in array array['client_assignments', 'client_locations', 'client_communications'] loop
    continue when to_regclass('public.' || t) is null; -- a part not set up yet (for example update 147)
    execute format('drop trigger if exists log_client_change on public.%I', t);
    execute format('create trigger log_client_change before insert or update on public.%I for each row execute function public.log_client_change()', t);
  end loop;
end $$;
-- The client record was copied whole into the change log; it now has field-by-field entries instead.
drop trigger if exists car_clients_log on public.car_clients;

-- 4. Who reads a client's trail: the system admin and audit admins (already),
-- Manager Administrators, people who assign staff to that client, and anyone
-- given "Activity and audit trail" on the Access page. To start with, that is
-- whoever can change the client's details, with the same reach (a Case
-- Manager: their assigned clients). Support workers don't have it.
insert into public.app_modules (id, parent_id, category, label, sensitivity, delegable, sort_order, actions, grant_ready) values
  ('clients.audit', 'clients.list', 'clients', 'Activity and audit trail', 'sensitive', true, 267, '{view}', true)
on conflict (id) do nothing;
update public.app_modules set status = 'active' where id = 'clients.audit' and status = 'retired'; -- run again after an undo
insert into public.access_baselines (job_title_id, function_group_id, module_id, actions, scope, note, by_system_admin)
select distinct b.job_title_id, b.function_group_id, 'clients.audit', '{view}'::text[], b.scope, 'Audit trail default: as for changing client details', true
  from public.access_baselines b
 where b.module_id = 'clients.details' and b.revoked_at is null and b.effect = 'allow' and 'edit' = any (b.actions)
   and (b.job_title_id is not null or b.function_group_id is not null)
   and not exists (select 1 from public.access_baselines x where x.module_id = 'clients.audit' and x.revoked_at is null);

create index if not exists audit_log_client on public.audit_log (entity_id, created_at desc) where entity in ('client', 'car_client');
drop policy if exists "people who look after a client read its trail" on public.audit_log;
create policy "people who look after a client read its trail" on public.audit_log
  for select to authenticated
  using (case when entity in ('client', 'car_client') and entity_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
              then (select public.is_manager_admin()) or public.can('clients.assign', 'edit', entity_id::uuid) or public.can('clients.audit', 'view', entity_id::uuid)
              else false end);

-- The same people see the client's download links and page openings.
drop policy if exists "read downloads" on public.download_log;
create policy "read downloads" on public.download_log
  for select to authenticated
  using ((select public.is_system_admin()) or (select public.is_manager_admin())
         or (client_id is not null and (public.can('clients.assign', 'edit', client_id) or public.can('clients.audit', 'view', client_id))));
drop policy if exists "people who assign staff read who opened" on public.client_staff_views;
create policy "people who assign staff read who opened" on public.client_staff_views
  for select to authenticated
  using (user_id = (select auth.uid()) or (select public.is_manager_admin()) or public.can('clients.assign', 'edit', client_id) or public.can('clients.audit', 'view', client_id));

-- 5. Opening the trail is recorded with the page openings.
alter table public.client_staff_views add column if not exists area text not null default 'profile';
alter table public.client_staff_views drop constraint if exists client_staff_views_area_check;
alter table public.client_staff_views add constraint client_staff_views_area_check check (area in ('profile', 'audit_trail'));
