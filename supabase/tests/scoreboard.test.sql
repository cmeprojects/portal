-- Staff Portal · © cmeproject. All rights reserved.
--
-- The scoreboard: who sees it, and what it counts.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('office@example.com', 'Olive', 'staff_admin'),
  ('lead@example.com', 'Taylor', 'team_leader'), ('sam@example.com', 'Sam', 'support_worker'), ('kim@example.com', 'Kim', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('office@example.com'), ('lead@example.com'), ('sam@example.com'), ('kim@example.com');
insert into public.teams (name) values ('Team A');
insert into public.team_leaders (team_id, user_id) select t.id, p.id from public.teams t, public.profiles p where t.name = 'Team A' and p.email = 'lead@example.com';
insert into public.team_members (team_id, user_id) select t.id, p.id from public.teams t, public.profiles p where t.name = 'Team A' and p.email = 'sam@example.com';
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.row(p_email text) returns public.profiles language sql as $$ select * from public.profiles where email = p_email $$;
grant execute on all functions in schema test to authenticated;

select test.act_as('boss@example.com');
set role authenticated;
select public.create_task('Late one', (select id from public.registries where prefix = 'GEN'), test.pid('sam@example.com'), p_due_date => current_date - 2);
select public.create_task('Stuck one', (select id from public.registries where prefix = 'GEN'), test.pid('sam@example.com'), p_due_date => current_date + 5);
select public.create_task('Done late', (select id from public.registries where prefix = 'GEN'), test.pid('sam@example.com'), p_due_date => current_date - 6);
select public.create_task('Done on time', (select id from public.registries where prefix = 'GEN'), test.pid('kim@example.com'), p_due_date => current_date + 1);
reset role;
-- History can't be changed; switch the guard off just to age this test task.
alter table public.task_events disable trigger user;
update public.task_events set created_at = now() - interval '10 days' where task_id = (select id from public.tasks where title = 'Stuck one');
alter table public.task_events enable trigger user;
update public.tasks set updated_at = now() - interval '10 days' where title = 'Stuck one';
update public.tasks set status = 'completed', completed_at = now() - interval '1 day' where title in ('Done late', 'Done on time');

select test.act_as('office@example.com');
set role authenticated;
select test.ok((select overdue = 1 and open_tasks = 2 and stuck = 1 and completed = 1 and completed_on_time = 0 and avg_days_late = 5
                  from public.staff_scoreboard() where full_name = 'Sam'),
  'Sam: one overdue, one stuck, one done late');
select test.ok((select completed = 1 and completed_on_time = 1 and overdue = 0 from public.staff_scoreboard() where full_name = 'Kim'),
  'Kim: one done on time');
select test.ok(not exists (select 1 from public.staff_scoreboard() where full_name in ('Olive', 'owner@example.com')),
  'you and the system admin aren''t on the scoreboard');
reset role;

select test.act_as('lead@example.com');
set role authenticated;
select test.ok((select count(*) from public.staff_scoreboard()) = 0, 'a team leader can''t see it by default');
reset role;
update public.app_settings set value = '["staff_admin", "manager", "team_leader"]' where key = 'people.scoreboard_roles';
select test.act_as('lead@example.com');
set role authenticated;
select test.ok((select array_agg(full_name) from public.staff_scoreboard()) = array['Sam'], 'when allowed, a team leader sees only their team');
reset role;

select test.act_as('sam@example.com');
set role authenticated;
select test.ok((select count(*) from public.staff_scoreboard()) = 0, 'a support worker can''t see it');
reset role;

\o
\echo 'All scoreboard tests passed.'
