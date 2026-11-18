-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 146): house rostering (SIL): other residents on a shift.
\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null
insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('boss@example.com', 'Morgan', 'manager'), ('sam@example.com', 'Sam', 'support_worker'), ('kim@example.com', 'Kim', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('sam@example.com'), ('kim@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.cid(p text) returns uuid language sql security definer as $$ select id from public.car_clients where name = p $$;
create function test.svc(p text) returns uuid language sql security definer as $$ select s.id from public.client_services s join public.car_clients c on c.id = s.client_id where c.name = p order by s.created_at limit 1 $$;
create function test.sid() returns uuid language sql security definer as $$ select id from public.shifts limit 1 $$;
grant execute on all functions in schema test to authenticated;
insert into public.car_clients (name, status) values ('Ann', 'active'), ('Ben', 'active'), ('Cal', 'active'), ('Dee', 'active');
insert into public.client_locations (client_id, label, address, approved) select id, 'House', '5 Shared St', true from public.car_clients;
-- SIL for Ann, Ben and Dee (catalogue); Cal only has gardening (custom).
insert into public.client_services (catalogue_id, client_id, program_id, label, start_date, location_id)
select (select id from public.service_catalogue where name = 'Supported Independent Living (SIL)'), c.id, (select id from public.client_programs where name = 'NDIS'), 'x', current_date, l.id
  from public.car_clients c join public.client_locations l on l.client_id = c.id where c.name in ('Ann', 'Ben', 'Dee');
update public.client_services set status = 'on_hold' where client_id = test.cid('Dee');
insert into public.client_services (origin, client_id, program_id, label, description, shift_types, start_date, location_id)
select 'custom', c.id, (select id from public.client_programs where name = 'Private'), 'Garden help', 'Garden.', '{gardening}', current_date, l.id
  from public.car_clients c join public.client_locations l on l.client_id = c.id where c.name = 'Cal';
insert into public.client_alerts (client_id, kind, title, severity) values (test.cid('Ben'), 'medical', 'Epilepsy', 'high');

select test.act_as('boss@example.com');
set role authenticated;
insert into public.shifts (worker_id, client_id, service_id, location_id, starts_at, ends_at, status, shift_type)
select test.pid('sam@example.com'), test.cid('Ann'), test.svc('Ann'), l.id, now() + interval '1 day', now() + interval '1 day 8 hours', 'published', 'personal_care'
  from public.client_locations l where l.client_id = test.cid('Ann');
insert into public.shift_residents (shift_id, client_id, service_id) values (test.sid(), test.cid('Ben'), test.svc('Ben'));
select test.ok((select count(*) from public.shift_residents) = 1, 'a resident whose approved service covers the shift type is added');
select test.refused($$insert into public.shift_residents (shift_id, client_id, service_id) values (test.sid(), test.cid('Cal'), test.svc('Cal'))$$, 'a resident whose service doesn''t cover the shift type is refused');
select test.refused($$insert into public.shift_residents (shift_id, client_id, service_id) values (test.sid(), test.cid('Dee'), test.svc('Dee'))$$, 'a resident whose service is suspended is refused');
select test.refused($$insert into public.shift_residents (shift_id, client_id, service_id) values (test.sid(), test.cid('Ann'), test.svc('Ann'))$$, 'the main client isn''t added twice');
select test.refused($$insert into public.shift_residents (shift_id, client_id, service_id) values (test.sid(), test.cid('Ben'), test.svc('Ann'))$$, 'the service must be the resident''s own');
select test.refused($$update public.shifts set shift_type = 'gardening' where id = test.sid()$$, 'the shift type can''t change to one a resident isn''t approved for');
select test.ok((select count(*) from public.shift_events where field = 'Residents') = 1, 'adding a resident is logged');
reset role;

select test.act_as('sam@example.com');
set role authenticated;
select test.ok((select count(*) from public.shift_residents) = 1, 'the worker sees the residents on their shift');
select test.ok((select count(*) from public.car_clients where name = 'Ben') = 1, 'and the resident''s name');
select test.ok((select count(*) from public.client_alerts where title = 'Epilepsy') = 1, 'and their current alerts');
select test.refused($$insert into public.shift_residents (shift_id, client_id, service_id) values (test.sid(), test.cid('Cal'), test.svc('Cal'))$$, 'workers can''t add residents');
reset role;
select test.act_as('kim@example.com');
set role authenticated;
select test.ok((select count(*) from public.shift_residents) = 0 and (select count(*) from public.car_clients where name = 'Ben') = 0, 'other workers see neither');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
delete from public.shift_residents where client_id = test.cid('Ben');
select test.ok((select count(*) from public.shift_events where field = 'Residents' and summary like 'removed%') = 1, 'removing a resident is logged');
reset role;
\o
select 'All house rostering tests passed.';
