-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 119: removes offboarding (and every checklist recorded in it).
-- Safe to run again.
begin;
delete from public.function_group_modules where module_id = 'hr.offboarding';
drop trigger if exists offboarding_on_deactivate on public.profiles;
drop function if exists public.offboarding_on_deactivate();
drop table if exists public.offboarding_steps;
drop table if exists public.offboardings;
drop function if exists public.guard_offboarding_step();
drop function if exists public.add_offboarding_steps();
drop function if exists public.guard_offboarding();
update public.access_baselines set revoked_at = now() where module_id = 'hr.offboarding' and revoked_at is null;
update public.app_modules set grant_ready = false where id = 'hr.offboarding';
commit;
