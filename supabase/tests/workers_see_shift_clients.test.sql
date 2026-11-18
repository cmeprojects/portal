-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 133): workers see their own shifts' client details.
\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null
insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('boss@example.com', 'Morgan', 'manager'), ('sam@example.com', 'Sam', 'support_worker'), ('kim@example.com', 'Kim', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('sam@example.com'), ('kim@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.n(p_email text, p_sql text) returns bigint language plpgsql as $$
declare v bigint;
begin
  perform test.act_as(p_email);
  execute 'set local role authenticated';
  execute 'select ' || p_sql into v;
  execute 'reset role';
  return v;
end $$;
grant execute on all functions in schema test to authenticated;
insert into public.car_clients (name, status) values ('Ann', 'active'), ('Bob', 'active');
insert into public.client_locations (client_id, label, address, approved) select id, 'Home', name || ' St', true from public.car_clients;
insert into public.client_services (client_id, program_id, label, status, start_date, location_id)
select c.id, (select id from public.client_programs where name = 'Private'), 'Support', 'planned', current_date, l.id from public.car_clients c join public.client_locations l on l.client_id = c.id;
insert into public.client_alerts (client_id, kind, severity, title, active) select id, 'safety', 'high', 'Dog', true from public.car_clients;
insert into public.client_details (client_id, date_of_birth) select id, '1950-01-01' from public.car_clients;
select test.act_as('boss@example.com');
set role authenticated;
insert into public.shifts (worker_id, starts_at, ends_at, client_id, service_id, location_id, status)
select test.pid('sam@example.com'), now() + interval '1 day', now() + interval '1 day 2 hours', c.id, v.id, v.location_id, 'published'
  from public.car_clients c join public.client_services v on v.client_id = c.id where c.name = 'Ann';
insert into public.shifts (worker_id, starts_at, ends_at, client_id, service_id, location_id, status)
select test.pid('kim@example.com'), now() + interval '2 days', now() + interval '2 days 2 hours', c.id, v.id, v.location_id, 'draft'
  from public.car_clients c join public.client_services v on v.client_id = c.id where c.name = 'Bob';
reset role;
select test.ok(test.n('sam@example.com', '(select count(*) from public.car_clients)') = 1, 'a worker sees the client of their published shift');
select test.ok(test.n('sam@example.com', '(select count(*) from public.client_locations)') = 1 and test.n('sam@example.com', '(select count(*) from public.client_alerts)') = 1, 'with its address and alerts');
select test.ok(test.n('sam@example.com', '(select count(*) from public.client_details)') = 0, 'but not the client''s details');
select test.ok(test.n('kim@example.com', '(select count(*) from public.car_clients)') = 0, 'a draft shift shows the worker nothing yet');
\o
select 'All worker shift-client tests passed.';
