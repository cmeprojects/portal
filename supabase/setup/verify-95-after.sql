-- Staff Portal · © cmeproject. All rights reserved.
-- Update 95, check AFTER (read only; changes no data). Compares each active
-- person's onboarding access under the old rules (System setting "Who manages
-- Compliance", managers while there's no staff admin, managers and team
-- leaders see progress) with the new permission check.
-- Expected: one row, changed = 0. Any other rows list who differs and why.
create temp table if not exists verify_95 (who text, role text, old_manage boolean, new_manage boolean, old_view boolean, new_view boolean, person_block boolean);
truncate verify_95;
do $$
declare
  p record;
  v_no_sa boolean := not exists (select 1 from public.profiles where role = 'staff_admin' and active);
  v_old_m boolean;
begin
  for p in select id, coalesce(nullif(full_name, ''), email) as who, role from public.profiles where active and role <> 'system_admin' loop
    perform set_config('request.jwt.claims', json_build_object('sub', p.id, 'aal', 'aal2')::text, true);
    v_old_m := p.role = any (public.setting_roles('compliance.manager_roles')) or (p.role = 'manager' and v_no_sa);
    insert into verify_95 values (
      p.who, p.role::text,
      v_old_m, public.can_manage_compliance(),
      v_old_m or p.role in ('manager', 'team_leader'), public.can('hr.onboarding', 'view'),
      exists (select 1 from public.access_grants g where g.user_id = p.id and g.area is null and g.revoked_at is null and g.module_id like 'hr.onboarding%'));
  end loop;
  perform set_config('request.jwt.claims', '', true);
end $$;
select count(*) filter (where (old_manage is distinct from new_manage or old_view is distinct from new_view) and not person_block) as changed,
       count(*) as people_checked,
       count(*) filter (where person_block) as with_own_onboarding_setting
  from verify_95;
select who, role, old_manage, new_manage, old_view, new_view, person_block as has_own_setting
  from verify_95
 where old_manage is distinct from new_manage or old_view is distinct from new_view
 order by role, who;
