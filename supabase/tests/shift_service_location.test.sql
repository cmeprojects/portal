-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 130): client shifts need a service and a location.
\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null
insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('boss@example.com', 'Morgan', 'manager');
insert into auth.users (email) values ('boss@example.com');
insert into public.car_clients (name, status) values ('Ready Client', 'active');
insert into public.client_locations (client_id, label, address, approved) select id, 'Home', '1 Test St', true from public.car_clients;
insert into public.client_services (client_id, program_id, label, status, start_date, location_id)
select c.id, (select id from public.client_programs where name = 'Private'), 'Domestic', 'planned', current_date, l.id from public.car_clients c join public.client_locations l on l.client_id = c.id;
-- Update 148: services list the shift types they cover (here: every client shift type).
update public.client_services set shift_types = (select array_agg(key) from public.shift_types where used_for in ('client', 'both')) where origin = 'legacy' and cardinality(shift_types) = 0;
create function test.t(p int) returns timestamptz language sql as $$ select date_trunc('hour', now()) + make_interval(hours => p) $$;
grant execute on all functions in schema test to authenticated;
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$insert into public.shifts (starts_at, ends_at, client_id, status) select test.t(24), test.t(26), id, 'draft' from public.car_clients$$, 'a client shift without a service or location is refused');
insert into public.shifts (starts_at, ends_at, client_id, service_id, location_id, status)
select test.t(24), test.t(26), c.id, s.id, s.location_id, 'draft' from public.car_clients c join public.client_services s on s.client_id = c.id;
insert into public.shifts (starts_at, ends_at, status, notes) values (test.t(30), test.t(31), 'draft', 'Team meeting');
reset role;
select test.ok((select count(*) from public.shifts) = 2, 'with both it saves; a shift with no client (a meeting) needs neither');
\o
select 'All shift service and location tests passed.';
