-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 152): Programs and schemes are managed by the system admin
-- and Manager Administrators (like the service catalogue and shift types), as a
-- tile in Portal settings. People given the Care settings area keep their access.
-- Nothing is deleted. No new security definer function. Safe to run again.

insert into public.app_modules (id, parent_id, category, label, sensitivity, delegable, sort_order)
values ('system.settings.programs', 'system.settings', 'system', 'Programs and schemes', 'normal', false, 1126)
on conflict (id) do nothing;
update public.app_modules set status = 'active' where id = 'system.settings.programs' and status = 'retired'; -- run again after an undo

drop policy if exists "care settings add programs" on public.client_programs;
create policy "care settings add programs" on public.client_programs
  for insert to authenticated
  with check ((select public.can_admin_area('care')) or (select public.is_manager_admin()));
drop policy if exists "care settings change programs" on public.client_programs;
create policy "care settings change programs" on public.client_programs
  for update to authenticated
  using ((select public.can_admin_area('care')) or (select public.is_manager_admin()))
  with check ((select public.can_admin_area('care')) or (select public.is_manager_admin()));
drop policy if exists "care settings change scheme wording" on public.client_schemes;
create policy "care settings change scheme wording" on public.client_schemes
  for update to authenticated
  using ((select public.can_admin_area('care')) or (select public.is_manager_admin()))
  with check ((select public.can_admin_area('care')) or (select public.is_manager_admin()));
