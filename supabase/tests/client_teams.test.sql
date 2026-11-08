-- Staff Portal · © cmeproject. All rights reserved.
--
-- Clients, teams and tasks (cmeprojects).

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('boss@example.com', 'Morgan', 'manager'), ('lead@example.com', 'Taylor', 'team_leader'), ('sam@example.com', 'Sam', 'support_worker'), ('kim@example.com', 'Kim', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('lead@example.com'), ('sam@example.com'), ('kim@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.client(p_name text) returns uuid language sql security definer as $$ select id from public.car_clients where name = p_name $$;
create function test.team(p_name text) returns uuid language sql security definer as $$ select id from public.teams where name = p_name $$;
grant execute on all functions in schema test to authenticated;

insert into public.teams (name) values ('North'), ('South');
insert into public.team_leaders (team_id, user_id) values (test.team('North'), test.pid('lead@example.com'));
insert into public.team_members (team_id, user_id) values (test.team('North'), test.pid('sam@example.com'));
insert into public.car_clients (name) values ('Alex Client'), ('Bea Client');

select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$insert into public.client_teams values (test.client('Alex Client'), test.team('North'))$$, 'a support worker can''t link clients to teams');
select test.ok((select count(*) from public.clients_to_pick()) = 2, 'staff can pick from client names');
reset role;

select test.act_as('boss@example.com');
set role authenticated;
insert into public.client_teams values (test.client('Alex Client'), test.team('North')), (test.client('Bea Client'), test.team('South'));
select public.create_task('Review Alex''s plan', (select id from public.registries where is_default), test.pid('sam@example.com'));
reset role;
select test.ok((select count(*) from public.client_teams) = 2, 'a manager links clients to teams');

select test.act_as('sam@example.com');
set role authenticated;
select public.set_task_client((select id from public.tasks where title = 'Review Alex''s plan'), test.client('Alex Client'));
select test.ok(public.task_client((select id from public.tasks where title = 'Review Alex''s plan')) = 'Alex Client', 'the person on the task sets its client');
reset role;

select test.act_as('kim@example.com');
set role authenticated;
select test.refused($$select public.set_task_client((select id from public.tasks limit 1), null)$$, 'someone not on the task can''t change its client');
reset role;

select test.act_as('lead@example.com');
set role authenticated;
select test.ok((select count(*) from public.my_team_clients()) = 1, 'a team leader sees only their team''s clients');
select test.ok((select open_tasks from public.my_team_clients()) = 1, 'with their open tasks');
reset role;

\o
\echo All client and team tests passed.
