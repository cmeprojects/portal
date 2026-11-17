-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 101): Staff switched over to can() (Stage 3b).
-- Managers and staff admins keep managing staff; nobody's access changes.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('lead@example.com', 'Taylor', 'team_leader'),
  ('sam@example.com', 'Sam', 'support_worker'), ('kim@example.com', 'Kim', 'support_worker'),
  ('ada@example.com', 'Ada', 'staff_admin');
insert into auth.users (email) values ('boss@example.com'), ('lead@example.com'), ('sam@example.com'), ('kim@example.com'), ('ada@example.com');
insert into public.invitations (email, full_name, role) values ('pending@example.com', 'Pat', 'new_starter');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
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
insert into public.teams (name) values ('North');
insert into public.team_leaders (team_id, user_id) select id, test.pid('lead@example.com') from public.teams where name = 'North';
insert into public.team_members (team_id, user_id) select id, test.pid('sam@example.com') from public.teams where name = 'North';

select test.ok((select grant_ready from public.app_modules where id = 'people.staff'), 'Staff is switched over');
select test.ok((select string_agg(access_level::text, ',' order by access_level) from public.access_baselines where module_id = 'people.staff' and revoked_at is null and by_system_admin) = 'manager,staff_admin', 'managers and staff admins by default');

-- Same as today.
select test.ok(test.n('boss@example.com', '(select count(*) from public.invitations where accepted_at is null)') = 1, 'manager sees pending invitations');
select test.ok(test.n('ada@example.com', '(select count(*) from public.invitations where accepted_at is null)') = 1, 'staff admin sees pending invitations');
select test.ok(test.n('lead@example.com', '(select count(*) from public.invitations where accepted_at is null)') = 0, 'team leader doesn''t');
select test.ok(test.n('sam@example.com', '(select count(*) from public.invitations)') = 0, 'support worker doesn''t');
select test.act_as('boss@example.com');
set role authenticated;
update public.profiles set active = false where email = 'sam@example.com';
reset role;
select test.ok((select not active from public.profiles where email = 'sam@example.com'), 'manager deactivates someone (staff management)');
select test.act_as('boss@example.com');
set role authenticated;
update public.profiles set active = true where email = 'sam@example.com';
reset role;
select test.act_as('kim@example.com');
set role authenticated;
select test.refused($$update public.profiles set active = false where email = 'sam@example.com'$$, 'support worker can''t');
reset role;

-- Onboarding progress (finishing update 95).
select test.ok(test.n('boss@example.com', $$(select (public.work_status(test.pid('sam@example.com')) is not null)::int)$$) = 1, 'manager sees anyone''s onboarding status');
select test.ok(test.n('lead@example.com', $$(select (public.work_status(test.pid('sam@example.com')) is not null)::int)$$) = 1, 'team leader sees their team member''s');
select test.ok(test.n('lead@example.com', $$(select (public.work_status(test.pid('kim@example.com')) is not null)::int)$$) = 0, 'not someone outside their team');
select test.ok(test.n('kim@example.com', $$(select (public.work_status(test.pid('sam@example.com')) is not null)::int)$$) = 0, 'support worker doesn''t');

-- Changed on the Access page now.
insert into public.job_titles (name, access_level) values ('HR Officer', 'support_worker');
update public.profiles set job_title_id = (select id from public.job_titles where name = 'HR Officer') where email = 'kim@example.com';
select set_config('request.jwt.claims', '', false);
insert into public.access_baselines (job_title_id, module_id, actions) values ((select id from public.job_titles where name = 'HR Officer'), 'people.staff', '{view}');
select test.ok(test.n('kim@example.com', '(select count(*) from public.invitations where accepted_at is null)') = 1, 'a role (job title) given Staff (view) sees invitations');
select test.act_as('kim@example.com');
set role authenticated;
select test.refused($$update public.profiles set active = false where email = 'sam@example.com'$$, 'but can''t change people with view only');
reset role;
select set_config('request.jwt.claims', '', false);
update public.access_baselines set revoked_at = now() where module_id = 'people.staff' and access_level = 'staff_admin' and revoked_at is null;
select test.ok(test.n('ada@example.com', '(select count(*) from public.invitations where accepted_at is null)') = 0, 'taken from staff admins on the Access page: they no longer see invitations');

\i supabase/live-updates/update-101.sql
\o /dev/null
select test.ok((select count(*) from public.access_baselines where module_id = 'people.staff' and access_level is not null and revoked_at is null) = 1, 'running it again adds nothing');

\o
