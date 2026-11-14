-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 83. Safe to run again.
begin;
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
         or public.is_system_admin()
       )
  )
$function$;
commit;
