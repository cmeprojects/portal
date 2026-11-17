-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 96: Manage cars goes back to the System setting "Who manages
-- cars". The defaults copied in are kept (no effect while Manage cars isn't
-- switched over), so running update 96 again doesn't copy them twice. Safe to
-- run again.
begin;
update public.app_modules set grant_ready = false where id = 'ops.cars.manage' and grant_ready;
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
$function$
;
CREATE OR REPLACE FUNCTION public.car_managers()
 RETURNS SETOF uuid
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select id from public.profiles
   where active and (role = 'system_admin' or role = any (public.setting_roles('vehicles.manager_roles')))
$function$
;
commit;
