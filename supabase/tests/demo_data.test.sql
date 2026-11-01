-- Staff Portal · © cmeproject. All rights reserved.
--
-- Demo data: the system admin loads sample records, deletes only those, or
-- clears every task. Nobody else can.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('office@example.com', 'Olive', 'staff_admin'), ('sam@example.com', 'Sam', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('office@example.com'), ('sam@example.com');
update public.features set enabled = true, included = true where key = 'assistant';
insert into public.registries (name, kind, prefix) values ('Incidents', 'tasks', 'INC');

-- A real task that must survive "delete sample records".
select test.act_as('boss@example.com');
set role authenticated;
select public.create_task('Real work', (select id from public.registries where prefix = 'GEN'), (select id from public.profiles where email = 'sam@example.com'));
select test.refused($$select public.demo_load()$$, 'a manager can''t load sample records');
select test.refused($$select public.demo_clear_all_tasks()$$, 'or clear all tasks');
reset role;

select test.act_as('owner@example.com');
set role authenticated;
select public.demo_load() as loaded \gset
reset role;
select test.ok(:loaded = 15, 'it loads 15 sample records (12 tasks and 3 enquiries)');
select test.ok((select count(*) from public.tasks where title like 'Call back: %') = 3, 'each sample enquiry made its Call back task');
select test.ok((select count(*) from public.tasks where registry_id = (select id from public.registries where prefix = 'INC')) = 2, 'incidents go in the Incidents register');
select test.ok((select count(distinct status) from public.tasks) >= 4, 'in different states');
select test.ok(not exists (select 1 from public.email_outbox e join public.demo_records d on d.row_id = e.task_id), 'no emails go out for them');

select test.act_as('owner@example.com');
set role authenticated;
select public.demo_clear() as cleared \gset
reset role;
select test.ok(:cleared = 18, 'deleting sample records removes the 15 tasks (with Call backs) and 3 enquiries');
select test.ok((select count(*) from public.tasks) = 1 and exists (select 1 from public.tasks where title = 'Real work'), 'real work is kept');
select test.ok((select count(*) from public.website_enquiries) = 0, 'sample enquiries are gone');

select test.act_as('owner@example.com');
set role authenticated;
select public.demo_clear_all_tasks() as all_gone \gset
reset role;
select test.ok(:all_gone = 1 and (select count(*) from public.tasks) = 0, 'clear all tasks removes every task');
select test.act_as('boss@example.com');
set role authenticated;
select public.create_task('After the clear', (select id from public.registries where prefix = 'GEN'), (select id from public.profiles where email = 'sam@example.com'));
reset role;
select test.refused($$delete from public.task_events$$, 'task history is append-only again afterwards');

\o
\echo All demo data tests passed.
