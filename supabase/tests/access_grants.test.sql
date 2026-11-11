-- Staff Portal · © cmeproject. All rights reserved.
--
-- Phase 2 (cmeprojects): access grants (scope, expiry, pass on, revoke and
-- cascade), names read-only for staff, staff details need a grant, and
-- settings save live for everyone but the system admin.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

update public.features set enabled = true where key = 'hr_profiles';

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('boss2@example.com', 'Max', 'manager'),
  ('office@example.com', 'Olive', 'staff_admin'), ('office2@example.com', 'Oscar', 'staff_admin'),
  ('lead@example.com', 'Taylor', 'team_leader'), ('sam@example.com', 'Sam', 'support_worker'), ('kim@example.com', 'Kim', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('boss2@example.com'), ('office@example.com'), ('office2@example.com'), ('lead@example.com'), ('sam@example.com'), ('kim@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
grant execute on all functions in schema test to authenticated;
insert into public.teams (name) values ('North'), ('South');
insert into public.team_members (team_id, user_id) select id, test.pid('sam@example.com') from public.teams where name = 'North';
insert into public.team_members (team_id, user_id) select id, test.pid('kim@example.com') from public.teams where name = 'South';
create function test.team(p_name text) returns uuid language sql security definer as $$ select id from public.teams where name = p_name $$;
grant execute on all functions in schema test to authenticated;

-- People added after the migration's rollout get nothing automatically.
select test.ok((select count(*) from public.access_grants) = 0, 'no grants for people who joined after the rollout');

-- ---------------------------------------------------------------------------
-- Names
-- ---------------------------------------------------------------------------
select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$update public.profiles set full_name = 'Samuel' where id = test.pid('sam@example.com')$$, 'staff can''t change their own name');
reset role;
select set_config('request.jwt.claims', '', false);
update public.profiles set full_name = '' where id = test.pid('kim@example.com');
select test.act_as('kim@example.com');
set role authenticated;
update public.profiles set full_name = 'Kim Lee' where id = test.pid('kim@example.com');
reset role;
select test.ok((select full_name from public.profiles where id = test.pid('kim@example.com')) = 'Kim Lee', 'a blank name can be set once at account set-up');

select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$update public.profiles set full_name = 'Sammy' where id = test.pid('sam@example.com')$$, 'a manager without a Staff details grant can''t rename staff');
select test.refused($$select public.save_profile(test.pid('sam@example.com'), '{"preferred_name": "S"}')$$, 'or change their details');
select test.ok(not public.has_access('staff_details', test.pid('sam@example.com')), 'has_access is false without a grant');
reset role;

-- ---------------------------------------------------------------------------
-- Grants by the system admin
-- ---------------------------------------------------------------------------
select test.act_as('owner@example.com');
set role authenticated;
insert into public.access_grants (area, user_id, scope, can_pass_on, granted_by)
values ('staff_details', test.pid('boss@example.com'), 'all', true, test.pid('owner@example.com'));
insert into public.access_grants (area, user_id, scope, scope_ids, can_pass_on, can_reveal_tfn, granted_by)
values ('payroll_tax', test.pid('boss@example.com'), 'teams', array[test.team('North')], true, true, test.pid('owner@example.com'));
select test.refused($$insert into public.access_grants (area, user_id, granted_by) values ('payroll_tax', test.pid('office@example.com'), test.pid('owner@example.com'))$$,
  'sensitive areas go to managers first, never straight to a staff admin');
select test.refused($$insert into public.access_grants (area, user_id, granted_by) values ('staff_details', test.pid('sam@example.com'), test.pid('owner@example.com'))$$,
  'support workers can''t be given access');
select test.refused($$insert into public.access_grants (area, user_id, granted_by, can_reveal_tfn) values ('staff_details', test.pid('boss2@example.com'), test.pid('owner@example.com'), true)$$,
  'TFN reveal only belongs to Payroll and tax');
select test.refused($$insert into public.access_grants (area, user_id, granted_by) values ('staff_details', test.pid('boss@example.com'), test.pid('owner@example.com'))$$,
  'one live grant per person and area');
select test.refused($$insert into public.access_grants (area, user_id, granted_by) values ('staff_details', test.pid('boss2@example.com'), test.pid('boss@example.com'))$$,
  'a grant must be recorded as given by the person giving it');
reset role;

select test.act_as('boss@example.com');
set role authenticated;
select test.ok(public.has_access('staff_details', test.pid('sam@example.com')), 'a granted manager has access');
select test.ok(public.has_access('payroll_tax', test.pid('sam@example.com')) and not public.has_access('payroll_tax', test.pid('kim@example.com')),
  'team scope covers people in that team only');
update public.profiles set full_name = 'Sam Worker' where id = test.pid('sam@example.com');
select public.save_profile(test.pid('sam@example.com'), '{"department": "Care"}');
select test.refused($$insert into public.access_grants (area, user_id, granted_by) values ('identity_docs', test.pid('boss@example.com'), test.pid('boss@example.com'))$$,
  'nobody grants themselves access');
select test.refused($$update public.access_grants set can_pass_on = true where user_id = test.pid('boss@example.com')$$,
  'a manager can''t widen or change their own grant');
reset role;
select test.ok((select full_name from public.profiles where id = test.pid('sam@example.com')) = 'Sam Worker', 'a granted manager renames staff');
select test.ok(exists (select 1 from public.audit_log where action = 'name_changed' and entity_id = test.pid('sam@example.com')::text), 'name changes go in the change log');
select test.ok((select department from public.staff_directory where user_id = test.pid('sam@example.com')) = 'Care', 'and changes employment details');

-- ---------------------------------------------------------------------------
-- Passing on
-- ---------------------------------------------------------------------------
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$insert into public.access_grants (area, user_id, scope, scope_ids, granted_by, parent_id)
  select 'payroll_tax', test.pid('office@example.com'), 'teams', array[test.team('South')], test.pid('boss@example.com'), id from public.access_grants where area = 'payroll_tax' and user_id = test.pid('boss@example.com')$$,
  'passing on can''t widen the scope (other team)');
select test.refused($$insert into public.access_grants (area, user_id, scope, granted_by, parent_id)
  select 'payroll_tax', test.pid('office@example.com'), 'all', test.pid('boss@example.com'), id from public.access_grants where area = 'payroll_tax' and user_id = test.pid('boss@example.com')$$,
  'passing on can''t widen the scope (all staff)');
select test.refused($$insert into public.access_grants (area, user_id, scope, scope_ids, granted_by, parent_id, can_pass_on)
  select 'payroll_tax', test.pid('office@example.com'), 'teams', array[test.team('North')], test.pid('boss@example.com'), id, true from public.access_grants where area = 'payroll_tax' and user_id = test.pid('boss@example.com')$$,
  'a staff admin can''t be allowed to pass it on further');
select test.refused($$insert into public.access_grants (area, user_id, scope, scope_ids, granted_by, parent_id)
  select 'payroll_tax', test.pid('boss2@example.com'), 'teams', array[test.team('North')], test.pid('boss@example.com'), id from public.access_grants where area = 'payroll_tax' and user_id = test.pid('boss@example.com')$$,
  'managers pass on only to staff admins');
insert into public.access_grants (area, user_id, scope, scope_ids, can_reveal_tfn, granted_by, parent_id, expires_at)
  select 'payroll_tax', test.pid('office@example.com'), 'people', array[test.pid('sam@example.com')], true, test.pid('boss@example.com'), id, now() + interval '30 days'
    from public.access_grants where area = 'payroll_tax' and user_id = test.pid('boss@example.com');
reset role;

select test.act_as('office@example.com');
set role authenticated;
select test.ok(public.has_access('payroll_tax', test.pid('sam@example.com')), 'a staff admin gets what a manager passed on (a person in their team)');
select test.ok(not public.has_access('payroll_tax', test.pid('kim@example.com')), 'and nothing wider');
select test.ok(not public.has_access('identity_docs', test.pid('sam@example.com')), 'staff admins don''t inherit other areas');
select test.ok((select count(*) from public.access_grants) = 1, 'a staff admin sees only their own grant');
reset role;

select test.act_as('office2@example.com');
set role authenticated;
select test.ok(not public.has_access('payroll_tax', test.pid('sam@example.com')), 'another staff admin has nothing');
select test.ok(not public.has_access('staff_details', test.pid('sam@example.com')), 'staff admins get no staff details access automatically');
reset role;

-- ---------------------------------------------------------------------------
-- Expiry, demotion, revoke and cascade
-- ---------------------------------------------------------------------------
-- An expired grant gives nothing.
select test.act_as('owner@example.com');
set role authenticated;
insert into public.access_grants (area, user_id, granted_by, expires_at) values ('identity_docs', test.pid('boss2@example.com'), test.pid('owner@example.com'), now() + interval '1 day');
reset role;
set session_replication_role = replica; -- test set-up only: make the grant look expired
update public.access_grants set expires_at = now() - interval '1 minute' where area = 'identity_docs';
set session_replication_role = origin;
select test.act_as('boss2@example.com');
set role authenticated;
select test.ok(not public.has_access('identity_docs', test.pid('sam@example.com')), 'an expired grant gives no access');
reset role;

-- Revoking the manager's grant ends what they passed on.
select test.act_as('owner@example.com');
set role authenticated;
update public.access_grants set revoked_at = now() where area = 'payroll_tax' and user_id = test.pid('boss@example.com');
select test.refused($$delete from public.access_grants$$, 'grants are never deleted');
reset role;
select test.ok((select revoked_by from public.access_grants where area = 'payroll_tax' and user_id = test.pid('boss@example.com')) = test.pid('owner@example.com'), 'who revoked it is recorded');
select test.ok((select revoked_at is not null from public.access_grants where area = 'payroll_tax' and user_id = test.pid('office@example.com')), 'revoking also ends what was passed on');
select test.act_as('office@example.com');
set role authenticated;
select test.ok(not public.has_access('payroll_tax', test.pid('sam@example.com')), 'immediately');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
select test.ok(not public.has_access('payroll_tax', test.pid('sam@example.com')), 'the manager loses it too');
reset role;

-- A deactivated manager's grant stops working.
select test.act_as('owner@example.com');
set role authenticated;
update public.profiles set active = false where id = test.pid('boss2@example.com');
insert into public.access_grants (area, user_id, granted_by) values ('staff_details', test.pid('office2@example.com'), test.pid('owner@example.com'));
reset role;
select test.act_as('office2@example.com');
set role authenticated;
select test.ok(public.has_access('staff_details', test.pid('kim@example.com')), 'the system admin can give a staff admin Staff details directly');
reset role;

-- Signed out: nothing.
set role anon;
select test.refused($$select count(*) from public.access_grants$$, 'signed out: no grants readable');
reset role;

-- ---------------------------------------------------------------------------
-- Settings: live for managers, drafts for the system admin
-- ---------------------------------------------------------------------------
select test.act_as('boss@example.com');
set role authenticated;
select test.ok(public.save_draft('setting', 'tasks.sla_weekdays_only', 'false'::jsonb) in ('live', 'unchanged'), 'a manager''s SLA change applies straight away');
select test.ok((select count(*) from public.settings_drafts) = 0, 'and leaves no draft');
reset role;
select test.ok((select value from public.app_settings where key = 'tasks.sla_weekdays_only') = 'false'::jsonb, 'the setting is live');

select test.act_as('owner@example.com');
set role authenticated;
select test.ok(public.save_draft('setting', 'tasks.sla_weekdays_only', 'true'::jsonb) = 'saved', 'the system admin''s change waits for Deploy');
reset role;
select test.ok((select value from public.app_settings where key = 'tasks.sla_weekdays_only') = 'false'::jsonb, 'not live yet');
select test.act_as('owner@example.com');
set role authenticated;
select test.ok(public.deploy_drafts() = 1, 'Deploy makes it live');
reset role;
select test.ok((select value from public.app_settings where key = 'tasks.sla_weekdays_only') = 'true'::jsonb, 'now live');

select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$select public.save_draft('setting', 'tasks.sla_weekdays_only', 'false'::jsonb)$$, 'staff can''t change settings');
select test.refused($$select public.apply_draft('setting', 'tasks.sla_weekdays_only')$$, 'nobody calls apply_draft directly');
reset role;
