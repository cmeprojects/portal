-- Staff Portal · © cmeproject. All rights reserved.
--
-- Delegation: a named manager looks after chosen areas of System settings.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('boss2@example.com', 'Max', 'manager'), ('office@example.com', 'Olive', 'staff_admin');
insert into auth.users (email) values ('boss@example.com'), ('boss2@example.com'), ('office@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
grant execute on all functions in schema test to authenticated;

select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$update public.app_settings set value = '"Hacked"' where key = 'brand.company_name'$$, 'a manager can''t change branding by default');
select test.refused($$select public.set_delegation(test.pid('boss@example.com'), array['branding'])$$, 'a manager can''t delegate to themselves');
reset role;

select test.act_as('owner@example.com');
set role authenticated;
select public.set_delegation(test.pid('boss@example.com'), array['branding', 'messages', 'audit']);
select test.refused($$select public.set_delegation(test.pid('office@example.com'), array['branding'])$$, 'only managers can be delegated to');
select test.refused($$select public.set_delegation(test.pid('boss2@example.com'), array['security'])$$, 'security can''t be delegated');
reset role;

select test.act_as('boss@example.com');
set role authenticated;
update public.app_settings set value = '"Engaged Care Melbourne"' where key = 'brand.company_name';
update public.app_settings set value = '"Office closed Monday"' where key = 'brand.announcement';
select test.refused($$update public.app_settings set value = '[]' where key = 'security.mfa_required_roles'$$, 'a delegate can''t change security');
select test.refused($$update public.app_settings set value = '"x"' where key = 'region.timezone'$$, 'or general settings');
select test.refused($$update public.app_settings set value = 'true' where key = 'people.staff_admin_role_approval' and value = 'true'$$ ,
  'or areas they weren''t given');
select test.refused($$update public.features set enabled = false where key = 'tasks'$$, 'or feature switches');
select test.ok((select count(*) from public.audit_log) > 0, 'with Change log, they can read it');
reset role;
select test.ok((select value #>> '{}' = 'Engaged Care Melbourne' from public.app_settings where key = 'brand.company_name'),
  'a delegated manager changes branding');

select test.act_as('boss2@example.com');
set role authenticated;
select test.ok((select count(*) from public.audit_log) = 0, 'other managers can''t read the change log');
reset role;

-- No longer a manager: the delegation goes.
select test.act_as('owner@example.com');
set role authenticated;
update public.profiles set role = 'staff_admin' where email = 'boss@example.com';
reset role;
select test.ok(not exists (select 1 from public.admin_delegations), 'a role change removes the delegation');

\o
\echo 'All delegation tests passed.'
