-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 76: Forms and the Cars report go back to the role rules only. Safe to run again.
begin;
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
                    (select value from public.app_settings where key = 'forms.maker_roles'), '[]')))))
$function$;

CREATE OR REPLACE FUNCTION public.can_see_car_reports()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select public.can_manage_cars()
      or (public.cars_on() and public.my_role() = any (public.setting_roles('vehicles.report_roles')))
$function$;
commit;
