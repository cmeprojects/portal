-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 97: making forms goes back to the System setting "Who can make
-- forms". Copied defaults are kept (no effect). Safe to run again.
begin;
update public.app_modules set grant_ready = false where id = 'workflows.forms' and grant_ready;
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
$function$
;
commit;
