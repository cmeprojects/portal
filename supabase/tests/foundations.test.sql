-- Staff Portal · © cmeproject. All rights reserved.
--
-- Security rule tests for Milestone 1. Run with: npm run test:db
-- Each check raises an error (and stops the run) if a rule is broken.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null


-- ---------------------------------------------------------------------------
-- People: the first account becomes system admin; others need an invitation.
-- ---------------------------------------------------------------------------

insert into auth.users (email) values ('owner@example.com');
select test.ok((select role = 'system_admin' and active from public.profiles where email = 'owner@example.com'),
  'first account becomes an active system admin');

insert into public.teams (name) values ('Derrimut house');

insert into public.invitations (email, full_name, role, team_id)
values
  ('Office@Example.com', 'Olive Office', 'staff_admin', null),
  ('boss@example.com',   'Morgan Manager', 'manager', null),
  ('lead@example.com',   'Taylor Lead', 'team_leader', null),
  ('sam@example.com',    'Sam Worker', 'support_worker', (select id from public.teams)),
  ('kim@example.com',    'Kim Worker', 'support_worker', null);

insert into auth.users (email) values
  ('office@example.com'), ('boss@example.com'), ('lead@example.com'),
  ('sam@example.com'), ('kim@example.com'), ('stranger@example.com');

insert into public.team_leaders (team_id, user_id)
select t.id, p.id from public.teams t, public.profiles p where p.email = 'lead@example.com';

select test.ok((select role = 'staff_admin' and full_name = 'Olive Office' from public.profiles where email = 'office@example.com'),
  'invited person gets the invited role and name (email matched case-insensitively)');
select test.ok((select accepted_at is not null from public.invitations where email = 'sam@example.com'),
  'invitation is marked accepted');
select test.ok((select team_id is not null from public.profiles where email = 'sam@example.com'),
  'invited person joins the invited team');
select test.ok((select not active from public.profiles where email = 'stranger@example.com'),
  'someone with no invitation starts deactivated');

-- ---------------------------------------------------------------------------
-- Signed out
-- ---------------------------------------------------------------------------

select set_config('request.jwt.claims', '{}', false);
set role anon;
select test.ok((select count(*) from public.app_settings) = (select count(*) from public.app_settings where is_public),
  'signed out: only public (branding) settings are visible');
select test.ok((select count(*) from public.app_settings where key = 'brand.company_name') = 1,
  'signed out: company name is visible for the sign-in page');
select test.ok((select count(*) from public.features) = 2,
  'signed out: only the sign-in options are visible from the feature list');
reset role;

-- ---------------------------------------------------------------------------
-- Support worker
-- ---------------------------------------------------------------------------

select test.act_as('sam@example.com', 'aal1');
set role authenticated;
select test.ok((select count(*) from public.registries) = 7, 'support worker sees registries');
select test.ok((select count(*) from public.profiles) = 7, 'support worker sees colleagues (for assigning tasks)');
select test.refused($$update public.profiles set role = 'manager' where email = 'sam@example.com'$$,
  'support worker cannot promote themselves');
select test.refused($$update public.profiles set active = false where email = 'kim@example.com'$$,
  'support worker cannot deactivate others');
select test.refused($$update public.features set enabled = false where key = 'tasks'$$,
  'support worker cannot switch features');
select test.refused($$insert into public.invitations (email) values ('x@example.com')$$,
  'support worker cannot invite');
select test.ok((select count(*) from public.audit_log) = 0, 'support worker cannot read the audit log');
select test.ok((select count(*) from public.invitations) = 0, 'support worker cannot read invitations');
update public.profiles set full_name = 'Sam N.' where email = 'sam@example.com';
reset role;
select test.ok((select full_name = 'Sam N.' from public.profiles where email = 'sam@example.com'),
  'support worker can change their own name');

-- ---------------------------------------------------------------------------
-- Two-factor login
-- ---------------------------------------------------------------------------

select test.act_as('boss@example.com', 'aal1');
set role authenticated;
select test.ok((select count(*) from public.profiles) = 1,
  'manager without two-factor sees only their own profile');
select test.ok((select count(*) from public.registries) = 0,
  'manager without two-factor sees no registries');
select test.ok((select mfa_required and not mfa_ok from public.my_access()),
  'my_access tells the app the manager still needs two-factor');
reset role;
select test.act_as('boss@example.com', 'aal2');
set role authenticated;
select test.ok((select count(*) from public.profiles) = 7, 'manager with two-factor sees colleagues');
select test.refused($$update public.profiles set role = 'manager' where email = 'kim@example.com'$$,
  'manager cannot change roles');
select test.refused($$update public.app_settings set value = '"Hacked"' where key = 'brand.company_name'$$,
  'manager cannot change system settings');
reset role;

-- ---------------------------------------------------------------------------
-- Staff admin
-- ---------------------------------------------------------------------------

select test.act_as('office@example.com', 'aal1');
set role authenticated;
select test.refused($$update public.profiles set role = 'team_leader' where email = 'kim@example.com'$$,
  'staff admin must finish two-factor login first');
reset role;

select test.act_as('office@example.com');
set role authenticated;
update public.profiles set role = 'team_leader' where email = 'kim@example.com';
update public.profiles set active = false where email = 'kim@example.com';
insert into public.invitations (email, full_name, role) values ('new@example.com', 'New Person', 'manager');
insert into public.registries (name) values ('Test registry');
select test.refused($$update public.profiles set role = 'system_admin' where email = 'boss@example.com'$$,
  'staff admin cannot make a system admin');
select test.refused($$update public.profiles set role = 'staff_admin' where email = 'boss@example.com'$$,
  'staff admin cannot make another staff admin');
select test.refused($$update public.profiles set active = false where email = 'owner@example.com'$$,
  'staff admin cannot deactivate a system admin');
select test.refused($$update public.profiles set active = false where email = 'office@example.com'$$,
  'staff admin cannot deactivate themselves');
select test.refused($$insert into public.invitations (email, role) values ('evil@example.com', 'system_admin')$$,
  'staff admin cannot invite a system admin');
select test.refused($$update public.features set enabled = false where key = 'tasks'$$,
  'staff admin cannot switch features');
select test.ok((select count(*) from public.audit_log) = 0, 'staff admin cannot read the audit log');
select public.log_admin_action('invite_resent', (select id from public.profiles where email = 'sam@example.com'));
select test.refused($$select public.log_admin_action('mfa_reset', (select id from public.profiles where email = 'sam@example.com'))$$,
  'staff admin cannot log a two-factor reset');
select test.refused($$select public.log_admin_action('anything', (select id from public.profiles where email = 'sam@example.com'))$$,
  'only known admin actions can be logged');
reset role;

select test.ok((select role = 'team_leader' and not active and deactivated_at is not null
                  from public.profiles where email = 'kim@example.com'),
  'staff admin changed a role and deactivated someone');

-- Deactivated people lose access straight away.
select test.act_as('kim@example.com');
set role authenticated;
select test.ok((select count(*) from public.profiles) = 1,
  'deactivated person sees only their own profile (so the app can tell them)');
select test.ok((select count(*) from public.registries) = 0, 'deactivated person sees no registries');
reset role;

-- ---------------------------------------------------------------------------
-- System admin
-- ---------------------------------------------------------------------------

select test.act_as('owner@example.com', 'aal1');
set role authenticated;
select test.refused($$update public.features set enabled = false where key = 'vehicles'$$,
  'system admin always needs two-factor login');
reset role;

select test.act_as('owner@example.com');
set role authenticated;
update public.features set enabled = true where key = 'vehicles';
update public.app_settings set value = '"Engaged Care"' where key = 'brand.company_name';
update public.profiles set role = 'staff_admin' where email = 'boss@example.com';
select test.ok((select count(*) from public.audit_log where action = 'feature_on') = 1,
  'system admin switched a feature on, and it was logged');
select test.ok((select count(*) from public.audit_log where action = 'setting_changed') = 1,
  'setting change was logged');
select test.ok((select count(*) from public.audit_log where action = 'invite_resent') = 1,
  'resent invite was logged');
select test.ok((select count(*) from public.audit_log where action = 'role_changed') = 2,
  'role changes were logged');
select test.refused($$update public.audit_log set action = 'nothing'$$, 'system admin cannot edit the audit log');
select test.refused($$delete from public.audit_log$$, 'system admin cannot delete the audit log');
select test.refused($$update public.profiles set role = 'manager' where email = 'owner@example.com'$$,
  'system admin cannot demote themselves');
reset role;

-- Not even the database owner can rewrite history.
select set_config('request.jwt.claims', '{}', false);
select test.refused($$delete from public.audit_log$$, 'database owner cannot delete the audit log');
select test.refused($$update public.profiles set role = 'manager' where email = 'owner@example.com'$$,
  'the last system admin cannot be removed');

select test.ok(public.feature_enabled('vehicles'), 'feature_enabled reads the switch');

\o
\echo 'All foundation security tests passed.'
