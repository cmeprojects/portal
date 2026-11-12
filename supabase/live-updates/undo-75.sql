-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 75: Onboarding and Cars go back to the role rules only. Safe to run again.
begin;
CREATE OR REPLACE FUNCTION public.can_manage_compliance()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select public.mfa_ok() and (public.my_role() = 'system_admin'
         or public.my_role() = any (public.setting_roles('compliance.manager_roles'))
         or (public.my_role() = 'manager'
             and not exists (select 1 from public.profiles where role = 'staff_admin' and active)))
$function$;

CREATE OR REPLACE FUNCTION public.can_manage_cars()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select public.cars_on()
     and (public.my_role() = 'system_admin' or public.my_role() = any (public.setting_roles('vehicles.manager_roles')))
$function$;
commit;
