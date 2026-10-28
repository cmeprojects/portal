-- Staff Portal · © cmeproject. All rights reserved.
--
-- Staff admins (people management) see each register's open tasks as an
-- overview: title, description, due date and who it's assigned to. They
-- can't open task details or custom fields, and they no longer add or set
-- up registers: that's managers (their own registers) and the system admin.

create or replace function public.manages_registry(p_registry_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_system_admin() or (
    public.has_role(array['manager']::public.app_role[])
    and exists (select 1 from public.registry_managers
                 where registry_id = p_registry_id and user_id = auth.uid())
  )
$$;

drop policy "managers create registries" on public.registries;
create policy "managers create registries" on public.registries
  for insert to authenticated
  with check (public.has_role(array['manager', 'system_admin']::public.app_role[]));

-- Who sees the overview: staff admins (and managers and the system admin,
-- who can see the tasks anyway).
create function public.sees_register_overview()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.has_role(array['staff_admin', 'manager', 'system_admin']::public.app_role[])
$$;

-- Open tasks per register.
create function public.register_open_counts()
returns table (registry_id uuid, open_tasks bigint)
language sql
stable
security definer
set search_path = ''
as $$
  select t.registry_id, count(*)
    from public.tasks t
   where public.sees_register_overview()
     and t.parent_task_id is null
     and t.status not in ('completed', 'closed')
   group by t.registry_id
$$;

-- A register's open tasks, without custom fields or history.
create function public.register_overview(p_registry_id uuid)
returns table (
  ref text,
  title text,
  description text,
  priority public.task_priority,
  status public.task_status,
  due_date date,
  assigned_to uuid,
  assigned_name text
)
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(r.prefix, 'T') || '-' || lpad(t.ref_number::text, 4, '0'),
         t.title, t.description, t.priority, t.status, t.due_date, t.assigned_to,
         case when p.role = 'system_admin' then 'Admin' else coalesce(nullif(p.full_name, ''), p.email) end
    from public.tasks t
    join public.registries r on r.id = t.registry_id
    join public.profiles p on p.id = t.assigned_to
   where public.sees_register_overview()
     and t.registry_id = p_registry_id
     and t.parent_task_id is null
     and t.status not in ('completed', 'closed')
   order by t.due_date nulls last, t.ref_number
$$;

revoke execute on function public.register_open_counts() from public, anon;
revoke execute on function public.register_overview(uuid) from public, anon;
grant execute on function public.register_open_counts() to authenticated;
grant execute on function public.register_overview(uuid) to authenticated;
