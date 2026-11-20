-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 155. Safe to run again. Entries already written stay in the
-- change log; the before-and-after values table is removed.
begin;
do $$
declare t text;
begin
  foreach t in array array['client_agreements', 'client_alert_notes', 'client_alerts', 'client_care_goals', 'client_care_plans', 'client_comms',
    'client_details', 'client_documents', 'client_external_access', 'client_funding', 'client_people', 'client_practitioner_notes',
    'client_reviews', 'client_services', 'client_worker_instructions', 'client_assignments', 'client_locations', 'client_communications', 'car_clients'] loop
    execute format('drop trigger if exists log_client_audit on public.%I', t);
  end loop;
  foreach t in array array['client_assignments', 'client_locations', 'client_communications', 'car_clients'] loop
    execute format('drop trigger if exists log_client_change on public.%I', t);
  end loop;
end $$;
drop trigger if exists car_clients_log on public.car_clients;
create trigger car_clients_log after insert or update on public.car_clients for each row execute function public.log_car_setup('car_client');
create or replace function public.log_client_change() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  v_ref text := (select client_ref from public.car_clients where id = new.client_id);
  v_what text := coalesce(to_jsonb(new) ->> 'kind', to_jsonb(new) ->> 'label', '');
begin
  if tg_op = 'UPDATE' and new.client_id is distinct from old.client_id then
    raise exception 'This stays with its client. Add a new one for another client.';
  end if;
  new.updated_at := now();
  new.updated_by := auth.uid();
  perform public.write_audit(tg_table_name || case when tg_op = 'INSERT' then '_added' else '_changed' end,
    'client', new.client_id::text, jsonb_build_object('client', v_ref, 'item', v_what));
  return new;
end;
$$;
revoke execute on function public.log_client_change() from public, anon, authenticated;
drop policy if exists "people who look after a client read its trail" on public.audit_log;
drop policy if exists "read downloads" on public.download_log;
create policy "read downloads" on public.download_log
  for select to authenticated
  using ((select public.is_system_admin()) or (select public.is_manager_admin())
         or (client_id is not null and public.can('clients.assign', 'edit', client_id)));
drop policy if exists "people who assign staff read who opened" on public.client_staff_views;
create policy "people who assign staff read who opened" on public.client_staff_views
  for select to authenticated
  using (user_id = (select auth.uid()) or public.can('clients.assign', 'edit', client_id));
update public.access_baselines set revoked_at = now() where module_id = 'clients.audit' and revoked_at is null;
update public.app_modules set status = 'retired' where id = 'clients.audit' and exists (select 1 from public.access_baselines where module_id = 'clients.audit');
delete from public.app_modules where id = 'clients.audit' and not exists (select 1 from public.access_baselines where module_id = 'clients.audit') and not exists (select 1 from public.access_grants where module_id = 'clients.audit');
drop index if exists public.audit_log_client;
drop table if exists public.client_audit_values;
alter table public.client_staff_views drop constraint if exists client_staff_views_area_check;
alter table public.client_staff_views drop column if exists area;
commit;
