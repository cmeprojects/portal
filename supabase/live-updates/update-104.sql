-- Staff Portal · © cmeproject. All rights reserved.
-- Update 104: which parts of the portal belong to each function group
-- (Stage 4). A mapping gives nobody access. Safe to run again.
-- Undo: undo-104.sql. Run update 103 first.
begin;
-- cmeprojects (update 104; function-based access, Stage 4; D-045, D-047):
-- which parts of the portal belong to each function group.
--
--   * A mapping only decides which parts a function group's screens offer
--     first (Access page, Roles page). It gives nobody access: access is
--     always an explicit grant (person, role, group or access level).
--   * A part can belong to more than one group (for example Tasks belongs to
--     Management, Care & Coordination and Service Delivery).
--   * Everyone's own pages (My workspace) belong to no group. Protected parts
--     (System settings, Access) stay with the system admin.
--   * Starting mapping below; the system admin (or whoever looks after
--     Roles) changes it on the Roles page.

create table if not exists public.function_group_modules (
  function_group_id uuid not null references public.function_groups (id) on delete restrict,
  module_id text not null references public.app_modules (id) on delete restrict,
  org_id uuid not null default public.default_org_id(),
  created_by uuid default auth.uid() references public.profiles (id),
  created_at timestamptz not null default now(),
  primary key (function_group_id, module_id)
);
create index if not exists function_group_modules_module on public.function_group_modules (module_id);
alter table public.function_group_modules enable row level security;

drop policy if exists "members read function group parts" on public.function_group_modules;
create policy "members read function group parts" on public.function_group_modules
  for select to authenticated using ((select public.is_member()));
drop policy if exists "roles admins map function group parts" on public.function_group_modules;
create policy "roles admins map function group parts" on public.function_group_modules
  for insert to authenticated with check ((select public.can_admin_area('roles')));
drop policy if exists "roles admins unmap function group parts" on public.function_group_modules;
create policy "roles admins unmap function group parts" on public.function_group_modules
  for delete to authenticated using ((select public.can_admin_area('roles')));
grant select, insert, delete on public.function_group_modules to authenticated;

-- Only active groups, and only top-level parts that aren't protected or
-- everyone's own (sub-parts follow their part).
create or replace function public.guard_function_group_module()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  m record;
begin
  if not exists (select 1 from public.function_groups where id = new.function_group_id and active) then
    raise exception 'That function group isn''t in use. Choose another.';
  end if;
  select * into m from public.app_modules where id = new.module_id;
  if not found or m.status <> 'active' or m.parent_id is not null or m.id like 'cat\_%' or m.category = 'workspace' or m.sensitivity = 'protected' then
    raise exception 'That part can''t belong to a function group.';
  end if;
  new.created_by := auth.uid();
  new.created_at := now();
  return new;
end;
$$;
revoke execute on function public.guard_function_group_module() from public, anon, authenticated;
drop trigger if exists guard_function_group_module on public.function_group_modules;
create trigger guard_function_group_module before insert on public.function_group_modules
  for each row execute function public.guard_function_group_module();

-- Starting mapping (only parts that exist; running again adds nothing).
insert into public.function_group_modules (function_group_id, module_id)
select g.id, x.module_id
  from (values
    ('management_admin', 'ops.tasks'), ('management_admin', 'ops.registers'), ('management_admin', 'ops.scoreboard'),
    ('management_admin', 'workflows.forms'), ('management_admin', 'ops.cars'), ('management_admin', 'ops.features'),
    ('management_admin', 'ops.apps'), ('management_admin', 'people.staff'), ('management_admin', 'people.invite'),
    ('management_admin', 'people.teams'), ('management_admin', 'people.roles'), ('management_admin', 'insights.reports'),
    ('management_admin', 'engagement.assistant'), ('management_admin', 'engagement.enquiries'), ('management_admin', 'engagement.website'),
    ('management_admin', 'hr.requests'),
    ('hr_workforce', 'hr.onboarding'), ('hr_workforce', 'hr.contracts'), ('hr_workforce', 'hr.requests'), ('hr_workforce', 'hr.records'),
    ('hr_workforce', 'people.staff'), ('hr_workforce', 'people.invite'), ('hr_workforce', 'people.teams'), ('hr_workforce', 'people.roles'),
    ('care_coordination', 'clients.list'), ('care_coordination', 'ops.tasks'), ('care_coordination', 'workflows.forms'),
    ('service_delivery', 'ops.tasks'), ('service_delivery', 'ops.cars'), ('service_delivery', 'ops.apps'), ('service_delivery', 'workflows.forms'),
    ('finance_accounts', 'insights.reports'), ('finance_accounts', 'hr.records'),
    ('allied_health', 'clients.list'), ('allied_health', 'workflows.forms')
  ) x(group_key, module_id)
  join public.function_groups g on g.key = x.group_key and g.active
  join public.app_modules m on m.id = x.module_id and m.status = 'active'
on conflict do nothing;
commit;
