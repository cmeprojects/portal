-- Staff Portal · © cmeproject. All rights reserved.
-- Update 92: Function Groups list (function-based access, Stage 1). Gives
-- nobody any access. Safe to run again. Undo: undo-92.sql. Run update 91 first.
begin;
-- cmeprojects (update 92; function-based access, Stage 1; decisions D-045,
-- D-046): the Function Groups list. A business function (for example Care &
-- Coordination) that job titles will belong to in Stage 2. This stage only
-- adds the list: it links nothing and gives nobody any access.
--   * Members read the list. People who look after Roles (the "roles"
--     settings area, as for job titles) add, rename, describe or deactivate.
--   * Never deleted (no delete rule); the key can't change once made.
--   * Changes are written to the change log by the server action (no new
--     SECURITY DEFINER function).

create table if not exists public.function_groups (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  key text not null unique check (key ~ '^[a-z][a-z0-9_]{1,40}$'),
  name text not null check (length(trim(name)) between 1 and 80),
  description text not null default '' check (length(description) <= 500),
  active boolean not null default true,
  sort_order integer not null default 0,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_by uuid,
  updated_at timestamptz not null default now()
);
create unique index if not exists function_groups_name on public.function_groups (org_id, lower(trim(name)));
alter table public.function_groups enable row level security;

drop policy if exists "members read function groups" on public.function_groups;
create policy "members read function groups" on public.function_groups
  for select to authenticated using ((select public.is_member()));
drop policy if exists "roles admins add function groups" on public.function_groups;
create policy "roles admins add function groups" on public.function_groups
  for insert to authenticated with check ((select public.can_admin_area('roles')));
drop policy if exists "roles admins change function groups" on public.function_groups;
create policy "roles admins change function groups" on public.function_groups
  for update to authenticated using ((select public.can_admin_area('roles'))) with check ((select public.can_admin_area('roles')));
-- No delete rule: deactivate instead.
grant select, insert, update on public.function_groups to authenticated;

create or replace function public.guard_function_group()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE' and new.key is distinct from old.key then
    raise exception 'A function group''s key never changes. Rename it instead.';
  end if;
  new.updated_at := now();
  new.updated_by := auth.uid();
  return new;
end;
$$;
revoke execute on function public.guard_function_group() from public, anon, authenticated;

drop trigger if exists guard_function_group on public.function_groups;
create trigger guard_function_group before insert or update on public.function_groups
  for each row execute function public.guard_function_group();

insert into public.function_groups (key, name, description, sort_order)
select v.key, v.name, v.description, v.sort_order
  from (values
    ('management_admin', 'Management & Administration', 'Running the organisation: centre and operations managers, administration.', 10),
    ('hr_workforce', 'HR & Workforce', 'Staff records, onboarding, rostering and payroll.', 20),
    ('care_coordination', 'Care & Coordination', 'Intake and assessment, care management and coordination.', 30),
    ('service_delivery', 'Service Delivery', 'Team leaders and support workers delivering services.', 40),
    ('finance_accounts', 'Finance & Accounts', 'Finance and accounts administration.', 50),
    ('allied_health', 'Allied Health', 'Allied health practitioners (each discipline is its own role).', 60)
  ) v(key, name, description, sort_order)
 where not exists (select 1 from public.function_groups g where g.key = v.key);
commit;
