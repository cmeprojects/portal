-- Staff Portal · © cmeproject. All rights reserved.
-- Update 99, check AFTER (read only; changes no data). Compares who sees
-- everyone's staff requests under the old rule (managers, staff admins and the
-- system admin) with the new permission check.
-- Expected: one row, changed = 0. Any other rows list who differs.
create temp table if not exists verify_99 (who text, role text, old_rule boolean, new_rule boolean, has_own_setting boolean);
truncate verify_99;
do $$
declare p record;
begin
  for p in select id, coalesce(nullif(full_name, ''), email) as who, role from public.profiles where active and role <> 'system_admin' loop
    perform set_config('request.jwt.claims', json_build_object('sub', p.id, 'aal', 'aal2')::text, true);
    insert into verify_99 values (p.who, p.role::text, p.role in ('manager', 'staff_admin'), public.can('hr.requests', 'view'),
      exists (select 1 from public.access_grants g where g.user_id = p.id and g.area is null and g.revoked_at is null and (g.module_id = 'hr.requests' or g.module_id = 'cat_hr')));
  end loop;
  perform set_config('request.jwt.claims', '', true);
end $$;
select count(*) filter (where old_rule is distinct from new_rule and not has_own_setting) as changed, count(*) as people_checked from verify_99;
select who, role, old_rule, new_rule, has_own_setting from verify_99 where old_rule is distinct from new_rule order by role, who;
