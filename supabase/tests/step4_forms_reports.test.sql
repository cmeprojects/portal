-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects step 4 (second batch): Forms and the Cars report follow the
-- Access page as well as the role rules.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('boss@example.com', 'Morgan', 'manager'), ('boss2@example.com', 'Max', 'manager'), ('office@example.com', 'Olive', 'staff_admin');
insert into auth.users (email) values ('boss@example.com'), ('boss2@example.com'), ('office@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
grant execute on all functions in schema test to authenticated;
set session_replication_role = replica;
update public.features set enabled = true, included = true where key in ('vehicles', 'forms', 'form_builder');
set session_replication_role = origin;
update public.app_settings set value = '[]'::jsonb where key in ('forms.maker_roles', 'vehicles.manager_roles', 'vehicles.report_roles');

select test.act_as('boss@example.com');
set role authenticated;
select test.ok(not public.can_make_forms() and not public.can_see_car_reports(), 'a manager without access given: no forms, no car report (as set)');
reset role;

select test.act_as('owner@example.com');
set role authenticated;
insert into public.admin_designations (user_id, granted_by) values (test.pid('boss@example.com'), test.pid('owner@example.com'));
insert into public.access_grants (module_id, user_id, granted_by, actions, can_pass_on) values
  ('workflows.forms', test.pid('boss@example.com'), test.pid('owner@example.com'), array['view', 'create'], true),
  ('insights.reports', test.pid('boss@example.com'), test.pid('owner@example.com'), array['view'], false);
reset role;

select test.act_as('boss@example.com');
set role authenticated;
select test.ok(public.can_make_forms(), 'given Forms (create): makes forms');
select test.ok(public.can_see_car_reports(), 'given Reports: sees the Cars report (inside Reports)');
select test.ok(public.can('insights.reports.cars', 'view') and not public.can('insights.reports.cars', 'export'), 'view only: no Excel download');
insert into public.access_grants (module_id, user_id, granted_by, parent_id, actions)
  select 'workflows.forms', test.pid('office@example.com'), test.pid('boss@example.com'), id, array['view', 'create'] from public.access_grants where user_id = test.pid('boss@example.com') and module_id = 'workflows.forms';
reset role;
select test.act_as('office@example.com');
set role authenticated;
select test.ok(public.can_make_forms(), 'passed on: the staff admin makes forms');
reset role;
select test.act_as('boss2@example.com');
set role authenticated;
select test.ok(not public.can_make_forms() and not public.can_see_car_reports(), 'another manager: neither');
reset role;

-- Switching the Form builder off still wins.
set session_replication_role = replica;
update public.features set enabled = false where key = 'form_builder';
set session_replication_role = origin;
select test.act_as('boss@example.com');
set role authenticated;
select test.ok(not public.can_make_forms(), 'with the Form builder switched off, access given doesn''t make forms');
reset role;
