-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 140. Safe to run again. The client page opening log is removed.
begin;
drop table if exists public.client_staff_views;
drop policy if exists "payroll view: read bank details" on public.staff_bank;
drop policy if exists "payroll view: read super details" on public.staff_super;
update public.access_baselines set revoked_at = now() where module_id = 'hr.payroll_view' and revoked_at is null;
update public.access_baselines set revoked_at = now() where note = 'Privacy decision 18 Nov 2026: Payroll Officer' and revoked_at is null;
delete from public.function_group_modules where module_id = 'hr.payroll_view';
update public.app_modules set status = 'retired' where id = 'hr.payroll_view' and exists (select 1 from public.access_baselines where module_id = 'hr.payroll_view');
delete from public.app_modules where id = 'hr.payroll_view' and not exists (select 1 from public.access_baselines where module_id = 'hr.payroll_view') and not exists (select 1 from public.access_grants where module_id = 'hr.payroll_view');
commit;
