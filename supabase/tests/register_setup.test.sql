-- Staff Portal · © cmeproject. All rights reserved.
--
-- "Setting up registers": delegated people change any register's set-up.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('boss@example.com', 'Morgan', 'manager'), ('office@example.com', 'Olive', 'staff_admin');
insert into auth.users (email) values ('boss@example.com'), ('office@example.com');
insert into public.registries (name, kind, prefix) values ('Incidents', 'tasks', 'INC');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
grant execute on all functions in schema test to authenticated;

select test.act_as('boss@example.com');
set role authenticated;
update public.registries set description = 'Changed' where prefix = 'INC';
reset role;
select test.ok((select description from public.registries where prefix = 'INC') is distinct from 'Changed', 'a manager who isn''t its manager can''t change a register');

update public.delegation_rules set mode = 'managers' where area = 'register_setup';
select test.act_as('boss@example.com');
set role authenticated;
select test.ok(public.can_setup_registry((select id from public.registries where prefix = 'INC')), 'with Setting up registers, every manager can');
update public.registries set description = 'Changed' where prefix = 'INC';
reset role;
select test.ok((select description from public.registries where prefix = 'INC') = 'Changed', 'and the change is saved');

update public.delegation_rules set mode = 'selected', people = array[test.pid('office@example.com')] where area = 'register_setup';
select test.act_as('office@example.com');
set role authenticated;
select test.ok(public.can_setup_registry((select id from public.registries where prefix = 'INC')), 'a chosen staff admin can too');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
select test.ok(not public.can_setup_registry((select id from public.registries where prefix = 'INC')), 'other managers can''t any more');
reset role;

\o
\echo All register set-up tests passed.
