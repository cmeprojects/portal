-- Staff Portal · © cmeproject. All rights reserved.
--
-- HR Pack switches and staff profiles (cmeprojects).

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

update public.features set enabled = true where key = 'hr_profiles';

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('office@example.com', 'Olive', 'staff_admin'), ('lead@example.com', 'Taylor', 'team_leader'), ('sam@example.com', 'Sam', 'support_worker'), ('kim@example.com', 'Kim', 'support_worker');
insert into auth.users (email) values ('office@example.com'), ('lead@example.com'), ('sam@example.com'), ('kim@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
grant execute on all functions in schema test to authenticated;
insert into public.teams (name) values ('North');
insert into public.team_leaders select id, test.pid('lead@example.com') from public.teams where name = 'North';
insert into public.team_members (team_id, user_id) select id, test.pid('sam@example.com') from public.teams where name = 'North';

-- Switches: the HR Pack turns its parts (and Compliance) off with it.
select test.ok(public.feature_live('hr_req_leave'), 'leave requests are on by default');
update public.features set enabled = false where key = 'hr';
select test.ok(not public.feature_live('hr_profiles') and not public.feature_live('hr_req_leave') and not public.feature_live('compliance') and not public.feature_live('compliance_read'), 'HR Pack off switches every HR part off, three levels down');
update public.features set enabled = true where key = 'hr';
update public.features set enabled = false where key = 'hr_requests';
select test.ok(not public.feature_live('hr_req_leave') and public.feature_live('hr_profiles'), 'switching My requests off leaves profiles on');
update public.features set enabled = true where key = 'hr_requests';
update public.features set enabled = false where key = 'hr_req_swap';
select test.ok(not public.feature_live('hr_req_swap') and public.feature_live('hr_req_leave'), 'each request type has its own switch');
update public.features set enabled = true where key = 'hr_req_swap';

-- Profiles
select test.act_as('sam@example.com');
set role authenticated;
select public.save_profile(test.pid('sam@example.com'), '{"preferred_name": "Sammy", "work_phone": "0400 000 000", "skills": ["First Aid", "Driver''s licence", " "], "address": "1 Test St", "availability": {"mon": ["am"]}}');
select test.refused($$select public.save_profile(test.pid('sam@example.com'), '{"department": "Executive"}')$$, 'staff can''t change their own department');
select test.refused($$select public.save_profile(test.pid('kim@example.com'), '{"preferred_name": "Bob"}')$$, 'staff can''t change someone else''s profile');
select test.refused($$update public.staff_directory set preferred_name = 'x'$$, 'nobody edits profiles directly');
reset role;
select test.ok((select preferred_name || '|' || array_length(skills, 1) from public.staff_directory where user_id = test.pid('sam@example.com')) = 'Sammy|2', 'a person saves their own card (blank skills dropped)');

select test.act_as('kim@example.com');
set role authenticated;
select test.ok((select preferred_name from public.staff_directory where user_id = test.pid('sam@example.com')) = 'Sammy', 'colleagues see the directory card');
select test.ok((select count(*) from public.staff_private where user_id = test.pid('sam@example.com')) = 0, 'colleagues can''t see private details');
reset role;

select test.act_as('lead@example.com');
set role authenticated;
select test.ok((select count(*) from public.staff_private where user_id = test.pid('sam@example.com')) = 1, 'a team leader sees their team member''s availability');
reset role;

select test.act_as('office@example.com');
set role authenticated;
select public.save_profile(test.pid('sam@example.com'), '{"department": "Community", "employment_type": "casual", "start_date": "2026-01-05", "employee_id": "E42"}');
select test.ok((select address from public.staff_private where user_id = test.pid('sam@example.com')) = '1 Test St', 'a staff admin sees private details');
reset role;
select test.ok((select department from public.staff_directory where user_id = test.pid('sam@example.com')) = 'Community'
  and (select employment_type from public.staff_private where user_id = test.pid('sam@example.com')) = 'casual', 'a staff admin sets employment details');

update public.features set enabled = false where key = 'hr_profiles';
select test.act_as('kim@example.com');
set role authenticated;
select test.ok((select count(*) from public.staff_directory) = 0, 'with profiles switched off, the directory is hidden');
reset role;

\o
\echo All HR profile tests passed.
