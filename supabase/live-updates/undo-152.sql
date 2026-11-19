-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 152. Safe to run again. Programs and schemes go back to Care settings holders only.
begin;
drop policy if exists "care settings add programs" on public.client_programs;
create policy "care settings add programs" on public.client_programs
  for insert to authenticated with check ((select public.can_admin_area('care')));
drop policy if exists "care settings change programs" on public.client_programs;
create policy "care settings change programs" on public.client_programs
  for update to authenticated using ((select public.can_admin_area('care'))) with check ((select public.can_admin_area('care')));
drop policy if exists "care settings change scheme wording" on public.client_schemes;
create policy "care settings change scheme wording" on public.client_schemes
  for update to authenticated using ((select public.can_admin_area('care'))) with check ((select public.can_admin_area('care')));
update public.app_modules set status = 'retired' where id = 'system.settings.programs' and (exists (select 1 from public.access_grants where module_id = 'system.settings.programs') or exists (select 1 from public.access_baselines where module_id = 'system.settings.programs'));
delete from public.app_modules where id = 'system.settings.programs' and not exists (select 1 from public.access_grants where module_id = 'system.settings.programs') and not exists (select 1 from public.access_baselines where module_id = 'system.settings.programs');
commit;
