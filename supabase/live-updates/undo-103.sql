-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 103: tasks go back to "managers and the system admin see every
-- task" and the one-task-at-a-time check. Copied default kept (no effect).
-- Safe to run again.
begin;
update public.app_modules set grant_ready = false where id = 'ops.tasks' and grant_ready;
CREATE OR REPLACE FUNCTION public.can_see_task(p_task_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select public.is_member() and (
    public.has_role(array['manager', 'system_admin']::public.app_role[])
    or exists (
      select 1
        from public.tasks t
       where t.id = p_task_id
         and (
           t.assigned_to = auth.uid()
           or t.created_by = auth.uid()
           or exists (select 1 from public.task_helpers h where h.task_id = t.id and h.user_id = auth.uid())
           or public.leads_user(t.assigned_to)
           or public.leads_user(t.created_by)
         )
    )
  )
$function$;
drop policy if exists "see tasks you have access to" on public.tasks;
create policy "see tasks you have access to" on public.tasks as PERMISSIVE for SELECT to authenticated using (can_see_task(id));
drop policy if exists "see helpers on tasks you have access to" on public.task_helpers;
create policy "see helpers on tasks you have access to" on public.task_helpers as PERMISSIVE for SELECT to authenticated using (can_see_task(task_id));
drop policy if exists "see the timeline of tasks you have access to" on public.task_events;
create policy "see the timeline of tasks you have access to" on public.task_events as PERMISSIVE for SELECT to authenticated using (can_see_task(task_id));
drop policy if exists "people who see the task see its files" on public.task_attachments;
create policy "people who see the task see its files" on public.task_attachments as PERMISSIVE for SELECT to authenticated using (can_see_task(task_id));
commit;
