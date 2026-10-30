-- Staff Portal · © cmeproject. All rights reserved.
--
-- General invites: people join as new starters with no role or team. A staff
-- admin gives the first role straight away; new starters can't use tasks.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('office@example.com', 'Olive', 'staff_admin');
insert into auth.users (email) values ('boss@example.com'), ('office@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
grant execute on all functions in schema test to authenticated;

-- A staff admin sends a general invite (no role, no team).
select test.act_as('office@example.com');
set role authenticated;
insert into public.invitations (email, full_name) values ('new@example.com', 'Nico'), ('new2@example.com', 'Nell');
reset role;
insert into auth.users (email) values ('new@example.com'), ('new2@example.com');
select test.ok((select role = 'new_starter' and active from public.profiles where email = 'new@example.com'),
  'a general invite makes an active new starter');
select test.ok(not exists (select 1 from public.team_members where user_id = test.pid('new@example.com')), 'a new starter is in no team');

-- New starters can't use tasks.
select test.act_as('new@example.com');
set role authenticated;
select test.refused($$select public.create_task('x', (select id from public.registries where prefix = 'GEN'), test.pid('boss@example.com'))$$,
  'a new starter cannot create tasks');
select test.ok((select count(*) from public.tasks) = 0, 'a new starter sees no tasks');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$select public.create_task('x', (select id from public.registries where prefix = 'GEN'), test.pid('new@example.com'))$$,
  'a new starter cannot be given a task');
reset role;

-- First role: with the rule off, a staff admin sets it straight away.
update public.app_settings set value = 'false' where key = 'people.first_role_approval';
select test.act_as('office@example.com');
set role authenticated;
update public.profiles set role = 'support_worker' where email = 'new@example.com';
reset role;
select test.ok((select role = 'support_worker' from public.profiles where email = 'new@example.com'),
  'a staff admin gives a new starter their first role straight away');
select test.act_as('office@example.com');
set role authenticated;
select test.refused($$update public.profiles set role = 'team_leader' where email = 'new@example.com'$$,
  'later role changes by a staff admin still need a manager');
select test.refused($$update public.profiles set role = 'system_admin' where email = 'new2@example.com'$$,
  'a staff admin cannot make a new starter a system admin');
reset role;

-- Roles (job titles) can't be "new starter".
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$insert into public.job_titles (name, access_level) values ('Trainee', 'new_starter')$$,
  'a role cannot have new starter access');
reset role;

-- The system admin switches the rules.
update public.app_settings set value = 'true' where key = 'people.first_role_approval';
select test.act_as('office@example.com');
set role authenticated;
select test.refused($$update public.profiles set role = 'support_worker' where email = 'new2@example.com'$$,
  'with "first role needs approval" on, a staff admin must ask');
reset role;
update public.app_settings set value = 'false' where key = 'people.staff_admin_role_approval';
select test.act_as('office@example.com');
set role authenticated;
update public.profiles set role = 'team_leader' where email = 'new@example.com';
reset role;
select test.ok((select role = 'team_leader' from public.profiles where email = 'new@example.com'),
  'with role approval off, a staff admin changes roles straight away');
update public.app_settings set value = 'true' where key = 'people.general_invites_only';
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$insert into public.invitations (email, role) values ('w@example.com', 'support_worker')$$,
  'with general invites only, a manager cannot invite into a role');
insert into public.invitations (email) values ('w@example.com');
reset role;
update public.app_settings set value = 'true' where key = 'people.new_starter_tasks';
select test.act_as('boss@example.com');
set role authenticated;
select public.create_task('For Nell', (select id from public.registries where prefix = 'GEN'), test.pid('new2@example.com'));
reset role;
select test.ok((select count(*) from public.tasks where title = 'For Nell') = 1, 'with the switch on, a new starter can be given tasks');
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$update public.app_settings set value = 'false' where key = 'people.new_starter_tasks'$$,
  'only the system admin changes the people rules');
reset role;

\o
\echo 'All new starter tests passed.'
