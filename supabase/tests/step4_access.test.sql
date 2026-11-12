-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects step 4: Onboarding and Cars follow the Access page as well as
-- the role rules. Nobody loses access; nobody gains it without a grant.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('boss2@example.com', 'Max', 'manager'), ('office@example.com', 'Olive', 'staff_admin'), ('sam@example.com', 'Sam', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('boss2@example.com'), ('office@example.com'), ('sam@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
grant execute on all functions in schema test to authenticated;
-- Cars on; only the system admin manages cars by role; onboarding managed by staff admins by role.
set session_replication_role = replica;
update public.features set enabled = true, included = true where key = 'vehicles';
set session_replication_role = origin;
update public.app_settings set value = '[]'::jsonb where key = 'vehicles.manager_roles';
update public.app_settings set value = '["staff_admin"]'::jsonb where key = 'compliance.manager_roles';

select test.act_as('boss@example.com');
set role authenticated;
select test.ok(not public.can_manage_compliance() and not public.can_manage_cars(), 'a manager without access given: neither (as before)');
reset role;
select test.act_as('office@example.com');
set role authenticated;
select test.ok(public.can_manage_compliance() and not public.can_manage_cars(), 'a staff admin: onboarding by role (unchanged), not cars');
reset role;

-- The system admin nominates Morgan and gives Onboarding (approve) and Manage cars (set up).
select test.act_as('owner@example.com');
set role authenticated;
insert into public.admin_designations (user_id, granted_by) values (test.pid('boss@example.com'), test.pid('owner@example.com'));
insert into public.access_grants (module_id, user_id, granted_by, actions, can_pass_on) values
  ('hr.onboarding', test.pid('boss@example.com'), test.pid('owner@example.com'), array['view', 'approve'], true),
  ('ops.cars.manage', test.pid('boss@example.com'), test.pid('owner@example.com'), array['view', 'configure'], true);
reset role;

select test.act_as('boss@example.com');
set role authenticated;
select test.ok(public.can_manage_compliance() and public.can_manage_cars(), 'given on the Access page: approves onboarding and manages cars');
-- And passes Manage cars on to Olive.
insert into public.access_grants (module_id, user_id, granted_by, parent_id, actions)
  select 'ops.cars.manage', test.pid('office@example.com'), test.pid('boss@example.com'), id, array['configure'] from public.access_grants where user_id = test.pid('boss@example.com') and module_id = 'ops.cars.manage';
reset role;
select test.act_as('office@example.com');
set role authenticated;
select test.ok(public.can_manage_cars(), 'passed on: the staff admin manages cars');
reset role;

select test.act_as('boss2@example.com');
set role authenticated;
select test.ok(not public.can_manage_compliance() and not public.can_manage_cars(), 'another manager still has neither');
reset role;
select test.act_as('sam@example.com');
set role authenticated;
select test.ok(not public.can_manage_compliance() and not public.can_manage_cars(), 'a support worker has neither');
reset role;

-- Suspending the nomination stops it (and what was passed on).
select test.act_as('owner@example.com');
set role authenticated;
update public.admin_designations set status = 'suspended' where user_id = test.pid('boss@example.com');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
select test.ok(not public.can_manage_compliance() and not public.can_manage_cars(), 'suspended: back to the role rules');
reset role;
select test.act_as('office@example.com');
set role authenticated;
select test.ok(not public.can_manage_cars() and public.can_manage_compliance(), 'the staff admin loses cars but keeps onboarding by role');
reset role;
