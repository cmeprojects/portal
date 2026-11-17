-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 93; function-based access, Stage 2; D-045, D-046 and
-- the owner's approval of 17 Nov 2026): each job title belongs to one or more
-- function groups. This only records the link: it gives nobody any access and
-- changes no permission check.
--   * Members read the links; people who look after Roles add and remove them.
--   * Only active groups can be linked.
--   * A group can't be deactivated while an active role uses it.
--   * Existing roles are linked once by their access level (support worker and
--     team leader: Service Delivery; manager: Management & Administration; staff
--     admin: HR & Workforce; external: Allied Health). Changeable on the Roles page.
--   * "At least one group" for new and edited roles is checked by the Roles page.
--   * Changes are logged by the server action (no new SECURITY DEFINER).

create table if not exists public.job_title_functions (
  job_title_id uuid not null references public.job_titles (id) on delete restrict,
  function_group_id uuid not null references public.function_groups (id) on delete restrict,
  org_id uuid not null default public.default_org_id(),
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  primary key (job_title_id, function_group_id)
);
create index if not exists job_title_functions_group on public.job_title_functions (function_group_id);
alter table public.job_title_functions enable row level security;

drop policy if exists "members read role function groups" on public.job_title_functions;
create policy "members read role function groups" on public.job_title_functions
  for select to authenticated using ((select public.is_member()));
drop policy if exists "roles admins link role function groups" on public.job_title_functions;
create policy "roles admins link role function groups" on public.job_title_functions
  for insert to authenticated with check ((select public.can_admin_area('roles')));
drop policy if exists "roles admins unlink role function groups" on public.job_title_functions;
create policy "roles admins unlink role function groups" on public.job_title_functions
  for delete to authenticated using ((select public.can_admin_area('roles')));
grant select, insert, delete on public.job_title_functions to authenticated;

-- Only active groups can be linked.
create or replace function public.guard_job_title_function()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if not exists (select 1 from public.function_groups where id = new.function_group_id and active) then
    raise exception 'That function group isn''t in use. Choose another.';
  end if;
  return new;
end;
$$;
revoke execute on function public.guard_job_title_function() from public, anon, authenticated;
drop trigger if exists guard_job_title_function on public.job_title_functions;
create trigger guard_job_title_function before insert on public.job_title_functions
  for each row execute function public.guard_job_title_function();

-- Function groups: key never changes (Stage 1), and now: can't be deactivated
-- while an active role uses it.
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
  if tg_op = 'UPDATE' and old.active and not new.active and exists (
       select 1 from public.job_title_functions l join public.job_titles t on t.id = l.job_title_id
        where l.function_group_id = new.id and t.active) then
    raise exception 'Roles in use belong to this group. Move them to another group first.';
  end if;
  new.updated_at := now();
  new.updated_by := auth.uid();
  return new;
end;
$$;

-- Link existing roles once, by access level (only roles with no group yet).
insert into public.job_title_functions (job_title_id, function_group_id)
select t.id, g.id
  from public.job_titles t
  join public.function_groups g on g.key = case t.access_level::text
         when 'support_worker' then 'service_delivery'
         when 'team_leader' then 'service_delivery'
         when 'manager' then 'management_admin'
         when 'staff_admin' then 'hr_workforce'
         when 'external' then 'allied_health'
       end
 where g.active
   and not exists (select 1 from public.job_title_functions l where l.job_title_id = t.id)
on conflict do nothing;
