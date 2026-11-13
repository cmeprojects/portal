-- Staff Portal · © cmeproject. All rights reserved.
-- Update 76: Forms and Reports follow the access given on the Access page
-- (as well as the role rules). Nobody loses access.
-- Safe to run again. Undo: undo-76.sql. Run update 75 first.
begin;
-- cmeprojects module framework step 4 (second batch): Forms and the Cars
-- report follow the Access page as well as the role rules (the Tasks and
-- Onboarding reports are checked by the pages; their data already follows the
-- task and onboarding rules). Nobody loses access; people with no admin access
-- given skip the extra check straight away.
-- No new SECURITY DEFINER function (two existing ones gain the extra rule).

CREATE OR REPLACE FUNCTION public.can_make_forms()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select public.is_member() and public.feature_enabled('forms')
     and (public.is_system_admin()
          or (public.feature_enabled('form_builder')
              and public.my_role()::text in (select jsonb_array_elements_text(coalesce(
                    (select value from public.app_settings where key = 'forms.maker_roles'), '[]'))))
              -- cmeprojects step 4: or given Forms (create) on the Access page.
              or (public.feature_enabled('form_builder') and (exists (select 1 from public.access_grants g where g.user_id = auth.uid() and g.area is null and g.revoked_at is null)
                   and public.can('workflows.forms', 'create'))))
$function$;

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
$function$;
commit;
