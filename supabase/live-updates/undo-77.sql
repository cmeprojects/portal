-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 77: Built features and Enquiries go back to the role rules only. Safe to run again.
begin;
CREATE OR REPLACE FUNCTION public.can_see_feature(p_feature uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select public.is_member() and public.custom_feature_live(p_feature)
     and (public.my_role() = 'system_admin'
          or exists (select 1 from public.custom_features where id = p_feature and public.my_role() = any (see_roles)))
$function$;

CREATE OR REPLACE FUNCTION public.can_fill_feature(p_feature uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select public.is_member() and public.custom_feature_live(p_feature)
     and (public.my_role() = 'system_admin'
          or exists (select 1 from public.custom_features where id = p_feature and public.my_role() = any (fill_roles)))
$function$;

CREATE OR REPLACE FUNCTION public.can_manage_feature(p_feature uuid, p_what text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select public.can_build_features()
      or (public.is_member() and public.mfa_ok() and public.my_role() = 'manager' and public.custom_feature_live(p_feature)
          and exists (select 1 from public.custom_features
                       where id = p_feature
                         and case p_what when 'fix' then managers_fix when 'targets' then managers_targets
                                         when 'options' then managers_options else false end))
$function$;

CREATE OR REPLACE FUNCTION public.can_see_enquiries()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select public.is_member() and (public.is_system_admin()
    or public.my_role()::text in (select jsonb_array_elements_text(coalesce(
         (select value from public.app_settings where key = 'assistant.enquiry_roles'), '[]'))))
$function$;
commit;
