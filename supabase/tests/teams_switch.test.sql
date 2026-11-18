-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 100): Teams switched over to can() (Stage 3b).
-- Managers and staff admins keep managing teams; nobody's access changes.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('lead@example.com', 'Taylor', 'team_leader'),
  ('sam@example.com', 'Sam', 'support_worker'), ('kim@example.com', 'Kim', 'support_worker'),
  ('ada@example.com', 'Ada', 'staff_admin');
insert into auth.users (email) values ('boss@example.com'), ('lead@example.com'), ('sam@example.com'), ('kim@example.com'), ('ada@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.tid(p_name text) returns uuid language sql security definer as $$ select id from public.teams where name = p_name $$;
grant execute on all functions in schema test to authenticated;
insert into public.teams (name) values ('North');

select test.ok((select grant_ready from public.app_modules where id = 'people.teams'), 'Teams is switched over');
select test.ok((select string_agg(access_level::text, ',' order by access_level) from public.access_baselines where module_id = 'people.teams' and revoked_at is null and by_system_admin) = 'manager,staff_admin', 'managers and staff admins by default');

-- Same as today.
select test.act_as('boss@example.com');
set role authenticated;
insert into public.teams (name) values ('South');
select public.set_team(test.tid('North'), array[test.pid('sam@example.com')], test.pid('lead@example.com'));
reset role;
select test.ok(test.tid('South') is not null, 'manager adds a team');
select test.ok((select count(*) from public.team_members where team_id = test.tid('North')) = 2, 'manager sets who''s in a team');
select test.act_as('ada@example.com');
set role authenticated;
update public.teams set name = 'South side' where name = 'South';
select test.refused($$select public.set_team(test.tid('North'), array[test.pid('kim@example.com')], null)$$, 'staff admin sends membership changes for approval (rule on)');
select test.refused($$insert into public.team_members (team_id, user_id) values (test.tid('North'), test.pid('kim@example.com'))$$, 'staff admin doesn''t write team members directly');
reset role;
select test.ok(test.tid('South side') is not null, 'staff admin renames a team');
select test.act_as('lead@example.com');
set role authenticated;
select test.refused($$insert into public.teams (name) values ('East')$$, 'team leader can''t add teams');
select test.refused($$select public.set_team(test.tid('North'), array[test.pid('kim@example.com')], null)$$, 'or change who''s in one');
reset role;
select test.act_as('sam@example.com');
set role authenticated;
select test.ok((select count(*) from public.teams) >= 2, 'everyone reads teams');
select test.refused($$update public.teams set name = 'X' where name = 'North'$$, 'support worker can''t change teams');
reset role;

-- Changed on the Access page now.
insert into public.job_titles (name, access_level) values ('Roster Clerk', 'support_worker');
update public.profiles set job_title_id = (select id from public.job_titles where name = 'Roster Clerk') where email = 'kim@example.com';
select set_config('request.jwt.claims', '', false);
insert into public.access_baselines (job_title_id, module_id) values ((select id from public.job_titles where name = 'Roster Clerk'), 'people.teams');
select test.act_as('kim@example.com');
set role authenticated;
insert into public.teams (name) values ('West');
select public.set_team(test.tid('West'), array[test.pid('sam@example.com')], null);
reset role;
select test.ok((select count(*) from public.team_members where team_id = test.tid('West')) = 1, 'a role (job title) given Teams manages teams');
select set_config('request.jwt.claims', '', false);
update public.access_baselines set revoked_at = now() where module_id = 'people.teams' and access_level = 'manager' and revoked_at is null;
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$insert into public.teams (name) values ('East')$$, 'taken from managers on the Access page: they can''t');
reset role;

\i supabase/live-updates/update-100.sql
\o /dev/null
select test.ok((select count(*) from public.access_baselines where module_id = 'people.teams' and access_level is not null and revoked_at is null) = 1, 'running it again adds nothing');

\o
