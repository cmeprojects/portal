-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 139, privacy review SEC-003): who reads shift notes about a client.
\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null
insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('boss@example.com', 'Morgan', 'manager'), ('sam@example.com', 'Sam', 'support_worker');
insert into public.invitations (email, full_name, role, job_title_id)
select x.e, x.n, 'support_worker', (select id from public.job_titles where name = x.t)
  from (values ('cm@example.com', 'Casey', 'Case Manager'), ('pay@example.com', 'Pat', 'Payroll Officer')) x(e, n, t);
insert into public.invitations (email, full_name, role) values ('sa@example.com', 'Sasha', 'staff_admin');
insert into auth.users (email) values ('boss@example.com'), ('sam@example.com'), ('cm@example.com'), ('pay@example.com'), ('sa@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.cid() returns uuid language sql security definer as $$ select id from public.car_clients limit 1 $$;
create function test.sid() returns uuid language sql security definer as $$ select id from public.shifts limit 1 $$;
grant execute on all functions in schema test to authenticated;
insert into public.car_clients (name, status) values ('Test Client', 'active');
insert into public.client_locations (client_id, label, address, approved) select id, 'Home', '1 Test St', true from public.car_clients;
insert into public.client_services (client_id, program_id, label, status, start_date, location_id)
select c.id, (select id from public.client_programs where name = 'Private'), 'Support', 'planned', current_date, l.id from public.car_clients c join public.client_locations l on l.client_id = c.id;
insert into public.client_assignments (client_id, user_id, assigned_as, assigned_by) values (test.cid(), test.pid('cm@example.com'), 'case_manager', test.pid('boss@example.com'));

select test.act_as('boss@example.com');
set role authenticated;
insert into public.shifts (worker_id, client_id, service_id, location_id, starts_at, ends_at, status)
select test.pid('sam@example.com'), s.client_id, s.id, s.location_id, now() - interval '3 hours', now() - interval '1 hour', 'published' from public.client_services s;
reset role;
select test.act_as('sam@example.com');
set role authenticated;
insert into public.shift_service_records (shift_id, delivered, concern, concern_note) values (test.sid(), 'Shower and lunch.', true, 'A small fall, no injury seen.');
select test.ok((select count(*) from public.shift_service_records) = 1, 'the worker reads their own notes');
reset role;
select test.ok((select client_id from public.shift_service_records) = test.cid(), 'the notes keep the client they''re about');

select test.act_as('cm@example.com');
set role authenticated;
select test.ok((select count(*) from public.shift_service_records) = 1, 'the client''s case manager reads them');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
select test.ok((select count(*) from public.shift_service_records) = 1, 'managers read them');
reset role;
select test.act_as('pay@example.com');
set role authenticated;
select test.ok(public.can('ops.roster', 'view'), 'payroll sees the roster');
select test.ok((select count(*) from public.shift_service_records) = 0, 'but not the care notes');
select test.ok((select count(*) from public.shift_events where summary like 'recorded the service delivered%flagged a concern') = 1, 'they still see that notes are in, with a concern');
reset role;
select test.act_as('sa@example.com');
set role authenticated;
select test.ok((select count(*) from public.shift_service_records) = 0, 'staff admins don''t read care notes');
reset role;
\o
select 'All shift notes privacy tests passed.';
