-- Staff Portal · © cmeproject. All rights reserved.
-- Update 101, check AFTER (read only; changes no data). Compares who manages staff
-- under the old rule (managers, staff admins and the
-- system admin) with the new permission check.
-- Expected: one row, changed = 0. Any other rows list who differs.
create temp table if not exists verify_101 (who text, role text, old_rule boolean, new_rule boolean, has_own_setting boolean);
truncate verify_101;
do $$
declare p record;
begin
  for p in select id, coalesce(nullif(full_name, ''), email) as who, role from public.profiles where active and role <> 'system_admin' loop
    perform set_config('request.jwt.claims', json_build_object('sub', p.id, 'aal', 'aal2')::text, true);
    insert into verify_101 values (p.who, p.role::text, p.role in ('manager', 'staff_admin'), public.can('people.staff', 'edit'),
      exists (select 1 from public.access_grants g where g.user_id = p.id and g.area is null and g.revoked_at is null and (g.module_id = 'people.staff' or g.module_id = 'cat_people')));
  end loop;
  perform set_config('request.jwt.claims', '', true);
end $$;
select count(*) filter (where old_rule is distinct from new_rule and not has_own_setting) as changed, count(*) as people_checked from verify_101;
select who, role, old_rule, new_rule, has_own_setting from verify_101 where old_rule is distinct from new_rule order by role, who;
