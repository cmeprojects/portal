-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 124: removes Allied Health access (practitioner access, notes,
-- the view log, the shared-documents flag and the package switch). Reports
-- practitioners uploaded stay as ordinary client documents. Default access
-- for the part is switched off, not deleted. Safe to run again.
begin;
do $do$
begin
  if to_regclass('storage.objects') is not null then
    drop policy if exists "practitioners read shared files" on storage.objects;
    drop policy if exists "practitioners add report files" on storage.objects;
  end if;
end
$do$;
drop policy if exists "practitioners see their clients" on public.car_clients;
drop policy if exists "practitioners see client details" on public.client_details;
drop policy if exists "practitioners see client alerts" on public.client_alerts;
drop policy if exists "practitioners see care plans" on public.client_care_plans;
drop policy if exists "practitioners see care goals" on public.client_care_goals;
drop policy if exists "practitioners see worker instructions" on public.client_worker_instructions;
drop policy if exists "practitioners see client documents" on public.client_documents;
drop policy if exists "practitioners add reports" on public.client_documents;
alter table public.client_documents drop column if exists shared_with_practitioners;
drop function if exists public.run_practitioner_alerts();
drop table if exists public.client_external_views;
drop table if exists public.client_practitioner_notes;
drop function if exists public.guard_practitioner_note();
drop table if exists public.client_external_access;
drop function if exists public.guard_external_access();
drop function if exists public.external_sees(uuid, text);
drop function if exists public.external_sees_basics(uuid, text);
update public.access_baselines set revoked_at = now() where module_id = 'clients.external' and revoked_at is null;
update public.app_modules set grant_ready = false where id = 'clients.external';
delete from public.features where key = 'allied_health';
commit;
