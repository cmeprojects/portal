-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects: TFN declarations (file only, TFN access only), sent-to-ATO
-- date, manual deletion and record keeping.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('office@example.com', 'Olive', 'staff_admin'), ('sam@example.com', 'Sam', 'support_worker'), ('kim@example.com', 'Kim', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('office@example.com'), ('sam@example.com'), ('kim@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
grant execute on all functions in schema test to authenticated;

select test.ok(not exists (select 1 from information_schema.columns where table_name = 'staff_tax' and column_name ilike '%tfn%' and column_name not ilike '%form%'), 'no TFN number column');

-- Sam uploads their form.
select test.act_as('sam@example.com');
set role authenticated;
insert into public.staff_tax (user_id, form_path, form_name) values (test.pid('sam@example.com'), 'tax/' || test.pid('sam@example.com') || '/tfn.pdf', 'tfn.pdf');
select test.refused($$update public.staff_tax set lodged_on = current_date$$, 'staff can''t mark their own form as sent to the ATO');
select test.refused($$update public.staff_tax set verified_at = now()$$, 'or checked');
reset role;

-- Payroll and tax access WITHOUT the TFN tick sees nothing.
select test.act_as('owner@example.com');
set role authenticated;
insert into public.access_grants (area, user_id, granted_by, can_pass_on) values ('payroll_tax', test.pid('boss@example.com'), test.pid('owner@example.com'), true);
reset role;
select test.act_as('boss@example.com');
set role authenticated;
select test.ok((select count(*) from public.staff_tax) = 0, 'Payroll and tax access without "can reveal TFN": no TFN forms');
reset role;

-- With the TFN tick (given to the staff admin handling onboarding, through the manager).
select test.act_as('owner@example.com');
set role authenticated;
update public.access_grants set revoked_at = now() where user_id = test.pid('boss@example.com');
insert into public.access_grants (area, user_id, granted_by, can_pass_on, can_reveal_tfn) values ('payroll_tax', test.pid('boss@example.com'), test.pid('owner@example.com'), true, true);
reset role;
select test.act_as('boss@example.com');
set role authenticated;
insert into public.access_grants (area, user_id, granted_by, parent_id, can_reveal_tfn)
  select 'payroll_tax', test.pid('office@example.com'), test.pid('boss@example.com'), id, true from public.access_grants where user_id = test.pid('boss@example.com') and revoked_at is null;
reset role;
select test.act_as('office@example.com');
set role authenticated;
select test.ok((select count(*) from public.staff_tax) = 1, 'the staff admin with TFN access sees the form');
update public.staff_tax set verified_at = now(), lodged_on = current_date where user_id = test.pid('sam@example.com');
reset role;
select test.ok((select lodged_by = test.pid('office@example.com') and verified_by = test.pid('office@example.com') from public.staff_tax), 'checked and sent-to-ATO date recorded with who did it');
select test.ok((select count(*) from public.sensitive_access_log where action = 'lodged') = 1, 'sending is logged');

select test.act_as('kim@example.com');
set role authenticated;
select test.ok((select count(*) from public.staff_tax) = 0, 'colleagues see nothing');
select test.refused($$delete from public.staff_tax$$, 'or delete');
reset role;

-- A new upload clears the check and the sent date.
select test.act_as('sam@example.com');
set role authenticated;
update public.staff_tax set form_path = 'tax/' || test.pid('sam@example.com') || '/tfn2.pdf';
select test.refused($$delete from public.staff_tax$$, 'staff can''t delete their own form');
reset role;
select test.ok((select verified_at is null and lodged_on is null from public.staff_tax), 'a new upload needs checking and sending again');

-- Manual deletion, logged.
select test.act_as('office@example.com');
set role authenticated;
delete from public.staff_tax where user_id = test.pid('sam@example.com');
reset role;
select test.ok((select count(*) from public.staff_tax) = 0 and exists (select 1 from public.sensitive_access_log where action = 'delete'), 'deleted by hand, and logged');

-- Record keeping: the system admin deletes a leaver's other records.
select test.act_as('kim@example.com');
set role authenticated;
insert into public.staff_bank (user_id, account_name, bsb, account_number) values (test.pid('kim@example.com'), 'Kim', '062-000', '12345678');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$delete from public.staff_bank where user_id = test.pid('kim@example.com')$$, 'only the system admin deletes bank records');
reset role;
select test.act_as('owner@example.com');
set role authenticated;
delete from public.staff_bank where user_id = test.pid('kim@example.com');
reset role;
select test.ok((select count(*) from public.staff_bank) = 0 and exists (select 1 from public.sensitive_access_log where action = 'delete' and detail = 'Bank details'), 'the system admin deletes, and it''s logged');
select test.ok((select value::text from public.app_settings where key = 'records.private_retention_years') = '5', 'records kept 5 years after leaving by default');

set role anon;
select test.refused($$select count(*) from public.staff_tax$$, 'signed out: nothing');
reset role;

-- Blank form: a manager with Payroll and tax access can set it; staff can't.
select test.act_as('boss@example.com');
set role authenticated;
update public.app_settings set value = '"templates/tfn-declaration.pdf"' where key = 'records.tfn_template';
reset role;
select test.ok((select value #>> '{}' from public.app_settings where key = 'records.tfn_template') = 'templates/tfn-declaration.pdf', 'a manager with Payroll and tax access sets the blank form');
select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$update public.app_settings set value = '"x"' where key = 'records.tfn_template'$$, 'staff can''t');
reset role;
