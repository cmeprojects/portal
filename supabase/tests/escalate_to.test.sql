-- Staff Portal · © cmeproject. All rights reserved.
--
-- Escalating to the right person: support workers choose their team leader or
-- a manager; team leaders and staff admins go straight to a manager; taking it
-- over or reassigning deals with the escalation.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('lead@example.com', 'Taylor', 'team_leader'),
  ('sam@example.com', 'Sam', 'support_worker'), ('lee@example.com', 'Lee', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('lead@example.com'), ('sam@example.com'), ('lee@example.com');
insert into public.teams (name) values ('Team A');
insert into public.team_leaders (team_id, user_id) select t.id, p.id from public.teams t, public.profiles p where t.name = 'Team A' and p.email = 'lead@example.com';
insert into public.team_members (team_id, user_id) select t.id, p.id from public.teams t, public.profiles p where t.name = 'Team A' and p.email in ('sam@example.com', 'lee@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.task(p_title text) returns public.tasks language sql security definer as $$ select * from public.tasks where title = p_title $$;
create function test.notes(p_email text) returns bigint language sql security definer as $$
  select count(*) from public.notifications where user_id = test.pid(p_email) and kind = 'task_escalated' $$;
grant execute on all functions in schema test to authenticated;

select test.act_as('boss@example.com');
set role authenticated;
select public.create_task('Broken hoist', (select id from public.registries where prefix = 'GEN'), test.pid('sam@example.com'));
select public.create_task('Roster gap', (select id from public.registries where prefix = 'GEN'), test.pid('lead@example.com'));
select public.create_task('Family complaint', (select id from public.registries where prefix = 'GEN'), test.pid('sam@example.com'));
reset role;

-- Sam escalates to the team leader.
select test.act_as('sam@example.com');
set role authenticated;
select test.ok(public.escalate_task((test.task('Broken hoist')).id, 'Needs two people', 'team_leader') = 'team_leader', 'a support worker can send it to their team leader');
reset role;
select test.ok((select status = 'escalated' and escalated_to = 'team_leader' and escalated_by = test.pid('sam@example.com') from test.task('Broken hoist')),
  'it''s escalated to the team leader, by Sam');
select test.ok(test.notes('lead@example.com') = 1 and test.notes('boss@example.com') = 0, 'the team leader is told, not the managers');

-- A team leader escalates: always to a manager.
select test.act_as('lead@example.com');
set role authenticated;
select test.ok(public.escalate_task((test.task('Roster gap')).id, 'No one free', 'team_leader') = 'manager', 'a team leader''s escalation goes to a manager');
reset role;
select test.ok(test.notes('boss@example.com') = 1, 'and the manager is told');

-- The team leader takes Sam's escalated task over: the escalation is dealt with.
select test.act_as('lead@example.com');
set role authenticated;
select public.take_over_task((test.task('Broken hoist')).id, 'I''ll sort it');
reset role;
select test.ok((select assigned_to = test.pid('lead@example.com') and status = 'assigned' and escalated_to is null from test.task('Broken hoist')),
  'taking it over deals with the escalation');

-- Sam sends one to a manager; the manager reassigns it to Lee.
select test.act_as('sam@example.com');
set role authenticated;
select public.escalate_task((test.task('Family complaint')).id, 'Family upset', 'manager');
reset role;
select test.ok((select escalated_to = 'manager' from test.task('Family complaint')), 'a support worker can choose a manager');
select test.act_as('boss@example.com');
set role authenticated;
select public.reassign_task((test.task('Family complaint')).id, test.pid('lee@example.com'), 'Lee knows the family');
reset role;
select test.ok((select assigned_to = test.pid('lee@example.com') and status = 'assigned' and escalated_to is null from test.task('Family complaint')),
  'reassigning deals with it too');

-- Escalated by the overnight check: managers look at it.
update public.tasks set status = 'escalated', escalated = true where title = 'Family complaint';
select test.ok((select escalated_to = 'manager' from test.task('Family complaint')), 'an automatic escalation goes to managers');

\o
\echo All escalate-to tests passed.
