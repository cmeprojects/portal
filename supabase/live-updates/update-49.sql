-- Staff Portal · © cmeproject. All rights reserved.
-- Update 49: "Setting up registers" delegation (change any register). Starts
-- with the system admin only. Needs update 46. Safe to run again. Undo: undo-49.sql.
begin;
alter table public.delegation_rules drop constraint if exists delegation_rules_area_check;
alter table public.delegation_rules add constraint delegation_rules_area_check
  check (area in ('branding', 'messages', 'people', 'compliance', 'tasks', 'reports', 'vehicles', 'website', 'audit', 'registers', 'roles', 'register_setup'));
insert into public.delegation_rules (area, mode) values ('register_setup', 'admin') on conflict (area) do nothing;

-- Can the signed-in person set up this register?
create or replace function public.can_setup_registry(p_registry_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.manages_registry(p_registry_id) or public.can_admin_area('register_setup')
$$;

revoke execute on function public.can_setup_registry(uuid) from public, anon;
grant execute on function public.can_setup_registry(uuid) to authenticated;

drop policy if exists "registry managers update registries" on public.registries;
create policy "registry managers update registries" on public.registries
  for update to authenticated
  using (public.can_setup_registry(id)) with check (public.can_setup_registry(id));

drop policy if exists "registry managers manage managers" on public.registry_managers;
create policy "registry managers manage managers" on public.registry_managers
  for all to authenticated
  using (public.can_setup_registry(registry_id)) with check (public.can_setup_registry(registry_id));

drop policy if exists "registry managers manage fields" on public.registry_fields;
create policy "registry managers manage fields" on public.registry_fields
  for insert to authenticated with check (public.can_setup_registry(registry_id));
drop policy if exists "registry managers change fields" on public.registry_fields;
create policy "registry managers change fields" on public.registry_fields
  for update to authenticated
  using (public.can_setup_registry(registry_id)) with check (public.can_setup_registry(registry_id));

commit;
