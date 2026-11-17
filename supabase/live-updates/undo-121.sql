-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 121: removes performance and development reviews (and what was
-- recorded in them) and the HR reminders. Safe to run again.
begin;
delete from public.function_group_modules where module_id = 'hr.performance';
drop function if exists public.run_hr_alerts();
drop table if exists public.hr_alerts_sent;
drop table if exists public.staff_reviews;
drop function if exists public.guard_staff_review();
drop function if exists public.leads_person(uuid);
update public.access_baselines set revoked_at = now() where module_id = 'hr.performance' and revoked_at is null;
update public.app_modules set grant_ready = false where id = 'hr.performance';
commit;
