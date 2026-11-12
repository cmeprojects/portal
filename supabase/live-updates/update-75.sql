-- Staff Portal · © cmeproject. All rights reserved.
-- Update 75: Onboarding and Cars follow the access given on the Access page
-- (as well as the existing role rules). Nobody loses access.
-- Safe to run again. Undo: undo-75.sql. Run update 74 first.
begin;
-- cmeprojects module framework step 4 (first modules): Onboarding and Cars
-- follow the Access page too. Approving uploads and setting up onboarding is
-- allowed by the existing role rules OR by "Onboarding: approve" given on the
-- Access page; managing cars by the role rules OR "Manage cars: set up".
-- Nobody loses access. People with no admin access given skip the extra check
-- straight away (one index lookup), so pages stay as fast.
-- No new SECURITY DEFINER function (two existing ones gain the extra rule).

CREATE OR REPLACE FUNCTION public.can_manage_compliance()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select public.mfa_ok() and (public.my_role() = 'system_admin'
         or public.my_role() = any (public.setting_roles('compliance.manager_roles'))
         or (public.my_role() = 'manager'
             and not exists (select 1 from public.profiles where role = 'staff_admin' and active))
         -- cmeprojects step 4: or given Onboarding (approve) on the Access page.
         or (exists (select 1 from public.access_grants g where g.user_id = auth.uid() and g.area is null and g.revoked_at is null)
              and public.can('hr.onboarding', 'approve')))
$function$;

CREATE OR REPLACE FUNCTION public.can_manage_cars()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select public.cars_on()
     and (public.my_role() = 'system_admin' or public.my_role() = any (public.setting_roles('vehicles.manager_roles'))
          -- cmeprojects step 4: or given Manage cars (set up) on the Access page.
          or (exists (select 1 from public.access_grants g where g.user_id = auth.uid() and g.area is null and g.revoked_at is null)
              and public.can('ops.cars.manage', 'configure')))
$function$;
commit;
