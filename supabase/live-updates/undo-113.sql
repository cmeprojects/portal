-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 113: removes care plans, goals and worker instructions (and
-- everything recorded in them). Safe to run again.
begin;
drop table if exists public.client_care_goals;
drop table if exists public.client_worker_instructions;
drop table if exists public.client_care_plans;
drop function if exists public.guard_care_goal();
drop function if exists public.guard_care_plan();
update public.access_baselines set revoked_at = now() where module_id = 'clients.care_plans' and revoked_at is null;
update public.app_modules set grant_ready = false where id = 'clients.care_plans';
commit;
