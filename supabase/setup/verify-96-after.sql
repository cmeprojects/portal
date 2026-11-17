-- Staff Portal · © cmeproject. All rights reserved.
-- Update 96, check AFTER (read only; changes no data). Compares each active
-- person's "manage cars" access under the old rule (System setting "Who
-- manages cars") with the new permission check.
-- Expected: one row, changed = 0. Any other rows list who differs.
create temp table if not exists verify_96 (who text, role text, old_manage boolean, new_manage boolean, has_own_setting boolean);
truncate verify_96;
do $$
declare
  p record;
begin
  for p in select id, coalesce(nullif(full_name, ''), email) as who, role from public.profiles where active and role <> 'system_admin' loop
    perform set_config('request.jwt.claims', json_build_object('sub', p.id, 'aal', 'aal2')::text, true);
    insert into verify_96 values (
      p.who, p.role::text,
      public.cars_on() and p.role = any (public.setting_roles('vehicles.manager_roles')),
      public.can_manage_cars(),
      exists (select 1 from public.access_grants g where g.user_id = p.id and g.area is null and g.revoked_at is null and g.module_id like 'ops.cars%'));
  end loop;
  perform set_config('request.jwt.claims', '', true);
end $$;
select count(*) filter (where old_manage is distinct from new_manage and not has_own_setting) as changed,
       count(*) as people_checked,
       count(*) filter (where has_own_setting) as with_own_cars_setting
  from verify_96;
select who, role, old_manage, new_manage, has_own_setting
  from verify_96 where old_manage is distinct from new_manage order by role, who;
