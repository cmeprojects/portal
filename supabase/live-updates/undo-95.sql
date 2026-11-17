-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 95: Onboarding goes back to the old rules (System settings
-- "Who manages Compliance" and the built-in fallback). The defaults copied in
-- are kept (they have no effect while Onboarding isn't switched over), so
-- running update 95 again doesn't copy them twice. Safe to run again.
begin;
update public.app_modules set grant_ready = false
 where id in ('hr.onboarding', 'hr.onboarding.overview', 'hr.onboarding.expiry') and grant_ready;
CREATE OR REPLACE FUNCTION public.guard_access_baseline()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare
  m record;
begin
  if tg_op = 'UPDATE' then
    if (to_jsonb(new) - 'revoked_at' - 'revoked_by') is distinct from (to_jsonb(old) - 'revoked_at' - 'revoked_by') or old.revoked_at is not null then
      raise exception 'A grant isn''t changed: revoke it and add a new one.';
    end if;
    new.revoked_by := auth.uid();
    return new;
  end if;
  select * into m from public.app_modules where id = new.module_id;
  if not found or m.status <> 'active' or m.sensitivity = 'protected' or m.legacy_kind is not null or not m.grant_ready then
    raise exception 'That part can''t be given to a role, group or access level (yet).';
  end if;
  if new.function_group_id is not null and m.sensitivity <> 'normal' then
    raise exception 'Sensitive parts are given to a job title or a person, never to a whole function group.';
  end if;
  if new.access_level in ('system_admin', 'new_starter', 'external') then
    raise exception 'That access level can''t hold grants.';
  end if;
  new.granted_by := auth.uid();
  new.by_system_admin := public.is_system_admin();
  new.created_at := now();
  return new;
end;
$function$
;
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
$function$
;
CREATE OR REPLACE FUNCTION public.people_admins()
 RETURNS SETOF uuid
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select id from public.profiles
   where active and (role = 'staff_admin' or role = any (public.setting_roles('compliance.manager_roles')))
     and role <> 'system_admin'
$function$
;
commit;
