-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 122: removes rostering (every shift recorded in it). Approved
-- leave is untouched. Safe to run again.
begin;
delete from public.function_group_modules where module_id = 'ops.roster';
drop policy if exists "people who roster see leave dates" on public.leave_periods;
drop function if exists public.run_roster_alerts();
drop table if exists public.shift_interest;
drop table if exists public.shifts;
drop function if exists public.guard_shift();
update public.access_baselines set revoked_at = now() where module_id = 'ops.roster' and revoked_at is null;
update public.app_modules set grant_ready = false where id = 'ops.roster';
commit;
