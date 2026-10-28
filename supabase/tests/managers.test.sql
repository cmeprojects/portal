-- Staff Portal · © cmeproject. All rights reserved.
--
-- Who manages whom: managers change roles straight away; staff admins (HR)
-- need a manager's approval; nobody changes their own role; system admins
-- are hidden and can't be given tasks.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('boss2@example.com', 'Max', 'manager'),
  ('office@example.com', 'Olive', 'staff_admin'), ('sam@example.com', 'Sam', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('boss2@example.com'), ('office@example.com'), ('sam@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
grant execute on all functions in schema test to authenticated;

-- Managers
select test.act_as('boss@example.com');
set role authenticated;
insert into public.invitations (email, full_name, role) values
  ('new@example.com', 'New', 'support_worker'), ('m3@example.com', 'Mia', 'manager'), ('sa@example.com', 'Sid', 'staff_admin');
insert into public.teams (name) values ('Morgan''s team');
update public.profiles set role = 'team_leader' where email = 'sam@example.com';
update public.profiles set role = 'team_leader' where email = 'boss2@example.com';
select test.refused($$insert into public.invitations (email, role) values ('x@example.com', 'system_admin')$$,
  'a manager cannot invite a system admin');
select test.refused($$update public.profiles set role = 'staff_admin' where email = 'boss@example.com'$$,
  'a manager cannot change their own role');
select test.ok((select count(*) from public.profiles where role = 'system_admin') = 0, 'a manager cannot see the system admin');
reset role;
select test.ok((select count(*) from public.invitations where email in ('m3@example.com', 'sa@example.com')) = 2,
  'a manager can invite managers and staff admins');
select test.ok((select role = 'team_leader' from public.profiles where email = 'boss2@example.com')
               and (select role = 'team_leader' from public.profiles where email = 'sam@example.com'),
  'a manager can change roles straight away (even another manager''s)');

-- Staff admins (HR)
select test.act_as('office@example.com');
set role authenticated;
insert into public.invitations (email, full_name, role) values ('mgr@example.com', 'Mo', 'manager');
select test.refused($$insert into public.invitations (email, role) values ('y@example.com', 'system_admin')$$,
  'a staff admin cannot invite a system admin');
select test.refused($$update public.profiles set role = 'manager' where email = 'sam@example.com'$$,
  'a staff admin cannot change a role directly');
select test.refused($$select public.request_role_change(test.pid('office@example.com'), 'manager')$$,
  'a staff admin cannot request a change to their own role');
select test.refused($$select public.request_role_change(test.pid('owner@example.com'), 'manager')$$,
  'a staff admin cannot touch the system admin');
select public.request_role_change(test.pid('sam@example.com'), 'manager', p_reason => 'Running the Derrimut house');
update public.profiles set active = false where email = 'boss2@example.com';
select test.ok((select count(*) from public.profiles where role = 'system_admin') = 0, 'a staff admin cannot see the system admin');
reset role;
select test.ok((select role = 'team_leader' from public.profiles where email = 'sam@example.com'),
  'the role stays the same until a manager approves');
select test.ok((select not active from public.profiles where email = 'boss2@example.com'),
  'a staff admin can deactivate a manager');

select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$select public.decide_change_request((select id from public.people_change_requests limit 1), true)$$,
  'a team leader cannot approve role changes');
reset role;

select test.act_as('boss@example.com');
set role authenticated;
select public.decide_change_request((select id from public.people_change_requests where status = 'pending'), true);
reset role;
select test.ok((select role = 'manager' from public.profiles where email = 'sam@example.com'),
  'a manager approved the staff admin''s request and the role changed');
select test.ok((select count(*) from public.audit_log where action in ('role_change_requested', 'role_change_approved')) = 2,
  'the request and the approval are in the change log');

select test.act_as('office@example.com');
set role authenticated;
select public.request_role_change(test.pid('sam@example.com'), 'team_leader');
reset role;
select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$select public.decide_change_request((select id from public.people_change_requests where status = 'pending'), true)$$,
  'a manager cannot approve a change to their own role');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
select public.decide_change_request((select id from public.people_change_requests where status = 'pending'), false, 'Not yet');
reset role;
select test.ok((select role = 'manager' from public.profiles where email = 'sam@example.com'), 'a declined request changes nothing');

-- Only a system admin makes a system admin.
select test.act_as('owner@example.com');
set role authenticated;
select test.ok((select count(*) from public.profiles where role = 'system_admin') = 1, 'a system admin can see system admins');
reset role;

-- System admins can't be given tasks.
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$select public.create_task('x', (select id from public.registries where prefix = 'GEN'), test.pid('owner@example.com'))$$,
  'a system admin cannot be given a task');
select public.create_task('Helpers check', (select id from public.registries where prefix = 'GEN'), test.pid('sam@example.com'),
  p_helpers => array[test.pid('owner@example.com'), test.pid('office@example.com')]);
select test.refused($$select public.add_task_helper((select id from public.tasks where title = 'Helpers check'), test.pid('owner@example.com'))$$,
  'a system admin cannot be added as a helper');
reset role;
select test.ok((select array_agg(user_id) = array[test.pid('office@example.com')] from public.task_helpers),
  'a system admin picked as a helper is left off');

-- SLA: managers can change it, others can't.
select test.act_as('boss@example.com');
set role authenticated;
update public.app_settings set value = '{"urgent": 2, "high": 4, "medium": 8, "low": 15}' where key = 'tasks.sla_days';
select test.refused($$update public.app_settings set value = '"Hacked"' where key = 'brand.company_name'$$,
  'a manager cannot change other system settings');
reset role;
select test.ok((select value ->> 'urgent' = '2' from public.app_settings where key = 'tasks.sla_days'), 'a manager can change the SLA');
select test.act_as('office@example.com');
set role authenticated;
select test.refused($$update public.app_settings set value = '{}' where key = 'tasks.sla_days'$$,
  'a staff admin cannot change the SLA');
reset role;

-- ---------------------------------------------------------------------------
-- Teams: support workers in several teams, team leaders in one, managers and
-- staff admins in the core team (managers see every team's tasks).
-- ---------------------------------------------------------------------------

insert into public.invitations (email, full_name, role) values
  ('w1@example.com', 'Wren', 'support_worker'), ('tl@example.com', 'Tia', 'team_leader');
insert into auth.users (email) values ('w1@example.com'), ('tl@example.com');
insert into public.teams (name) values ('Team North'), ('Team South');
create function test.tid(p_name text) returns uuid language sql security definer as $$ select id from public.teams where name = p_name $$;
grant execute on all functions in schema test to authenticated;

select test.act_as('boss@example.com');
set role authenticated;
select public.set_team(test.tid('Team North'), array[test.pid('w1@example.com')], test.pid('tl@example.com'));
select public.set_team(test.tid('Team South'), array[test.pid('w1@example.com')], null);
select test.refused($$select public.set_team(test.tid('Team South'), array[test.pid('tl@example.com')], null)$$,
  'a team leader can be in one team only');
select test.refused($$select public.set_team(test.tid('Team South'), array[test.pid('office@example.com')], null)$$,
  'staff admins are in the core team, not in other teams');
select test.refused($$select public.set_team((select id from public.teams where is_core), array[test.pid('w1@example.com')], null)$$,
  'nobody is added to the core team by hand');
reset role;
select test.ok((select count(*) from public.team_members where user_id = test.pid('w1@example.com')) = 2,
  'a support worker can be in more than one team');
select test.ok(exists (select 1 from public.team_members where user_id = test.pid('tl@example.com') and team_id = test.tid('Team North')),
  'the team leader is a member of the team they lead');

-- The team leader sees tasks of people in their team; managers see everything.
select test.act_as('boss@example.com');
set role authenticated;
select public.create_task('North task', (select id from public.registries where prefix = 'GEN'), test.pid('w1@example.com'));
reset role;
select test.act_as('office@example.com');
set role authenticated;
select public.create_task('Office task', (select id from public.registries where prefix = 'GEN'), test.pid('sam@example.com'));
select test.ok((select count(*) from public.tasks where title = 'North task') = 0, 'a staff admin does not see other people''s tasks');
reset role;
select test.act_as('tl@example.com');
set role authenticated;
select test.ok((select count(*) from public.tasks where title = 'North task') = 1, 'a team leader sees their team''s tasks');
select test.ok((select count(*) from public.tasks where title = 'Office task') = 0, 'a team leader does not see other teams'' tasks');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
select test.ok((select count(*) from public.tasks where title in ('North task', 'Office task')) = 2, 'a manager sees every team''s tasks');
reset role;

-- Staff admins ask; a manager approves.
select test.act_as('office@example.com');
set role authenticated;
select test.refused($$select public.set_team(test.tid('Team South'), array[]::uuid[], null)$$,
  'a staff admin cannot change a team straight away');
select public.request_team_change(test.tid('Team South'), array[]::uuid[], null, 'Wren moved north');
reset role;
select test.ok((select count(*) from public.team_members where team_id = test.tid('Team South')) = 1, 'the team stays the same until approved');
select test.act_as('boss@example.com');
set role authenticated;
select public.decide_change_request((select id from public.people_change_requests where kind = 'team' and status = 'pending'), true);
reset role;
select test.ok((select count(*) from public.team_members where team_id = test.tid('Team South')) = 0, 'the approved team change is made');

-- A role change to manager moves them to the core team.
select test.act_as('boss@example.com');
set role authenticated;
update public.profiles set role = 'manager' where email = 'w1@example.com';
reset role;
select test.ok(not exists (select 1 from public.team_members where user_id = test.pid('w1@example.com')),
  'someone made a manager leaves their teams for the core team');
select test.act_as('boss@example.com');
set role authenticated;
update public.profiles set role = 'support_worker' where email = 'w1@example.com';
reset role;

-- ---------------------------------------------------------------------------
-- Job titles on top of access levels
-- ---------------------------------------------------------------------------

select test.act_as('boss@example.com');
set role authenticated;
insert into public.job_titles (name, access_level) values ('Nurse', 'support_worker'), ('House coordinator', 'team_leader');
select test.refused($$insert into public.job_titles (name, access_level) values ('Owner', 'system_admin')$$,
  'a role cannot have system admin access');
update public.profiles set job_title_id = (select id from public.job_titles where name = 'House coordinator') where email = 'sam@example.com';
reset role;
select test.ok((select role = 'team_leader' from public.profiles where email = 'sam@example.com'),
  'giving someone a role sets their access level');

select test.act_as('office@example.com');
set role authenticated;
select test.refused($$insert into public.job_titles (name, access_level) values ('HR helper', 'support_worker')$$,
  'a staff admin cannot add roles');
select test.refused($$update public.profiles set job_title_id = (select id from public.job_titles where name = 'Nurse') where email = 'sam@example.com'$$,
  'a staff admin cannot change a role directly');
select public.request_role_change(test.pid('sam@example.com'), 'support_worker', (select id from public.job_titles where name = 'Nurse'));
reset role;
select test.act_as('boss@example.com');
set role authenticated;
select public.decide_change_request((select id from public.people_change_requests where kind = 'role' and status = 'pending'), true);
select test.refused($$update public.job_titles set access_level = 'manager' where name = 'Nurse'$$,
  'a role in use cannot change access level');
reset role;
select test.ok((select role = 'support_worker' and job_title_id = (select id from public.job_titles where name = 'Nurse')
                  from public.profiles where email = 'sam@example.com'),
  'an approved request gives the role and its access level');

-- Invited with a role.
select test.act_as('boss@example.com');
set role authenticated;
insert into public.invitations (email, full_name, role, job_title_id, team_id)
values ('nurse@example.com', 'Nia', 'support_worker', (select id from public.job_titles where name = 'Nurse'), test.tid('Team North'));
reset role;
insert into auth.users (email) values ('nurse@example.com');
select test.ok((select job_title_id is not null and role = 'support_worker' from public.profiles where email = 'nurse@example.com')
               and exists (select 1 from public.team_members where user_id = test.pid('nurse@example.com') and team_id = test.tid('Team North')),
  'an invited person gets their role and team');

\o
\echo 'All manager tests passed.'
