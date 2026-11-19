-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 149. Safe to run again. Incidents and their timelines are removed (shift notes keep their incident text).
begin;
drop function if exists public.run_incident_alerts();
drop trigger if exists incident_from_shift_note on public.shift_service_records;
drop function if exists public.incident_from_shift_note();
drop table if exists public.client_incident_events;
drop table if exists public.client_incidents;
drop function if exists public.log_incident_created();
drop function if exists public.guard_incident();
drop function if exists public.plus_business_days(timestamptz, int);
drop sequence if exists public.client_incident_ref_seq;
update public.access_baselines set revoked_at = now() where module_id = 'clients.incidents' and revoked_at is null;
update public.app_modules set status = 'retired' where id = 'clients.incidents' and exists (select 1 from public.access_baselines where module_id = 'clients.incidents');
delete from public.app_modules where id = 'clients.incidents' and not exists (select 1 from public.access_baselines where module_id = 'clients.incidents') and not exists (select 1 from public.access_grants where module_id = 'clients.incidents');
commit;
