-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (updates 97 and 98): Forms and Reports switched over to can()
-- (Stage 3b, D-049). Their "who" settings become access-level defaults;
-- nobody's access changes.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('lead@example.com', 'Taylor', 'team_leader'),
  ('sam@example.com', 'Sam', 'support_worker'), ('kim@example.com', 'Kim', 'support_worker'),
  ('ada@example.com', 'Ada', 'staff_admin');
insert into auth.users (email) values ('boss@example.com'), ('lead@example.com'), ('sam@example.com'), ('kim@example.com'), ('ada@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.as_check(p_email text, p_sql text) returns boolean language plpgsql as $$
declare v boolean;
begin
  perform test.act_as(p_email);
  execute 'set local role authenticated';
  execute 'select ' || p_sql into v;
  execute 'reset role';
  return v;
end $$;
grant execute on all functions in schema test to authenticated;
set session_replication_role = replica;
update public.features set enabled = true, included = true where key in ('vehicles', 'forms', 'form_builder');
set session_replication_role = origin;

-- Switched over, with the settings' defaults copied (fresh install).
select test.ok((select bool_and(grant_ready) from public.app_modules where id in ('workflows.forms', 'insights.reports', 'insights.reports.tasks', 'insights.reports.compliance', 'insights.reports.cars')), 'Forms and Reports are switched over');
select test.ok((select string_agg(module_id || '=' || access_level, ',' order by module_id) from public.access_baselines where (module_id like 'insights%' or module_id = 'workflows.forms') and revoked_at is null)
  = 'insights.reports.cars=manager,insights.reports.compliance=staff_admin,insights.reports.tasks=manager,workflows.forms=manager', 'defaults copied from the four settings');

-- Forms: same as today.
select test.ok(test.as_check('owner@example.com', 'public.can_make_forms()'), 'system admin makes forms');
select test.ok(test.as_check('boss@example.com', 'public.can_make_forms()'), 'manager makes forms (the setting)');
select test.ok(not test.as_check('ada@example.com', 'public.can_make_forms()'), 'staff admin doesn''t');
select test.ok(not test.as_check('sam@example.com', 'public.can_make_forms()'), 'support worker doesn''t');
update public.features set enabled = false where key = 'form_builder';
select test.ok(not test.as_check('boss@example.com', 'public.can_make_forms()') and test.as_check('owner@example.com', 'public.can_make_forms()'), 'form builder off: only the system admin (as before)');
update public.features set enabled = true where key = 'form_builder';

-- Reports: same as today.
select test.ok(test.as_check('boss@example.com', $$public.can('insights.reports.tasks', 'export')$$), 'manager sees and downloads the tasks report');
select test.ok(not test.as_check('ada@example.com', $$public.can('insights.reports.tasks', 'view')$$), 'staff admin doesn''t see the tasks report');
select test.ok(test.as_check('ada@example.com', $$public.can('insights.reports.compliance', 'view')$$), 'staff admin sees the compliance report');
select test.ok(not test.as_check('boss@example.com', $$public.can('insights.reports.compliance', 'view')$$), 'manager doesn''t (there''s a staff admin)');
select test.ok(test.as_check('boss@example.com', 'public.can_see_car_reports()'), 'manager sees car reports');
select test.ok(not test.as_check('lead@example.com', 'public.can_see_car_reports()') and not test.as_check('sam@example.com', $$public.can('insights.reports.tasks', 'view')$$), 'team leader and support worker see none');

-- Car managers still see car reports even without the report default.
select set_config('request.jwt.claims', '', false);
update public.access_baselines set revoked_at = now() where module_id = 'insights.reports.cars' and revoked_at is null;
select test.ok(test.as_check('boss@example.com', 'public.can_see_car_reports()'), 'car managers still see car reports');

-- Changed on the Access page now; old settings no longer decide.
insert into public.job_titles (name, access_level) values ('Quality Officer', 'support_worker');
update public.profiles set job_title_id = (select id from public.job_titles where name = 'Quality Officer') where email = 'kim@example.com';
select test.act_as('owner@example.com');
set role authenticated;
insert into public.access_baselines (job_title_id, module_id, actions) values ((select id from public.job_titles where name = 'Quality Officer'), 'insights.reports.compliance', '{view}');
insert into public.access_baselines (job_title_id, module_id, actions) values ((select id from public.job_titles where name = 'Quality Officer'), 'workflows.forms', '{view,create}');
reset role;
select test.ok(test.as_check('kim@example.com', $$public.can('insights.reports.compliance', 'view') and not public.can('insights.reports.compliance', 'export')$$), 'a role given the compliance report sees it (view only, as given)');
select test.ok(test.as_check('kim@example.com', 'public.can_make_forms()'), 'a role given Forms makes forms');
update public.app_settings set value = '["support_worker"]' where key in ('forms.maker_roles', 'reports.roles', 'reports.compliance_roles', 'vehicles.report_roles');
select test.ok(not test.as_check('sam@example.com', $$public.can_make_forms() or public.can('insights.reports.tasks', 'view') or public.can('insights.reports.compliance', 'view') or public.can_see_car_reports()$$), 'the old System settings no longer give access');

-- Existing copy with no staff admin: managers get the compliance report (old fallback, settled once).
select set_config('request.jwt.claims', '', false);
update public.access_baselines set revoked_at = now() where module_id like 'insights.reports%' and access_level is not null and revoked_at is null;
update public.app_settings set value = '["staff_admin"]' where key = 'reports.compliance_roles';
update public.profiles set active = false where email = 'ada@example.com';
\i supabase/live-updates/update-98.sql
\o /dev/null
select test.ok(test.as_check('boss@example.com', $$public.can('insights.reports.compliance', 'view')$$), 'no staff admin when it ran: managers see the compliance report');
\i supabase/live-updates/update-97.sql
\i supabase/live-updates/update-98.sql
\o /dev/null
select test.ok((select count(*) from public.access_baselines where module_id = 'workflows.forms' and access_level is not null and revoked_at is null) = 1, 'running them again adds nothing');

\o
