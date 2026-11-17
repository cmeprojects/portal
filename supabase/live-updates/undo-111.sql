-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 111: removes communication preferences (table and its grants),
-- the section switches and My clients from the catalogue; "support
-- coordinator" assignments become "case manager". Safe to run again.
begin;
drop table if exists public.client_comms;
update public.access_baselines set revoked_at = now() where module_id = 'clients.comms' and revoked_at is null;
delete from public.app_settings where key in ('care.section_documents', 'care.section_care_plans', 'care.section_reviews', 'care.section_agreements', 'care.section_funding', 'care.section_comms', 'care.team_sees_comms');
update public.client_assignments set assigned_as = 'case_manager' where assigned_as = 'support_coordinator';
alter table public.client_assignments drop constraint if exists client_assignments_assigned_as_check;
alter table public.client_assignments add constraint client_assignments_assigned_as_check
  check (assigned_as in ('case_manager', 'intake', 'key_worker', 'other'));
update public.app_modules set grant_ready = false where id = 'clients.comms';
commit;
