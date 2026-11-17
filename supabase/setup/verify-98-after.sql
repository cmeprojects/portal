-- Staff Portal · © cmeproject. All rights reserved.
-- Updates 97 and 98, check AFTER (read only; changes no data). Compares each
-- active person's access to Forms and the three reports under the old System
-- settings with the new permission check.
-- Expected: one row, changed = 0. Any other rows list who differs.
create temp table if not exists verify_98 (who text, role text, part text, old_rule boolean, new_rule boolean, has_own_setting boolean);
truncate verify_98;
do $$
declare
  p record;
  v_no_sa boolean := not exists (select 1 from public.profiles where role = 'staff_admin' and active);
  v_own boolean;
begin
  for p in select id, coalesce(nullif(full_name, ''), email) as who, role from public.profiles where active and role <> 'system_admin' loop
    perform set_config('request.jwt.claims', json_build_object('sub', p.id, 'aal', 'aal2')::text, true);
    v_own := exists (select 1 from public.access_grants g where g.user_id = p.id and g.area is null and g.revoked_at is null
                       and (g.module_id like 'workflows.forms%' or g.module_id like 'insights.reports%' or g.module_id like 'cat_%'));
    insert into verify_98 values
      (p.who, p.role::text, 'make forms',
       public.feature_enabled('forms') and public.feature_enabled('form_builder') and p.role = any (public.setting_roles('forms.maker_roles')),
       public.can_make_forms(), v_own),
      (p.who, p.role::text, 'tasks report', p.role = any (public.setting_roles('reports.roles')), public.can('insights.reports.tasks', 'view'), v_own),
      (p.who, p.role::text, 'compliance report', p.role = any (public.setting_roles('reports.compliance_roles')) or (p.role = 'manager' and v_no_sa),
       public.can('insights.reports.compliance', 'view'), v_own),
      (p.who, p.role::text, 'car reports', public.cars_on() and (p.role = any (public.setting_roles('vehicles.report_roles')) or public.can_manage_cars()),
       public.can_see_car_reports(), v_own);
  end loop;
  perform set_config('request.jwt.claims', '', true);
end $$;
select count(*) filter (where old_rule is distinct from new_rule and not has_own_setting) as changed,
       count(distinct who) as people_checked
  from verify_98;
select who, role, part, old_rule, new_rule, has_own_setting
  from verify_98 where old_rule is distinct from new_rule order by part, role, who;
