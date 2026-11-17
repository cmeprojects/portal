-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 98: reports go back to the System settings. Copied defaults are
-- kept (no effect). Safe to run again.
begin;
update public.app_modules set grant_ready = false
 where id in ('insights.reports', 'insights.reports.tasks', 'insights.reports.compliance', 'insights.reports.cars') and grant_ready;
CREATE OR REPLACE FUNCTION public.can_see_car_reports()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select public.can_manage_cars()
      or (public.cars_on() and public.my_role() = any (public.setting_roles('vehicles.report_roles')))
      -- cmeprojects step 4: or given the Cars report on the Access page.
      or (public.cars_on() and (exists (select 1 from public.access_grants g where g.user_id = auth.uid() and g.area is null and g.revoked_at is null)
                   and public.can('insights.reports.cars', 'view')))
$function$
;
commit;
