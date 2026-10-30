-- Staff Portal · © cmeproject. All rights reserved.
--
-- Helping someone sign in: the system admin, plus the roles they choose.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('office@example.com', 'Olive', 'staff_admin'), ('sam@example.com', 'Sam', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('office@example.com'), ('sam@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
grant execute on all functions in schema test to authenticated;

select test.act_as('office@example.com');
set role authenticated;
select test.refused($$select public.log_admin_action('password_reset_sent', test.pid('sam@example.com'))$$, 'by default a staff admin can''t');
reset role;

select test.act_as('owner@example.com');
set role authenticated;
select public.log_admin_action('mfa_reset', test.pid('sam@example.com'));
select test.ok(public.can_help_sign_in(test.pid('boss@example.com')), 'the system admin can help anyone');
select test.ok(not public.can_help_sign_in(test.pid('owner@example.com')), 'but not themselves');
reset role;

update public.app_settings set value = '["staff_admin", "manager"]' where key = 'people.access_reset_roles';
select test.act_as('office@example.com');
set role authenticated;
select public.log_admin_action('password_reset_sent', test.pid('sam@example.com'));
select test.ok(public.can_help_sign_in(test.pid('boss@example.com')), 'once allowed, a staff admin can help a manager');
select test.refused($$select public.log_admin_action('mfa_reset', test.pid('owner@example.com'))$$, 'but never the system admin');
select test.refused($$select public.log_admin_action('pin_cleared', test.pid('office@example.com'))$$, 'or themselves');
select test.refused($$select * from public.email_throttle$$, 'and can''t read the email limits');
reset role;
select test.ok((select count(*) from public.audit_log where action in ('mfa_reset', 'password_reset_sent')) = 2, 'each one is in the change log');

\o
\echo All sign-in help tests passed.
