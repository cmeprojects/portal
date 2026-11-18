-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 140): the owner's privacy decisions (SEC-003 §4).
\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null
insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('boss@example.com', 'Morgan', 'manager'), ('sam@example.com', 'Sam', 'support_worker');
insert into public.invitations (email, full_name, role, job_title_id)
select 'pay@example.com', 'Pat', 'support_worker', id from public.job_titles where name = 'Payroll Officer';
insert into auth.users (email) values ('boss@example.com'), ('sam@example.com'), ('pay@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.cid() returns uuid language sql security definer as $$ select id from public.car_clients limit 1 $$;
grant execute on all functions in schema test to authenticated;
insert into public.car_clients (name, status) values ('Test Client', 'active');
update public.staff_bank set account_name = 'Sam Worker', bsb = '062-000', account_number = '12345678' where user_id = test.pid('sam@example.com');

select test.act_as('pay@example.com');
set role authenticated;
select test.ok(public.can('clients.list', 'view', test.cid()), 'payroll still sees the client list');
select test.ok(not public.can('clients.comms', 'view', test.cid()), 'but not communication preferences');
select test.ok(not public.can('clients.assign', 'view', test.cid()), 'or who looks after each client');
select test.ok((select count(*) from public.staff_bank where user_id = test.pid('sam@example.com')) = 1, 'payroll reads staff bank details');
select test.refused($$update public.staff_bank set bsb = '000-000' where user_id = test.pid('sam@example.com')$$, 'but can''t change them');
select test.ok(not public.has_tfn_access(test.pid('sam@example.com')), 'and TFN forms stay with the people given them');
reset role;

select test.act_as('sam@example.com');
set role authenticated;
select test.ok((select count(*) from public.staff_bank where user_id <> auth.uid()) = 0, 'other staff don''t read anyone else''s bank details');
reset role;

-- Who opened a client's page.
select test.act_as('boss@example.com');
set role authenticated;
insert into public.client_staff_views (client_id) values (test.cid());
select test.refused($$insert into public.client_staff_views (client_id, user_id) values (test.cid(), test.pid('sam@example.com'))$$, 'nobody records an opening for someone else');
select test.refused($$delete from public.client_staff_views$$, 'the log isn''t deleted');
select test.ok((select count(*) from public.client_staff_views) = 1, 'people who assign staff read who opened');
reset role;
select test.act_as('sam@example.com');
set role authenticated;
select test.ok((select count(*) from public.client_staff_views) = 0, 'other staff don''t');
reset role;
\o
select 'All privacy decision tests passed.';
