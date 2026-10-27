-- Staff Portal · © cmeproject. All rights reserved.
--
-- Managers can manage support workers and team leaders; system admins
-- can't be given tasks.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('boss2@example.com', 'Max', 'manager'),
  ('office@example.com', 'Olive', 'staff_admin'), ('sam@example.com', 'Sam', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('boss2@example.com'), ('office@example.com'), ('sam@example.com');
create function test.pid(p_email text) returns uuid language sql as $$ select id from public.profiles where email = p_email $$;
grant execute on all functions in schema test to authenticated;

select test.act_as('boss@example.com');
set role authenticated;
insert into public.invitations (email, full_name, role) values ('new@example.com', 'New', 'support_worker');
insert into public.teams (name) values ('Morgan''s team');
update public.profiles set role = 'team_leader', team_id = (select id from public.teams limit 1) where email = 'sam@example.com';
select test.refused($$insert into public.invitations (email, role) values ('m@example.com', 'manager')$$,
  'a manager cannot invite another manager');
select test.refused($$update public.profiles set role = 'support_worker' where email = 'boss2@example.com'$$,
  'a manager cannot change another manager');
select test.refused($$update public.profiles set active = false where email = 'office@example.com'$$,
  'a manager cannot deactivate a staff admin');
select test.refused($$update public.profiles set role = 'manager' where email = 'sam@example.com'$$,
  'a manager cannot promote someone to manager');
select test.ok((select count(*) from public.invitations) >= 1, 'a manager can see invitations');
reset role;
select test.ok((select role = 'team_leader' and team_id is not null from public.profiles where email = 'sam@example.com'),
  'a manager can invite support workers, add teams, and change a support worker to team leader');

select test.act_as('office@example.com');
set role authenticated;
update public.profiles set role = 'support_worker' where email = 'boss2@example.com';
reset role;
select test.ok((select role = 'support_worker' from public.profiles where email = 'boss2@example.com'),
  'a staff admin can still change a manager');
select test.act_as('office@example.com');
set role authenticated;
select test.refused($$update public.profiles set role = 'system_admin' where email = 'sam@example.com'$$,
  'a staff admin cannot make anyone a system admin');
select test.refused($$insert into public.invitations (email, role) values ('sa@example.com', 'system_admin')$$,
  'a staff admin cannot invite a system admin');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$update public.profiles set role = 'system_admin' where email = 'sam@example.com'$$,
  'a manager cannot make anyone a system admin');
select test.refused($$insert into public.invitations (email, role) values ('sa2@example.com', 'system_admin')$$,
  'a manager cannot invite a system admin');
reset role;
select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$update public.profiles set role = 'system_admin' where email = 'sam@example.com'$$,
  'a team leader cannot make themselves a system admin');
reset role;

-- System admins can't be given tasks.
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$select public.create_task('x', (select id from public.registries where prefix = 'GEN'), test.pid('owner@example.com'))$$,
  'a system admin cannot be given a task');
select public.create_task('Helpers check', (select id from public.registries where prefix = 'GEN'), test.pid('sam@example.com'),
  p_helpers => array[test.pid('owner@example.com'), test.pid('boss2@example.com')]);
select test.refused($$select public.add_task_helper((select id from public.tasks where title = 'Helpers check'), test.pid('owner@example.com'))$$,
  'a system admin cannot be added as a helper');
reset role;
select test.ok((select array_agg(user_id) = array[test.pid('boss2@example.com')] from public.task_helpers),
  'a system admin picked as a helper is left off');

\o
\echo 'All manager tests passed.'
