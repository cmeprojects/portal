-- Staff Portal · © cmeproject. All rights reserved.
--
-- Who can see and change tasks, and who gets emailed.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

-- People: owner (system admin), a manager of Compliance, a team leader
-- leading Sam's team, support workers in different teams, a staff admin.
insert into auth.users (email) values ('owner@example.com');
insert into public.teams (name) values ('Team A'), ('Team B');
insert into public.invitations (email, full_name, role, team_id) values
  ('boss@example.com', 'Morgan Manager', 'manager', null),
  ('lead@example.com', 'Taylor Lead', 'team_leader', null),
  ('sam@example.com',  'Sam Worker', 'support_worker', (select id from public.teams where name = 'Team A')),
  ('kim@example.com',  'Kim Worker', 'support_worker', (select id from public.teams where name = 'Team B')),
  ('ali@example.com',  'Ali Worker', 'support_worker', (select id from public.teams where name = 'Team B')),
  ('office@example.com', 'Olive Office', 'staff_admin', null);
insert into auth.users (email) values
  ('boss@example.com'), ('lead@example.com'), ('sam@example.com'), ('kim@example.com'),
  ('ali@example.com'), ('office@example.com');
insert into public.team_leaders (team_id, user_id)
select t.id, p.id from public.teams t, public.profiles p where t.name = 'Team A' and p.email = 'lead@example.com';
insert into public.registry_managers (registry_id, user_id)
select r.id, p.id from public.registries r, public.profiles p
 where r.name = 'Compliance Registry' and p.email = 'boss@example.com';

create function test.pid(p_email text) returns uuid language sql as $$
  select id from public.profiles where email = p_email
$$;
create function test.rid(p_name text) returns uuid language sql as $$
  select id from public.registries where name = p_name
$$;
create function test.visible(p_email text) returns bigint language plpgsql as $$
declare n bigint;
begin
  perform test.act_as(p_email);
  set local role authenticated;
  select count(*) into n from public.tasks;
  reset role;
  return n;
end $$;
grant execute on all functions in schema test to authenticated;

-- ---------------------------------------------------------------------------
-- Creating tasks
-- ---------------------------------------------------------------------------

select test.act_as('kim@example.com', 'aal1');
set role authenticated;
select test.refused($$insert into public.tasks (title, registry_id, assigned_to, created_by)
  values ('x', test.rid('Maintenance'), test.pid('kim@example.com'), test.pid('kim@example.com'))$$,
  'nobody can insert into tasks directly');
select test.refused($$select public.create_task('  ', test.rid('Maintenance'), test.pid('sam@example.com'))$$,
  'a task needs a title');
-- Task 1: Kim (Team B) creates a Maintenance task for Sam (Team A), helped by Ali.
select public.create_task('Fix the back door', test.rid('Maintenance'), test.pid('sam@example.com'),
  'It sticks when wet', 'medium', current_date + 3,
  array[test.pid('ali@example.com'), test.pid('sam@example.com')]);
reset role;

select test.ok((select created_by = test.pid('kim@example.com') and status = 'assigned' and number = 1
                  from public.tasks),
  'task is created by the signed-in person, starts as Assigned and gets number 1');
select test.ok((select array_agg(user_id) = array[test.pid('ali@example.com')] from public.task_helpers),
  'the person looking after a task is never also listed as a helper');
select test.ok((select array_agg(type order by id) = array['created', 'helper_added'] from public.task_events),
  'creating and adding a helper are on the timeline');
select test.ok((select count(*) = 1 and bool_and(to_user = test.pid('sam@example.com')
                       and cc_users = array[test.pid('ali@example.com')] and template = 'task_assigned')
                  from public.email_outbox),
  'one email to the assignee with the helper copied in (no manager on Maintenance)');

-- Task 2: Morgan (manager) creates a Compliance task for Kim.
select test.act_as('boss@example.com');
set role authenticated;
select public.create_task('Update screening register', test.rid('Compliance Registry'), test.pid('kim@example.com'),
  '', 'high', current_date - 1, '{}');
reset role;
select test.ok((select count(*) from public.email_outbox where template = 'task_created_manager') = 0,
  'the manager is not emailed about a task they created themselves');

-- Task 3: Kim creates a Compliance task for herself; the manager hears about it.
select test.act_as('kim@example.com');
set role authenticated;
select public.create_task('Check fire extinguishers', test.rid('Compliance Registry'), test.pid('kim@example.com'));
reset role;
select test.ok((select count(*) from public.email_outbox where template = 'task_created_manager'
                  and to_user = test.pid('boss@example.com')) = 1,
  'registry manager is emailed about a new task in their registry');
select test.ok((select count(*) from public.email_outbox where to_user = test.pid('kim@example.com')) = 1,
  'nobody is emailed about a task they assigned to themselves (only task 2 emailed Kim)');

-- ---------------------------------------------------------------------------
-- Who can see what
-- ---------------------------------------------------------------------------

select test.ok(test.visible('sam@example.com') = 1, 'support worker sees only the task assigned to them');
select test.ok(test.visible('ali@example.com') = 1, 'helper sees the task they help on');
select test.ok(test.visible('kim@example.com') = 3, 'creator sees tasks they created and tasks assigned to them');
select test.ok(test.visible('lead@example.com') = 1, 'team leader sees tasks of support workers in their team');
select test.ok(test.visible('boss@example.com') = 2, 'manager sees every task in their registry and nothing else');
select test.ok(test.visible('office@example.com') = 0, 'staff admin does not see task content');
select test.ok(test.visible('owner@example.com') = 3, 'system admin sees every task');

select test.act_as('sam@example.com');
set role authenticated;
select test.ok((select count(*) from public.task_events) = 2, 'support worker sees the timeline of their task only');
select test.refused($$update public.tasks set title = 'changed'$$, 'nobody can edit tasks directly');
select test.refused($$delete from public.tasks$$, 'nobody can delete tasks');
select test.refused($$select * from public.email_outbox$$, 'nobody can read the email queue from the app');
reset role;

-- ---------------------------------------------------------------------------
-- Adding helpers
-- ---------------------------------------------------------------------------

select test.act_as('sam@example.com');
set role authenticated;
select public.add_task_helper((select id from public.tasks where number = 1), test.pid('lead@example.com'));
select test.refused($$select public.add_task_helper((select id from public.tasks where number = 1), test.pid('lead@example.com'))$$,
  'the same helper cannot be added twice');
select test.refused($$select public.add_task_helper((select id from public.tasks where number = 1), test.pid('sam@example.com'))$$,
  'the person looking after the task cannot be added as a helper');
select test.refused($$select public.add_task_helper((select id from public.tasks where number = 2), test.pid('sam@example.com'))$$,
  'you cannot add helpers to a task you cannot see');
reset role;
select test.ok((select count(*) from public.email_outbox where template = 'helper_added'
                  and to_user = test.pid('lead@example.com')) = 1,
  'the new helper is emailed');

-- ---------------------------------------------------------------------------
-- Switches and history
-- ---------------------------------------------------------------------------

update public.features set enabled = false where key = 'email_notifications';
select test.act_as('kim@example.com');
set role authenticated;
select public.create_task('No email please', test.rid('Maintenance'), test.pid('sam@example.com'));
reset role;
select test.ok((select count(*) from public.email_outbox
                 where task_id = (select id from public.tasks where title = 'No email please')) = 0,
  'no emails are queued when email notifications are switched off');

update public.features set enabled = false where key = 'tasks';
select test.ok(test.visible('sam@example.com') = 2, 'tasks stay readable when the Tasks feature is switched off');
select test.act_as('kim@example.com');
set role authenticated;
select test.refused($$select public.create_task('x', test.rid('Maintenance'), test.pid('sam@example.com'))$$,
  'no new tasks while the Tasks feature is switched off');
reset role;

select set_config('request.jwt.claims', '{}', false);
select test.refused($$update public.task_events set comment = 'rewritten'$$, 'the timeline cannot be edited');
select test.refused($$delete from public.task_events$$, 'the timeline cannot be deleted');

\o
\echo 'All task security tests passed.'
