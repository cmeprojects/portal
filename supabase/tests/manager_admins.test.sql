-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects step 3: Manager Administrators (nominated managers only),
-- passing access on within limits, suspending and ending.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('boss2@example.com', 'Max', 'manager'), ('office@example.com', 'Olive', 'staff_admin'),
  ('office2@example.com', 'Oscar', 'staff_admin'), ('sam@example.com', 'Sam', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('boss2@example.com'), ('office@example.com'), ('office2@example.com'), ('sam@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.gid(p_email text, p_module text) returns uuid language sql security definer as $$
  select id from public.access_grants where user_id = test.pid(p_email) and module_id = p_module and revoked_at is null $$;
grant execute on all functions in schema test to authenticated;

-- Nominating
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$insert into public.admin_designations (user_id, granted_by) values (test.pid('boss@example.com'), test.pid('boss@example.com'))$$, 'managers can''t nominate themselves');
reset role;
select test.act_as('owner@example.com');
set role authenticated;
select test.refused($$insert into public.access_grants (module_id, user_id, granted_by) values ('ops.tasks', test.pid('boss@example.com'), test.pid('owner@example.com'))$$, 'admin access only to a nominated Manager Administrator');
select test.refused($$insert into public.admin_designations (user_id, granted_by) values (test.pid('office@example.com'), test.pid('owner@example.com'))$$, 'only managers can be nominated');
insert into public.admin_designations (user_id, granted_by, note) values (test.pid('boss@example.com'), test.pid('owner@example.com'), 'Runs HR');
select test.refused($$insert into public.admin_designations (user_id, granted_by) values (test.pid('boss@example.com'), test.pid('owner@example.com'))$$, 'one open nomination per person');
insert into public.access_grants (module_id, user_id, granted_by, can_pass_on, actions) values ('hr.onboarding', test.pid('boss@example.com'), test.pid('owner@example.com'), true, array['view', 'approve']);
insert into public.access_grants (module_id, user_id, granted_by) values ('ops.tasks', test.pid('boss@example.com'), test.pid('owner@example.com'));
reset role;
select test.ok(public.is_manager_admin(test.pid('boss@example.com')) and not public.is_manager_admin(test.pid('boss2@example.com')), 'only the nominated manager is a Manager Administrator');

select test.act_as('boss@example.com');
set role authenticated;
select test.ok(public.can('hr.onboarding.expiry', 'approve') and not public.can('hr.onboarding.expiry', 'configure'), 'a Manager Administrator has the access given, only those actions');
-- Passing on
select test.refused($$insert into public.access_grants (module_id, user_id, granted_by, parent_id) values ('ops.tasks', test.pid('office@example.com'), test.pid('boss@example.com'), test.gid('boss@example.com', 'ops.tasks'))$$, 'can''t pass on what wasn''t allowed to be passed on');
select test.refused($$insert into public.access_grants (module_id, user_id, granted_by, parent_id, actions) values ('hr.onboarding', test.pid('office@example.com'), test.pid('boss@example.com'), test.gid('boss@example.com', 'hr.onboarding'), array['configure'])$$, 'can''t pass on more actions than they have');
select test.refused($$insert into public.access_grants (module_id, user_id, granted_by, parent_id, actions) values ('hr.requests', test.pid('office@example.com'), test.pid('boss@example.com'), test.gid('boss@example.com', 'hr.onboarding'), array['view'])$$, 'can''t pass on a different module');
select test.refused($$insert into public.access_grants (module_id, user_id, granted_by, parent_id, actions) values ('hr.onboarding', test.pid('boss2@example.com'), test.pid('boss@example.com'), test.gid('boss@example.com', 'hr.onboarding'), array['view'])$$, 'only to staff admins');
select test.refused($$insert into public.access_grants (module_id, user_id, granted_by, parent_id, actions, can_pass_on) values ('hr.onboarding', test.pid('office@example.com'), test.pid('boss@example.com'), test.gid('boss@example.com', 'hr.onboarding'), array['view'], true)$$, 'never further');
insert into public.access_grants (module_id, user_id, granted_by, parent_id, actions) values ('hr.onboarding.expiry', test.pid('office@example.com'), test.pid('boss@example.com'), test.gid('boss@example.com', 'hr.onboarding'), array['view']);
select test.refused($$insert into public.admin_designations (user_id, granted_by) values (test.pid('boss2@example.com'), test.pid('boss@example.com'))$$, 'a Manager Administrator can''t nominate others');
select test.refused($$update public.admin_designations set expires_at = now() + interval '10 years' where user_id = test.pid('boss@example.com')$$, 'or change their own nomination');
reset role;

select test.act_as('office@example.com');
set role authenticated;
select test.ok(public.can('hr.onboarding.expiry', 'view') and not public.can('hr.onboarding', 'view'), 'the staff admin gets just what was passed on (one submodule, view)');
select test.ok(not public.can('ops.tasks'), 'nothing else');
reset role;
select test.act_as('office2@example.com');
set role authenticated;
select test.ok(not public.can('hr.onboarding.expiry'), 'another staff admin has nothing');
reset role;

-- Suspending stops it straight away (and what was passed on)
select test.act_as('owner@example.com');
set role authenticated;
update public.admin_designations set status = 'suspended' where user_id = test.pid('boss@example.com');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
select test.ok(not public.can('hr.onboarding') and not public.can('ops.tasks'), 'suspended: no admin access');
reset role;
select test.act_as('office@example.com');
set role authenticated;
select test.ok(not public.can('hr.onboarding.expiry'), 'and what they passed on stops too');
reset role;
select test.act_as('owner@example.com');
set role authenticated;
update public.admin_designations set status = 'active' where user_id = test.pid('boss@example.com');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
select test.ok(public.can('ops.tasks'), 'resumed: access back');
reset role;

-- Ending removes their module access, recorded
select test.act_as('owner@example.com');
set role authenticated;
update public.admin_designations set status = 'ended' where user_id = test.pid('boss@example.com');
select test.refused($$update public.admin_designations set status = 'active' where user_id = test.pid('boss@example.com')$$, 'an ended nomination can''t be reopened (nominate again instead)');
reset role;
select test.ok((select count(*) from public.access_grants where area is null and revoked_at is null) = 0, 'ending removes their access and what they passed on');
select test.ok((select changed_by from public.admin_designations where user_id = test.pid('boss@example.com')) = test.pid('owner@example.com'), 'who ended it is recorded');
select test.act_as('owner@example.com');
set role authenticated;
select test.refused($$delete from public.admin_designations$$, 'nominations are never deleted, even by the system admin');
reset role;

-- A time-limited nomination
select test.act_as('owner@example.com');
set role authenticated;
insert into public.admin_designations (user_id, granted_by, starts_at, expires_at) values (test.pid('boss2@example.com'), test.pid('owner@example.com'), now() - interval '2 days', now() - interval '1 day');
reset role;
select test.ok(not public.is_manager_admin(test.pid('boss2@example.com')), 'a nomination that has ended by date gives nothing');

select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$insert into public.admin_designations (user_id, granted_by) values (test.pid('sam@example.com'), test.pid('sam@example.com'))$$, 'staff can''t nominate');
reset role;
set role anon;
select test.refused($$select count(*) from public.admin_designations$$, 'signed out: nothing');
reset role;
