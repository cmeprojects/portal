-- Staff Portal · © cmeproject. All rights reserved.
-- Update 98: Reports switched over to the one permission check (Stage 3b).
-- Today's settings are copied once into access-level defaults on the Access
-- page, so nobody's access changes. Safe to run again. Undo: undo-98.sql.
-- Run update 97 first.
begin;
-- cmeprojects (update 98; function-based access, Stage 3b; D-047, D-049):
-- Reports (tasks, compliance, cars) switched over to the one permission check
-- `can()`.
--
--   * Who sees each report (and downloads it) now comes only from
--     `can('insights.reports.<report>', 'view' / 'export')`. Car managers
--     still see the car reports.
--   * Today's System settings are copied once into access-level defaults, so
--     nobody's access changes:
--       - "Who sees reports" → the Tasks report;
--       - "Who sees the compliance report" → the Compliance report, plus
--         managers if there's no active staff admin when this runs (the old
--         fallback, settled once; a fresh install starts without it);
--       - "Who sees car reports" → the Cars reports.
--     After this they're changed on the Access page; the old settings are kept
--     but no longer used.

update public.app_modules set grant_ready = true
 where id in ('insights.reports', 'insights.reports.tasks', 'insights.reports.compliance', 'insights.reports.cars') and not grant_ready;

do $$
declare
  v_comp public.app_role[];
begin
  if exists (select 1 from public.access_baselines
              where module_id like 'insights.reports%' and access_level is not null and revoked_at is null) then
    return;
  end if;
  insert into public.access_baselines (access_level, module_id, actions, scope, note)
  select distinct r, 'insights.reports.tasks', '{}'::text[], 'all', 'Set at switch-over from "Who sees reports"'
    from unnest(public.setting_roles('reports.roles')) r
   where r not in ('system_admin', 'new_starter', 'external');
  v_comp := public.setting_roles('reports.compliance_roles');
  if exists (select 1 from public.profiles where role <> 'system_admin')
     and not exists (select 1 from public.profiles where role = 'staff_admin' and active) then
    v_comp := v_comp || 'manager'::public.app_role;
  end if;
  insert into public.access_baselines (access_level, module_id, actions, scope, note)
  select distinct r, 'insights.reports.compliance', '{}'::text[], 'all', 'Set at switch-over from "Who sees the compliance report"'
    from unnest(v_comp) r
   where r not in ('system_admin', 'new_starter', 'external');
  insert into public.access_baselines (access_level, module_id, actions, scope, note)
  select distinct r, 'insights.reports.cars', '{}'::text[], 'all', 'Set at switch-over from "Who sees car reports"'
    from unnest(public.setting_roles('vehicles.report_roles')) r
   where r not in ('system_admin', 'new_starter', 'external');
end $$;

-- Car reports: car managers, or given the Cars report (Cars switched on).
create or replace function public.can_see_car_reports()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.can_manage_cars() or (public.cars_on() and public.can('insights.reports.cars', 'view'))
$$;
commit;
