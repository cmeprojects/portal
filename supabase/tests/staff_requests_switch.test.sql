-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 99): Staff requests switched over to can() (Stage 3b).
-- Managers and staff admins keep seeing every request; nobody's access changes.

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
create function test.sees(p_email text, p_table text) returns bigint language plpgsql as $$
declare v bigint;
begin
  perform test.act_as(p_email);
  execute 'set local role authenticated';
  execute format('select count(*) from public.%I', p_table) into v;
  execute 'reset role';
  return v;
end $$;
grant execute on all functions in schema test to authenticated;
set session_replication_role = replica;
update public.features set enabled = true, included = true where key = 'hr_requests';
set session_replication_role = origin;
insert into public.teams (name) values ('North'), ('South');
insert into public.team_leaders (team_id, user_id) select id, test.pid('lead@example.com') from public.teams where name = 'North';
insert into public.team_members (team_id, user_id) select id, test.pid('sam@example.com') from public.teams where name = 'North';
insert into public.team_members (team_id, user_id) select id, test.pid('kim@example.com') from public.teams where name = 'South';
insert into public.leave_periods (user_id, leave_type, start_date, end_date) values (test.pid('sam@example.com'), 'Annual leave', current_date, current_date + 1), (test.pid('kim@example.com'), 'Annual leave', current_date, current_date + 1);

select test.ok((select grant_ready from public.app_modules where id = 'hr.requests'), 'Staff requests is switched over');
select test.ok((select string_agg(access_level::text, ',' order by access_level) from public.access_baselines where module_id = 'hr.requests' and revoked_at is null and by_system_admin) = 'manager,staff_admin', 'managers and staff admins by default');

-- Same as today.
select test.ok(test.sees('boss@example.com', 'leave_periods') = 2, 'manager sees everyone''s leave');
select test.ok(test.sees('ada@example.com', 'leave_periods') = 2, 'staff admin sees everyone''s leave');
select test.ok(test.sees('owner@example.com', 'leave_periods') = 2, 'system admin sees everyone''s leave');
select test.ok(test.sees('lead@example.com', 'leave_periods') = 1, 'team leader sees their team''s leave only');
select test.ok(test.sees('sam@example.com', 'leave_periods') = 1, 'staff see their own');

-- Changed on the Access page now.
select set_config('request.jwt.claims', '', false);
update public.access_baselines set revoked_at = now() where module_id = 'hr.requests' and access_level = 'staff_admin' and revoked_at is null;
select test.ok(test.sees('ada@example.com', 'leave_periods') = 0, 'taken from staff admins on the Access page: they no longer see everyone''s');
select test.ok(test.sees('boss@example.com', 'leave_periods') = 2, 'managers unaffected');
insert into public.job_titles (name, access_level) values ('Rostering Officer', 'support_worker');
update public.profiles set job_title_id = (select id from public.job_titles where name = 'Rostering Officer') where email = 'kim@example.com';
select set_config('request.jwt.claims', '', false);
insert into public.access_baselines (job_title_id, module_id, actions) values ((select id from public.job_titles where name = 'Rostering Officer'), 'hr.requests', '{view}');
select test.ok(test.sees('kim@example.com', 'leave_periods') = 2, 'a role (job title) given Staff requests sees everyone''s');
select test.ok(test.sees('sam@example.com', 'leave_periods') = 1, 'other support workers unchanged');

\i supabase/live-updates/update-99.sql
\o /dev/null
select test.ok((select count(*) from public.access_baselines where module_id = 'hr.requests' and access_level is not null and revoked_at is null) = 1, 'running it again adds nothing (one default left live)');

\o
