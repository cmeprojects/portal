-- Staff Portal · © cmeproject. All rights reserved.
--
-- Limited tasks: support workers raise General tasks and questions only.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('sam@example.com', 'Sam', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('sam@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
grant execute on all functions in schema test to authenticated;
insert into public.registries (name, kind, prefix) values ('Incidents', 'tasks', 'INC');

select test.act_as('sam@example.com');
set role authenticated;
select test.ok(public.create_task('Question about rosters', (select id from public.registries where prefix = 'GEN'), test.pid('boss@example.com')) is not null,
  'a support worker raises a General task');
select test.refused($$select public.create_task('Fall in the lounge', (select id from public.registries where prefix = 'INC'), test.pid('boss@example.com'))$$,
  'but not a task in another register');
reset role;

select test.act_as('boss@example.com');
set role authenticated;
select test.ok(public.create_task('Check the fall', (select id from public.registries where prefix = 'INC'), test.pid('sam@example.com')) is not null,
  'managers use any register, and can give support workers those tasks');
reset role;

update public.app_settings set value = '[]' where key = 'tasks.limited_roles';
select test.act_as('sam@example.com');
set role authenticated;
select test.ok(public.create_task('Fall in the lounge', (select id from public.registries where prefix = 'INC'), test.pid('boss@example.com')) is not null,
  'with nobody limited, support workers use any register again');
reset role;

\o
\echo All limited task tests passed.
