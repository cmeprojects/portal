-- Staff Portal · © cmeproject. All rights reserved.
--
-- Reminders, overdue alerts, automatic escalation and the managers' morning
-- summary. "Today" is Wednesday 4 November 2026, 9am Melbourne time.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('lead@example.com', 'Taylor', 'team_leader'),
  ('sam@example.com', 'Sam', 'support_worker'), ('kim@example.com', 'Kim', 'support_worker'),
  ('office@example.com', 'Olive', 'staff_admin');
insert into auth.users (email) values ('boss@example.com'), ('lead@example.com'), ('sam@example.com'), ('kim@example.com'), ('office@example.com');
insert into public.teams (name) values ('Team A');
insert into public.team_leaders (team_id, user_id)
select t.id, p.id from public.teams t, public.profiles p where t.name = 'Team A' and p.email = 'lead@example.com';
insert into public.team_members (team_id, user_id)
select t.id, p.id from public.teams t, public.profiles p where t.name = 'Team A' and p.email = 'sam@example.com';

create function test.pid(p_email text) returns uuid language sql as $$ select id from public.profiles where email = p_email $$;
create function test.tid(p_title text) returns uuid language sql as $$ select id from public.tasks where title = p_title $$;
create function test.alerts(p_title text, p_step text) returns text language sql as $$
  select coalesce(string_agg(p.email, ',' order by p.email), '')
    from public.task_alerts a join public.profiles p on p.id = a.user_id
   where a.task_id = test.tid(p_title) and a.step = p_step $$;
grant execute on all functions in schema test to authenticated;

select test.act_as('boss@example.com');
set role authenticated;
select public.create_task('Due tomorrow', (select id from public.registries where prefix = 'GEN'), test.pid('sam@example.com'), p_due_date => date '2026-11-05');
select public.create_task('Due today', (select id from public.registries where prefix = 'GEN'), test.pid('sam@example.com'), p_due_date => date '2026-11-04',
  p_helpers => array[test.pid('kim@example.com')]);
select public.create_task('One day late', (select id from public.registries where prefix = 'GEN'), test.pid('sam@example.com'), p_due_date => date '2026-11-03');
select public.create_task('Kim late', (select id from public.registries where prefix = 'GEN'), test.pid('kim@example.com'), p_due_date => date '2026-11-03');
select public.create_task('Very late', (select id from public.registries where prefix = 'GEN'), test.pid('sam@example.com'), p_due_date => date '2026-10-30');
select public.create_task('Done late', (select id from public.registries where prefix = 'GEN'), test.pid('sam@example.com'), p_due_date => date '2026-10-30');
select public.create_task('No date', (select id from public.registries where prefix = 'GEN'), test.pid('sam@example.com'));
reset role;
update public.tasks set status = 'completed' where title = 'Done late';
delete from public.email_outbox;

select set_config('request.jwt.claims', '{}', false), public.run_due_alerts(timestamptz '2026-11-04 09:00 Australia/Melbourne');

select test.ok(test.alerts('Due tomorrow', 'reminder') = 'sam@example.com', 'a reminder goes to the person a day before');
select test.ok(test.alerts('Due today', 'due_today') = 'kim@example.com,sam@example.com', 'on the day, the person and helpers are told');
select test.ok(test.alerts('One day late', 'overdue') = 'lead@example.com,sam@example.com', 'overdue: the person and their team leader');
select test.ok(test.alerts('Kim late', 'overdue') = 'boss@example.com,kim@example.com', 'no team leader: the managers are told');
select test.ok(test.alerts('One day late', 'escalated') = '', 'one day late is not escalated yet');
select test.ok((select status = 'escalated' and escalated from public.tasks where title = 'Very late'), 'three days overdue: marked escalated');
select test.ok(test.alerts('Very late', 'escalated') = 'boss@example.com', 'the managers are told about the escalation');
select test.ok(exists (select 1 from public.task_events where task_id = test.tid('Very late') and to_value = 'escalated'),
  'the escalation is in the task history');
select test.ok((select count(*) from public.task_alerts where task_id in (test.tid('Done late'), test.tid('No date'))) = 0,
  'completed tasks and tasks with no due date never alert');
select test.ok(not exists (select 1 from public.task_alerts a join public.profiles p on p.id = a.user_id where p.role in ('staff_admin', 'system_admin')),
  'staff admins and system admins are not told');
select test.ok((select count(*) from public.email_outbox where template = 'overdue_summary') = 1
               and (select jsonb_array_length(data -> 'tasks') from public.email_outbox where template = 'overdue_summary') = 3,
  'one morning summary to the manager, listing the three overdue tasks');
select test.ok((select count(*) from public.email_outbox where template like 'task_%')
               = (select count(*) from public.task_alerts where step in ('overdue', 'escalated')),
  'one email per overdue or escalated alert');
select test.ok(not exists (select 1 from public.email_outbox where template in ('task_reminder', 'task_due_today')),
  'reminders and due today go to the bell only, not email');

-- Running again sends nothing new.
select set_config('request.jwt.claims', '{}', false), public.run_due_alerts(timestamptz '2026-11-04 10:00 Australia/Melbourne');
select test.ok((select count(*) from public.email_outbox)
               = (select count(*) from public.task_alerts where step in ('overdue', 'escalated')) + 1, 'running again sends nothing twice');

-- The bell.
select test.act_as('lead@example.com');
set role authenticated;
select test.ok((select count(*) from public.my_due_alerts()) = 2, 'the team leader sees their team''s overdue tasks in their bell');
select public.mark_all_tasks_seen();
select test.ok((select count(*) from public.my_due_alerts()) = 0, 'mark all as seen clears it');
reset role;

-- A new due date starts again.
update public.tasks set due_date = date '2026-11-05' where title = 'One day late';
select set_config('request.jwt.claims', '{}', false), public.run_due_alerts(timestamptz '2026-11-04 11:00 Australia/Melbourne');
select test.ok(test.alerts('One day late', 'reminder') = 'sam@example.com', 'a new due date starts the steps again');

-- Before 7am, and at the weekend, there's no summary.
delete from public.daily_runs;
delete from public.email_outbox;
select set_config('request.jwt.claims', '{}', false), public.run_due_alerts(timestamptz '2026-11-05 06:00 Australia/Melbourne');
select test.ok(not exists (select 1 from public.email_outbox where template = 'overdue_summary'), 'no summary before 7am');
select set_config('request.jwt.claims', '{}', false), public.run_due_alerts(timestamptz '2026-11-07 09:00 Australia/Melbourne');
select test.ok(not exists (select 1 from public.email_outbox where template = 'overdue_summary'), 'no summary on a Saturday');

-- Only the timer can run it.
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$select set_config('request.jwt.claims', '{}', false), public.run_due_alerts()$$, 'staff cannot run the timer job');
reset role;

\o
\echo 'All due date alert tests passed.'
