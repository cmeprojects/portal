-- Staff Portal · © cmeproject. All rights reserved.
--
-- Two-factor login per person: the system admin can let one person off.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('boss@example.com', 'Morgan', 'manager'), ('sam@example.com', 'Sam', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('sam@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
grant execute on all functions in schema test to authenticated;
update public.features set enabled = true where key = 'two_factor';
update public.app_settings set value = '["manager"]' where key = 'security.mfa_required_roles';

select test.act_as('boss@example.com', 'aal1');
set role authenticated;
select test.ok(not public.mfa_ok(), 'a manager without a code isn''t through when managers need it');
select test.refused($$select public.set_mfa_exempt(auth.uid(), true)$$, 'and can''t let themselves off');
reset role;

select test.act_as('owner@example.com');
set role authenticated;
select public.set_mfa_exempt(test.pid('boss@example.com'), true);
select test.refused($$select public.set_mfa_exempt(auth.uid(), true)$$, 'system admins always need it');
reset role;

select test.act_as('boss@example.com', 'aal1');
set role authenticated;
select test.ok(public.mfa_ok(), 'once let off, they get in without a code');
select test.ok(not (select mfa_required from public.my_access()), 'and aren''t asked for one');
reset role;
select test.ok((select count(*) from public.audit_log where action = 'mfa_exempted') = 1, 'it''s in the change log');

\o
\echo All two-factor per person tests passed.
