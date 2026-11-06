-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 49: only a register's own managers (and the system admin) set it up again. Safe to run again.
begin;

drop policy if exists "registry managers update registries" on public.registries;
create policy "registry managers update registries" on public.registries
  for update to authenticated
  using (public.manages_registry(id)) with check (public.manages_registry(id));

drop policy if exists "registry managers manage managers" on public.registry_managers;
create policy "registry managers manage managers" on public.registry_managers
  for all to authenticated
  using (public.manages_registry(registry_id)) with check (public.manages_registry(registry_id));

drop policy if exists "registry managers manage fields" on public.registry_fields;
create policy "registry managers manage fields" on public.registry_fields
  for insert to authenticated with check (public.manages_registry(registry_id));
drop policy if exists "registry managers change fields" on public.registry_fields;
create policy "registry managers change fields" on public.registry_fields
  for update to authenticated
  using (public.manages_registry(registry_id)) with check (public.manages_registry(registry_id));

drop function if exists public.can_setup_registry(uuid);
delete from public.settings_drafts where kind = 'delegation' and key = 'register_setup';
delete from public.delegation_rules where area = 'register_setup';
alter table public.delegation_rules drop constraint if exists delegation_rules_area_check;
alter table public.delegation_rules add constraint delegation_rules_area_check
  check (area in ('branding', 'messages', 'people', 'compliance', 'tasks', 'reports', 'vehicles', 'website', 'audit', 'registers', 'roles'));

commit;
