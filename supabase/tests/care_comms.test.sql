-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 111): communication preferences, section switches,
-- support coordinator assignments (Care block C1, C2).

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('office@example.com', 'Olive', 'staff_admin'),
  ('sam@example.com', 'Sam', 'support_worker'), ('kim@example.com', 'Kim', 'support_worker'),
  ('cm@example.com', 'Casey', 'support_worker'), ('io@example.com', 'Ira', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('office@example.com'), ('sam@example.com'), ('kim@example.com'), ('cm@example.com'), ('io@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.cid(p_name text) returns uuid language sql security definer as $$ select id from public.car_clients where name = p_name $$;
create function test.n(p_email text, p_sql text) returns bigint language plpgsql as $$
declare v bigint;
begin
  perform test.act_as(p_email);
  execute 'set local role authenticated';
  execute 'select ' || p_sql into v;
  execute 'reset role';
  return v;
end $$;
grant execute on all functions in schema test to authenticated;
update public.profiles set job_title_id = (select id from public.job_titles where name = 'Case Manager') where email = 'cm@example.com';
update public.profiles set job_title_id = (select id from public.job_titles where name = 'Intake & Assessment Officer') where email = 'io@example.com';
insert into public.teams (name) values ('North');
insert into public.team_members (team_id, user_id) select id, test.pid('sam@example.com') from public.teams where name = 'North';
insert into public.car_clients (name) values ('Zara North'), ('Alex South');
insert into public.client_teams (client_id, team_id) select test.cid('Zara North'), id from public.teams where name = 'North';
insert into public.client_comms (client_id, language, interpreter_needed) values (test.cid('Zara North'), 'Arabic', true), (test.cid('Alex South'), 'English', false);

select test.ok((select grant_ready from public.app_modules where id = 'clients.comms'), 'Communication preferences is a part of Clients');
select test.ok((select count(*) from public.app_settings where key like 'care.section_%') = 6, 'six section switches');

-- Who sees preferences.
select test.ok(test.n('boss@example.com', '(select count(*) from public.client_comms)') = 2, 'manager: every client');
select test.ok(test.n('office@example.com', '(select count(*) from public.client_comms)') = 0, 'staff admin: none (D-052)');
select test.ok(test.n('io@example.com', '(select count(*) from public.client_comms)') = 2, 'intake: every client');
select test.ok(test.n('sam@example.com', '(select count(*) from public.client_comms)') = 1, 'team staff: their team''s client (switch on)');
select test.ok(test.n('kim@example.com', '(select count(*) from public.client_comms)') = 0, 'other staff: none');
select test.ok(test.n('cm@example.com', '(select count(*) from public.client_comms)') = 0, 'case manager with no assignment: none');
update public.app_settings set value = 'false' where key = 'care.team_sees_comms';
select test.ok(test.n('sam@example.com', '(select count(*) from public.client_comms)') = 0, 'switch off: team staff see none');
update public.app_settings set value = 'true' where key = 'care.team_sees_comms';

-- Intake adds a client and assigns a support coordinator.
select test.act_as('io@example.com');
set role authenticated;
insert into public.client_assignments (client_id, user_id, assigned_as) values (test.cid('Alex South'), test.pid('cm@example.com'), 'support_coordinator');
reset role;
select test.ok(test.n('cm@example.com', '(select count(*) from public.client_comms)') = 1, 'assigned as support coordinator: the case manager sees that client''s preferences');
select test.act_as('cm@example.com');
set role authenticated;
update public.client_comms set language = 'English (and Auslan)' where client_id = test.cid('Alex South');
select test.refused($$update public.client_comms set language = 'x' where client_id = test.cid('Zara North')$$, 'but can''t change another client''s');
reset role;
select test.ok((select language from public.client_comms where client_id = test.cid('Alex South')) = 'English (and Auslan)', 'and changes their assigned client''s');
select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$update public.client_comms set language = 'x'$$, 'team staff can''t change preferences');
select test.refused($$delete from public.client_comms$$, 'nobody deletes them');
reset role;

\o
