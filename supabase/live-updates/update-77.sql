-- Staff Portal · © cmeproject. All rights reserved.
-- Update 77: Built features and Enquiries follow the access given on the
-- Access page (as well as the role rules). Nobody loses access.
-- Safe to run again. Undo: undo-77.sql. Run update 76 first.
begin;
-- cmeprojects module framework step 4 (third batch): Built features and
-- Enquiries follow the Access page as well as the role rules. Built features:
-- view = see them all, create = fill them in, set up = the same manager tools
-- the system admin allowed for managers in the Feature builder. Nobody loses
-- access; people with no admin access given skip the extra check straight away.
-- No new SECURITY DEFINER function (four existing ones gain the extra rule).

CREATE OR REPLACE FUNCTION public.can_see_feature(p_feature uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select public.is_member() and public.custom_feature_live(p_feature)
     and (public.my_role() = 'system_admin'
          or exists (select 1 from public.custom_features where id = p_feature and public.my_role() = any (see_roles))
          -- cmeprojects step 4: or given Built features (view) on the Access page.
          or (exists (select 1 from public.access_grants g where g.user_id = auth.uid() and g.area is null and g.revoked_at is null)
                and public.can('ops.features', 'view')))
$function$;

CREATE OR REPLACE FUNCTION public.can_fill_feature(p_feature uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select public.is_member() and public.custom_feature_live(p_feature)
     and (public.my_role() = 'system_admin'
          or exists (select 1 from public.custom_features where id = p_feature and public.my_role() = any (fill_roles))
          -- cmeprojects step 4: or given Built features (create) on the Access page.
          or (exists (select 1 from public.access_grants g where g.user_id = auth.uid() and g.area is null and g.revoked_at is null)
                and public.can('ops.features', 'create')))
$function$;

CREATE OR REPLACE FUNCTION public.can_manage_feature(p_feature uuid, p_what text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select public.can_build_features()
      or (public.is_member() and public.mfa_ok() and (public.my_role() = 'manager'
               -- cmeprojects step 4: or given Built features (set up): the same manager tools.
               or (exists (select 1 from public.access_grants g where g.user_id = auth.uid() and g.area is null and g.revoked_at is null)
                and public.can('ops.features', 'configure')))
          and public.custom_feature_live(p_feature)
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
         (select value from public.app_settings where key = 'assistant.enquiry_roles'), '[]')))
    -- cmeprojects step 4: or given Enquiries on the Access page.
    or (exists (select 1 from public.access_grants g where g.user_id = auth.uid() and g.area is null and g.revoked_at is null)
                and public.can('engagement.enquiries', 'view')))
$function$;
commit;
