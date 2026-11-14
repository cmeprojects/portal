-- Staff Portal · © cmeproject. All rights reserved.
-- PROPOSAL (not applied, awaiting the owner): managers can act on tasks in registers with no named managers
-- (they're the ones told about escalations). Safe to run again.
-- Undo: undo-83.sql. Run update 82 first.
begin;
-- cmeprojects: managers can act on tasks in registers that have no named
-- managers (for example General tasks), matching who is told about their
-- escalations. Before, every manager was told but none could press
-- "Escalation dealt with". Registers with named managers are unchanged.
-- Only can_edit_task changes. No tables, policies or other permissions.

CREATE OR REPLACE FUNCTION public.can_edit_task(p_task_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select public.is_member() and exists (
    select 1 from public.tasks t
     where t.id = p_task_id
       and (
         t.assigned_to = auth.uid()
         or t.created_by = auth.uid()
         or public.leads_user(t.assigned_to)
         or (public.has_role(array['manager', 'system_admin']::public.app_role[])
             and exists (select 1 from public.registry_managers rm
                          where rm.registry_id = t.registry_id and rm.user_id = auth.uid()))
         -- cmeprojects (update 83): a register with no named managers is
         -- looked after by every manager (they're the ones told about its
         -- escalations, see task_managers), so they can act on its tasks.
         or (public.has_role(array['manager']::public.app_role[])
             and not exists (select 1 from public.registry_managers rm where rm.registry_id = t.registry_id))
         or public.is_system_admin()
       )
  )
$function$;
commit;
