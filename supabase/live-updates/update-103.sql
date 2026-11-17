-- Staff Portal · © cmeproject. All rights reserved.
-- Update 103: Tasks switched over to the one permission check, with a faster
-- task check (Stage 3b). Nobody's access changes. Safe to run again.
-- Undo: undo-103.sql. Run update 102 first.
begin;
-- cmeprojects (update 103; function-based access, Stage 3b; D-047, D-049;
-- owner chose option A): Tasks switched over to the one permission check
-- `can()`, together with a faster task check.
--
--   * "Sees every task" (managers and the system admin today) now comes from
--     `can('ops.tasks', 'view')`, default managers. Nobody's access changes.
--   * Unchanged: everyone sees tasks they're given, made, or help on; team
--     leaders see their team's tasks; who may change a task (assignee, maker,
--     team leader, the register's managers).
--   * Faster: the task list no longer runs a check for every task. The
--     permission check runs once per query, and "mine / I help / my team's"
--     is worked out in one go. Timeline and files follow the task (whoever
--     can see the task sees them).

update public.app_modules set grant_ready = true where id = 'ops.tasks' and not grant_ready;

do $$
begin
  if exists (select 1 from public.access_baselines
              where module_id = 'ops.tasks' and access_level is not null and revoked_at is null) then
    return;
  end if;
  insert into public.access_baselines (access_level, module_id, actions, scope, note)
  values ('manager', 'ops.tasks', '{view}', 'all', 'Set at switch-over: managers saw every task');
end $$;

-- One task (used by the task functions).
CREATE OR REPLACE FUNCTION public.can_see_task(p_task_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select public.is_member() and (
    public.can('ops.tasks', 'view') or public.is_system_admin()
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
create policy "see tasks you have access to" on public.tasks
  for select to authenticated
  using ((select public.is_member()) and (
    (select public.can('ops.tasks', 'view')) or (select public.is_system_admin())
    or assigned_to = (select auth.uid()) or created_by = (select auth.uid())
    or id in (select h.task_id from public.task_helpers h where h.user_id = (select auth.uid()))
    or ((select public.feature_live('teams') and public.has_role(array['team_leader', 'manager', 'system_admin']::public.app_role[]))
        and (assigned_to in (select m.user_id from public.team_leaders tl join public.team_members m on m.team_id = tl.team_id where tl.user_id = (select auth.uid())) or created_by in (select m.user_id from public.team_leaders tl join public.team_members m on m.team_id = tl.team_id where tl.user_id = (select auth.uid()))))));

drop policy if exists "see helpers on tasks you have access to" on public.task_helpers;
create policy "see helpers on tasks you have access to" on public.task_helpers
  for select to authenticated
  using (user_id = (select auth.uid()) or (select public.can('ops.tasks', 'view')) or public.can_see_task(task_id));

drop policy if exists "see the timeline of tasks you have access to" on public.task_events;
create policy "see the timeline of tasks you have access to" on public.task_events
  for select to authenticated
  using (exists (select 1 from public.tasks t where t.id = task_events.task_id));

drop policy if exists "people who see the task see its files" on public.task_attachments;
create policy "people who see the task see its files" on public.task_attachments
  for select to authenticated
  using (exists (select 1 from public.tasks t where t.id = task_attachments.task_id));
commit;
