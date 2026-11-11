-- Staff Portal · © cmeproject. All rights reserved.
--
-- Phase 3 (cmeprojects): sensitive staff records (bank, super, work rights),
-- the access log, checking (verify), and staged expiry reminders.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('office@example.com', 'Olive', 'staff_admin'),
  ('lead@example.com', 'Taylor', 'team_leader'), ('sam@example.com', 'Sam', 'support_worker'), ('kim@example.com', 'Kim', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('office@example.com'), ('lead@example.com'), ('sam@example.com'), ('kim@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
grant execute on all functions in schema test to authenticated;
insert into public.teams (name) values ('North');
insert into public.team_members (team_id, user_id) select id, test.pid('sam@example.com') from public.teams where name = 'North';
insert into public.team_leaders select id, test.pid('lead@example.com') from public.teams where name = 'North';

-- Defaults
select test.ok((select count(*) from public.compliance_items where title in ('First Aid certificate', 'CPR certificate', 'Life saving certificate') and not active and needs_expiry) = 3,
  'First Aid, CPR and Life saving are separate items, off until chosen');

-- The person keeps their own records.
select test.act_as('sam@example.com');
set role authenticated;
insert into public.staff_bank (user_id, account_name, bsb, account_number) values (test.pid('sam@example.com'), 'Sam Worker', '062-000', '12345678');
insert into public.staff_super (user_id, fund_name, fund_abn, usi, member_number) values (test.pid('sam@example.com'), 'Test Super', '12345678901', 'TST0001AU', 'M1');
insert into public.staff_work_rights (user_id, status, visa_subclass, visa_expiry) values (test.pid('sam@example.com'), 'visa', '482', public.local_today() + 20);
select test.refused($$insert into public.staff_bank (user_id, bsb) values (test.pid('sam@example.com'), '12')$$, 'a BSB must be 6 digits (NNN-NNN)');
select test.refused($$update public.staff_bank set verified_at = now() where user_id = test.pid('sam@example.com')$$, 'staff can''t mark their own record checked');
select test.refused($$delete from public.staff_bank$$, 'records aren''t deleted from the app');
select test.ok((select count(*) from public.staff_bank) = 1, 'staff see only their own bank details');
select test.ok((select count(*) from public.sensitive_access_log) = 0, 'staff can''t read the access log');
reset role;
select test.ok((select count(*) from public.sensitive_access_log where subject_id = test.pid('sam@example.com') and action = 'change') = 3, 'every change is logged');

select test.act_as('kim@example.com');
set role authenticated;
select test.ok((select count(*) from public.staff_bank) + (select count(*) from public.staff_super) + (select count(*) from public.staff_work_rights) = 0, 'colleagues see nothing');
select test.refused($$update public.staff_bank set account_number = '99999' where user_id = test.pid('sam@example.com')$$, 'or change it');
select test.refused($$insert into public.staff_bank (user_id) values (test.pid('sam@example.com'))$$, 'or add to it');
reset role;

-- Managers, team leaders and staff admins see nothing without access.
select test.act_as('boss@example.com');
set role authenticated;
select test.ok((select count(*) from public.staff_bank) = 0, 'a manager without Payroll and tax access sees no bank details');
select test.ok((select count(*) from public.staff_work_rights) = 0, 'or work rights');
reset role;
select test.act_as('lead@example.com');
set role authenticated;
select test.ok((select count(*) from public.staff_bank) + (select count(*) from public.staff_work_rights) = 0, 'a team leader sees nothing of their team''s');
reset role;

-- With access.
select test.act_as('owner@example.com');
set role authenticated;
select test.ok((select count(*) from public.staff_bank) = 1, 'the system admin sees bank details');
insert into public.access_grants (area, user_id, scope, can_pass_on, granted_by) values ('payroll_tax', test.pid('boss@example.com'), 'all', true, test.pid('owner@example.com'));
reset role;
select test.act_as('boss@example.com');
set role authenticated;
select test.ok((select count(*) from public.staff_bank) = 1 and (select count(*) from public.staff_super) = 1, 'Payroll and tax access shows bank and super');
select test.ok((select count(*) from public.staff_work_rights) = 0, 'but not work rights (a separate access)');
update public.staff_bank set verified_at = now() where user_id = test.pid('sam@example.com');
insert into public.sensitive_access_log (subject_id, area, action, detail) values (test.pid('sam@example.com'), 'payroll_tax', 'reveal', 'Account number');
select test.refused($$insert into public.sensitive_access_log (actor_id, subject_id, area, action) values (test.pid('kim@example.com'), test.pid('sam@example.com'), 'payroll_tax', 'view')$$, 'log entries are written as yourself only');
select test.refused($$update public.sensitive_access_log set detail = 'x'$$, 'the access log can''t be changed');
reset role;
select test.ok((select verified_by from public.staff_bank where user_id = test.pid('sam@example.com')) = test.pid('boss@example.com'), 'who checked it is recorded');

-- A change by the person needs checking again.
select test.act_as('sam@example.com');
set role authenticated;
update public.staff_bank set account_number = '87654321' where user_id = test.pid('sam@example.com');
reset role;
select test.ok((select verified_at is null from public.staff_bank where user_id = test.pid('sam@example.com')), 'changing your details clears the check');

-- A staff admin gets nothing automatically, and only what's passed on.
select test.act_as('office@example.com');
set role authenticated;
select test.ok((select count(*) from public.staff_bank) = 0, 'a staff admin sees nothing automatically');
reset role;

-- Signed out.
set role anon;
select test.refused($$select count(*) from public.staff_bank$$, 'signed out: no bank details');
select test.refused($$select count(*) from public.sensitive_access_log$$, 'signed out: no access log');
reset role;

-- Staged reminders: a document 45 days out (60-day stage), then 5 days out (7-day stage), once each.
select set_config('request.jwt.claims', '', false);
insert into public.compliance_items (kind, title, needs_expiry, active, created_by) values ('upload', 'Test licence', true, true, null);
insert into public.compliance_records (item_id, user_id, version, file_name, file_path, expires_on, status)
select id, test.pid('kim@example.com'), version, 'l.pdf', 'x/l.pdf', public.local_today() + 45, 'accepted' from public.compliance_items where title = 'Test licence';
select public.run_compliance_alerts();
select public.run_compliance_alerts();
select test.ok((select count(*) from public.notifications where user_id = test.pid('kim@example.com') and title like 'Test licence expires in 45 days') = 1, '60-day reminder, once');
update public.compliance_records set expires_on = public.local_today() + 5 where file_name = 'l.pdf';
select public.run_compliance_alerts();
select test.ok((select count(*) from public.notifications where user_id = test.pid('kim@example.com') and title like 'Test licence expires in 5 days') = 1, '7-day reminder');
select test.ok((select count(*) from public.notifications where user_id = test.pid('office@example.com') and title like 'Kim%Test licence%') = 2, 'onboarding managers get each stage too');

-- Visa: the person and Identity and work rights holders only; no visa details in the message.
select public.run_compliance_alerts();
select test.ok((select count(*) from public.notifications where user_id = test.pid('sam@example.com') and title = 'Your visa expires in 20 days') = 1, 'the person is reminded about their visa');
select test.ok((select count(*) from public.notifications where title like '%work rights%') = 0, 'nobody else without Identity and work rights access is told');
select test.ok(not exists (select 1 from public.notifications where body like '%482%' or title like '%482%'), 'visa details never appear in notifications');
