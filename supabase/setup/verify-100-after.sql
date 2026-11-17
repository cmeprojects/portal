-- Staff Portal · © cmeproject. All rights reserved.
-- Update 100, check AFTER (read only; changes no data). Compares who manages teams
-- under the old rule (managers, staff admins and the
-- system admin) with the new permission check.
-- Expected: one row, changed = 0. Any other rows list who differs.
create temp table if not exists verify_100 (who text, role text, old_rule boolean, new_rule boolean, has_own_setting boolean);
truncate verify_100;
do $$
declare p record;
begin
  for p in select id, coalesce(nullif(full_name, ''), email) as who, role from public.profiles where active and role <> 'system_admin' loop
    perform set_config('request.jwt.claims', json_build_object('sub', p.id, 'aal', 'aal2')::text, true);
    insert into verify_100 values (p.who, p.role::text, p.role in ('manager', 'staff_admin'), public.can('people.teams', 'edit'),
      exists (select 1 from public.access_grants g where g.user_id = p.id and g.area is null and g.revoked_at is null and (g.module_id = 'people.teams' or g.module_id = 'cat_people')));
  end loop;
  perform set_config('request.jwt.claims', '', true);
end $$;
select count(*) filter (where old_rule is distinct from new_rule and not has_own_setting) as changed, count(*) as people_checked from verify_100;
select who, role, old_rule, new_rule, has_own_setting from verify_100 where old_rule is distinct from new_rule order by role, who;
