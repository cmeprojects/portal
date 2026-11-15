-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 84): team leaders see only availability and start dates
-- of their own team; the emergency contact only behind the system admin's
-- switch. The person, people managers and the system admin are unchanged.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

update public.features set enabled = true where key in ('hr', 'hr_profiles');

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('lead@example.com', 'Taylor', 'team_leader'),
  ('lead2@example.com', 'Jo', 'team_leader'), ('sam@example.com', 'Sam', 'support_worker'),
  ('kim@example.com', 'Kim', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('lead@example.com'), ('lead2@example.com'), ('sam@example.com'), ('kim@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
grant execute on all functions in schema test to authenticated;
insert into public.teams (name) values ('North'), ('South');
insert into public.team_leaders select id, test.pid('lead@example.com') from public.teams where name = 'North';
insert into public.team_leaders select id, test.pid('lead2@example.com') from public.teams where name = 'South';
insert into public.team_members (team_id, user_id) select id, test.pid('sam@example.com') from public.teams where name = 'North';
insert into public.team_members (team_id, user_id) select id, test.pid('kim@example.com') from public.teams where name = 'South';
insert into public.staff_private (user_id, address, emergency_name, emergency_phone, start_date, employment_type, employee_id, availability)
values (test.pid('sam@example.com'), '1 Test St', 'Pat', '0400 111 222', '2023-03-01', 'casual', 'E-7', '{"mon": ["am"]}')
on conflict (user_id) do update set address = excluded.address, emergency_name = excluded.emergency_name, emergency_phone = excluded.emergency_phone,
  start_date = excluded.start_date, employment_type = excluded.employment_type, employee_id = excluded.employee_id, availability = excluded.availability;

-- The emergency switch is new, off by default, and part of Staff profiles.
select test.ok((select not enabled and parent = 'hr_profiles' from public.features where key = 'hr_leader_emergency'), 'the emergency contact switch starts off, under Staff profiles');

-- Team leader of Sam's team.
select test.act_as('lead@example.com');
set role authenticated;
select test.ok((select count(*) from public.staff_private where user_id = test.pid('sam@example.com')) = 0, 'a team leader can''t select the private row (address, employee ID)');
select test.ok((select count(*) from public.team_private()) = 1, 'a team leader gets one row: their team member');
select test.ok((select availability ->> 'mon' = '["am"]' and start_date = '2023-03-01' from public.team_private()), 'it has availability and the start date (work anniversaries)');
select test.ok((select emergency_name is null and emergency_phone is null from public.team_private()), 'no emergency contact while the switch is off');
reset role;

update public.features set enabled = true where key = 'hr_leader_emergency';
select test.act_as('lead@example.com');
set role authenticated;
select test.ok((select emergency_name = 'Pat' and emergency_phone = '0400 111 222' from public.team_private()), 'with the switch on, the team leader sees the emergency contact');
reset role;
update public.features set enabled = false where key = 'hr_profiles';
select test.act_as('lead@example.com');
set role authenticated;
select test.ok((select count(*) from public.team_private()) = 0, 'nothing while Staff profiles is off');
reset role;
update public.features set enabled = true where key = 'hr_profiles';
update public.features set enabled = false where key = 'hr_leader_emergency';

-- Another team's leader and a colleague see nothing of Sam.
select test.act_as('lead2@example.com');
set role authenticated;
select test.ok((select count(*) from public.team_private() where user_id = test.pid('sam@example.com')) = 0, 'another team''s leader gets nothing');
reset role;
select test.act_as('kim@example.com');
set role authenticated;
select test.ok((select count(*) from public.team_private()) = 0 and (select count(*) from public.staff_private where user_id = test.pid('sam@example.com')) = 0, 'a support worker gets nothing');
reset role;

-- Unchanged: the person, a people manager and the system admin read the whole row.
select test.act_as('sam@example.com');
set role authenticated;
select test.ok((select address from public.staff_private where user_id = test.pid('sam@example.com')) = '1 Test St', 'the person still reads their own private details');
select test.ok((select count(*) from public.team_private()) = 0, 'team_private never returns the caller''s own row');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
select test.ok((select employee_id from public.staff_private where user_id = test.pid('sam@example.com')) = 'E-7', 'a manager still reads private details');
reset role;
select test.act_as('owner@example.com');
set role authenticated;
select test.ok((select address from public.staff_private where user_id = test.pid('sam@example.com')) = '1 Test St', 'the system admin still reads private details');
reset role;

-- Signed-out callers can't run it.
set role anon;
select test.refused($$select * from public.team_private()$$, 'signed-out users can''t run team_private');
reset role;
