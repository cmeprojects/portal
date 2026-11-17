-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 95): Onboarding switched over to can() (Stage 3b,
-- D-049). Today's rules become access-level defaults; nobody's access changes.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('lead@example.com', 'Taylor', 'team_leader'),
  ('sam@example.com', 'Sam', 'support_worker'), ('kim@example.com', 'Kim', 'support_worker'),
  ('ada@example.com', 'Ada', 'staff_admin'), ('newbie@example.com', 'Nina', 'new_starter'),
  ('ext@example.com', 'Eli', 'external');
insert into auth.users (email) values ('boss@example.com'), ('lead@example.com'), ('sam@example.com'), ('kim@example.com'), ('ada@example.com'), ('newbie@example.com'), ('ext@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.as_check(p_email text, p_sql text) returns boolean language plpgsql as $$
declare v boolean;
begin
  perform test.act_as(p_email);
  execute 'set local role authenticated';
  execute 'select ' || p_sql into v;
  execute 'reset role';
  return v;
end $$;
grant execute on all functions in schema test to authenticated;
insert into public.teams (name) values ('North'), ('South');
insert into public.team_members (team_id, user_id) select id, test.pid('sam@example.com') from public.teams where name = 'North';
insert into public.team_leaders (team_id, user_id) select id, test.pid('lead@example.com') from public.teams where name = 'North';
insert into public.team_members (team_id, user_id) select id, test.pid('kim@example.com') from public.teams where name = 'South';

-- Switched over, with defaults (fresh install: staff admins manage).
select test.ok((select bool_and(grant_ready) from public.app_modules where id like 'hr.onboarding%'), 'Onboarding is switched over');
select test.ok((select count(*) from public.access_baselines where module_id = 'hr.onboarding' and revoked_at is null and by_system_admin) = 3, 'three defaults, counted as the system admin''s');

-- Same as today, role by role.
select test.ok(test.as_check('owner@example.com', 'public.can_manage_compliance()'), 'system admin manages onboarding');
select test.ok(test.as_check('ada@example.com', 'public.can_manage_compliance()'), 'staff admin manages onboarding (the setting)');
select test.ok(not test.as_check('boss@example.com', 'public.can_manage_compliance()'), 'manager doesn''t manage it while there''s a staff admin');
select test.ok(test.as_check('boss@example.com', $$public.can('hr.onboarding', 'view')$$), 'manager sees progress');
select test.ok(test.as_check('boss@example.com', $$public.can('hr.onboarding.expiry', 'view')$$), 'manager sees the expiry list');
select test.ok(not test.as_check('lead@example.com', 'public.can_manage_compliance()'), 'team leader doesn''t manage it');
select test.ok(test.as_check('lead@example.com', $$public.can('hr.onboarding', 'view')$$), 'team leader sees progress');
select test.ok(test.as_check('lead@example.com', $$public.can('hr.onboarding', 'view', test.pid('sam@example.com'))$$), 'team leader: someone in their team');
select test.ok(not test.as_check('lead@example.com', $$public.can('hr.onboarding', 'view', test.pid('kim@example.com'))$$), 'team leader: not someone in another team');
select test.ok(not test.as_check('sam@example.com', $$public.can('hr.onboarding', 'view')$$), 'support worker: nothing');
select test.ok(not test.as_check('newbie@example.com', $$public.can('hr.onboarding', 'view')$$), 'new starter: nothing');
select test.ok(not test.as_check('ext@example.com', $$public.can('hr.onboarding', 'view')$$), 'external: nothing');
select test.ok(test.as_check('ada@example.com', $$public.can_manage_compliance()$$) and not test.as_check('ada@example.com', $$public.can('hr.contracts', 'view')$$), 'the default covers Onboarding only');
select test.ok((select array_agg(x order by x) from public.people_admins() x) = array[test.pid('ada@example.com')], 'notices go to the staff admin, as before');

-- Two-step sign-in still applies.
select test.act_as('ada@example.com', 'aal1');
update public.features set enabled = true where key = 'two_factor';
update public.app_settings set value = '["staff_admin"]' where key = 'security.mfa_required_roles';
select test.ok(not public.can_manage_compliance(), 'without the second step when it''s required: no');
update public.app_settings set value = '[]' where key = 'security.mfa_required_roles';
update public.features set enabled = false where key = 'two_factor';

-- The database rules follow the new check (a policy that used the old rule).
select test.act_as('ada@example.com');
set role authenticated;
insert into public.compliance_items (kind, title) values ('upload', 'Police check');
reset role;
select test.ok((select count(*) from public.compliance_items where title = 'Police check') = 1, 'staff admin adds an onboarding item');
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$insert into public.compliance_items (kind, title) values ('upload', 'First aid')$$, 'manager can''t (as today, with a staff admin)');
reset role;

-- Changed on the Access page now.
select test.act_as('owner@example.com');
set role authenticated;
update public.access_baselines set revoked_at = now() where access_level = 'manager' and module_id = 'hr.onboarding' and revoked_at is null;
insert into public.access_baselines (access_level, module_id) values ('manager', 'hr.onboarding');
reset role;
select test.ok(test.as_check('boss@example.com', 'public.can_manage_compliance()'), 'the system admin gives managers onboarding on the Access page');
select test.ok(test.pid('boss@example.com') = any (array(select public.people_admins())), 'and managers then get the notices');
select test.ok(not test.as_check('lead@example.com', 'public.can_manage_compliance()'), 'team leaders unaffected');

-- A person's own setting still comes first.
insert into public.admin_designations (user_id, granted_by) values (test.pid('boss@example.com'), test.pid('owner@example.com'));
insert into public.access_grants (module_id, user_id, granted_by, effect) values ('hr.onboarding', test.pid('boss@example.com'), test.pid('owner@example.com'), 'restrict');
select test.ok(not test.as_check('boss@example.com', 'public.can_manage_compliance()'), 'a person''s block beats the access-level default');

-- Roles and function groups work here now.
insert into public.job_titles (name, access_level) values ('Onboarding Officer', 'support_worker');
update public.profiles set job_title_id = (select id from public.job_titles where name = 'Onboarding Officer') where email = 'kim@example.com';
select test.act_as('owner@example.com');
set role authenticated;
insert into public.access_baselines (job_title_id, module_id, actions) values ((select id from public.job_titles where name = 'Onboarding Officer'), 'hr.onboarding', '{view,approve}');
reset role;
select test.ok(test.as_check('kim@example.com', 'public.can_manage_compliance()'), 'a role (job title) given onboarding manages it');

-- The old setting no longer decides.
update public.app_settings set value = '["support_worker"]' where key = 'compliance.manager_roles';
select test.ok(not test.as_check('sam@example.com', 'public.can_manage_compliance()'), 'the old System setting no longer gives access');

-- Running the update on an existing copy: copies the setting once, with the
-- old fallback (no staff admin) settled then.
select test.act_as('owner@example.com');
update public.access_baselines set revoked_at = now() where access_level is not null and revoked_at is null;
update public.profiles set role = 'manager' where email = 'ada@example.com';
update public.app_settings set value = '["team_leader"]' where key = 'compliance.manager_roles';
\i supabase/live-updates/update-95.sql
\o /dev/null
select test.ok(test.as_check('lead@example.com', 'public.can_manage_compliance()'), 'on an existing copy: the roles in the setting manage it');
select test.ok((select count(*) from public.access_baselines where access_level = 'manager' and actions = '{}' and revoked_at is null) = 1, 'no staff admin when it ran: managers get it (the old fallback)');
\i supabase/live-updates/update-95.sql
\o /dev/null
select test.ok((select count(*) from public.access_baselines where access_level is not null and revoked_at is null) = 2, 'running it again adds nothing');

\o
