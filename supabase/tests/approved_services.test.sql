-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 143): approved services and the service catalogue.
\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null
insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('boss@example.com', 'Morgan', 'manager'), ('sam@example.com', 'Sam', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('sam@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.cat(p_name text) returns uuid language sql security definer as $$ select id from public.service_catalogue where name = p_name $$;
create function test.cid() returns uuid language sql security definer as $$ select id from public.car_clients where name = 'Zara' $$;
create function test.loc() returns uuid language sql security definer as $$ select id from public.client_locations limit 1 $$;
create function test.prog(p text) returns uuid language sql security definer as $$ select id from public.client_programs where name = p $$;
create function test.svc(p text) returns uuid language sql security definer as $$ select id from public.client_services where label = p $$;
grant execute on all functions in schema test to authenticated;
insert into public.car_clients (name, status) values ('Zara', 'active');
insert into public.client_locations (client_id, label, address, approved) values (test.cid(), 'Home', '1 Test St', true);

-- The catalogue.
select test.ok((select count(*) from public.service_catalogue where name in ('Community Access', 'Shopping Assistance')) = 2, 'Community Access and Shopping Assistance are separate entries');
select test.ok(not exists (select 1 from public.service_catalogue where name ilike '%shopping%' and name ilike '%community%'), 'no combined entry');
select test.act_as('boss@example.com');
set role authenticated;
select test.ok((select count(*) from public.service_catalogue) >= 7, 'staff read the catalogue');
select test.refused($$insert into public.service_catalogue (name) values ('Made up')$$, 'only Manager Administrators add to the catalogue');
select test.refused($$update public.service_catalogue set active = false where name = 'Gardening'$$, 'or switch services off');
-- Adding services to a client.
insert into public.client_services (catalogue_id, client_id, program_id, label, start_date, location_id)
values (test.cat('Shopping Assistance'), test.cid(), test.prog('Private'), 'Anything typed', current_date, test.loc());
select test.ok((select label || '|' || description || '|' || origin from public.client_services where catalogue_id = test.cat('Shopping Assistance')) = 'Shopping Assistance|Assistance with shopping activities and related support.|catalogue', 'a catalogue service takes its name and description, and records where it came from');
select test.refused($$insert into public.client_services (catalogue_id, client_id, program_id, label, start_date, location_id) values (test.cat('Shopping Assistance'), test.cid(), test.prog('Private'), 'x', current_date, test.loc())$$, 'the same service twice under one program is refused');
select test.refused($$update public.client_services set label = 'Renamed' where catalogue_id = test.cat('Shopping Assistance')$$, 'a catalogue service keeps its name');
select test.refused($$insert into public.client_services (client_id, program_id, label, start_date, location_id) values (test.cid(), test.prog('Private'), 'Typed in', current_date, test.loc())$$, 'people choose the catalogue or add a custom service');
select test.refused($$insert into public.client_services (origin, client_id, program_id, label, description, start_date, location_id) values ('custom', test.cid(), test.prog('Private'), 'Pet care', 'Walking the dog.', current_date, test.loc())$$, 'a custom service needs its shift types');
select test.refused($$insert into public.client_services (origin, client_id, program_id, label, shift_types, start_date, location_id) values ('custom', test.cid(), test.prog('Private'), 'Pet care', '{domestic}', current_date, test.loc())$$, 'and a description');
select test.refused($$insert into public.client_services (origin, client_id, program_id, label, description, shift_types, start_date, location_id) values ('custom', test.cid(), test.prog('Private'), 'Pet care', 'Walking the dog.', '{admin}', current_date, test.loc())$$, 'only client shift types');
insert into public.client_services (origin, client_id, program_id, label, description, shift_types, start_date, location_id)
values ('custom', test.cid(), test.prog('Private'), 'Pet care', 'Walking the dog.', '{domestic}', current_date, test.loc());
select test.ok((select origin from public.client_services where label = 'Pet care') = 'custom', 'a custom service is saved for this client');
select test.ok(not exists (select 1 from public.service_catalogue where name = 'Pet care'), 'and isn''t added to the catalogue');
reset role;

-- Promoting a custom service and switching a catalogue service off (system admin).
select test.act_as('owner@example.com');
set role authenticated;
insert into public.service_catalogue (name, description, shift_types, promoted_from) select label, description, shift_types, id from public.client_services where label = 'Pet care';
update public.service_catalogue set active = false where name = 'Shopping Assistance';
reset role;
select test.ok((select origin || '|' || description from public.client_services where label = 'Pet care') = 'custom|Walking the dog.', 'promoting keeps the custom service as it was');
select test.ok(exists (select 1 from public.client_services where catalogue_id = test.cat('Shopping Assistance')), 'switching a catalogue service off keeps client services');
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$insert into public.client_services (catalogue_id, client_id, program_id, label, start_date, location_id) values (test.cat('Shopping Assistance'), test.cid(), test.prog('NDIS'), 'x', current_date, test.loc())$$, 'a switched-off service can''t be newly chosen');

-- Rostering: the shift type must be covered by the approved service.
select test.refused($$insert into public.shifts (worker_id, client_id, service_id, location_id, starts_at, ends_at, status, shift_type) values (test.pid('sam@example.com'), test.cid(), test.svc('Shopping Assistance'), test.loc(), now() + interval '1 day', now() + interval '1 day 2 hours', 'draft', 'personal_care')$$, 'a shift type the service doesn''t cover is refused');
insert into public.shifts (worker_id, client_id, service_id, location_id, starts_at, ends_at, status, shift_type) values (test.pid('sam@example.com'), test.cid(), test.svc('Shopping Assistance'), test.loc(), now() + interval '1 day', now() + interval '1 day 2 hours', 'draft', 'shopping_assistance');
select test.ok((select count(*) from public.shifts) = 1, 'a covered shift type is allowed');
update public.client_services set status = 'on_hold' where label = 'Pet care';
select test.refused($$insert into public.shifts (worker_id, client_id, service_id, location_id, starts_at, ends_at, status, shift_type) values (test.pid('sam@example.com'), test.cid(), test.svc('Pet care'), test.loc(), now() + interval '2 days', now() + interval '2 days 2 hours', 'draft', 'domestic')$$, 'a suspended service can''t be rostered');
update public.client_services set status = 'planned', end_date = current_date where label = 'Pet care';
select test.refused($$insert into public.shifts (worker_id, client_id, service_id, location_id, starts_at, ends_at, status, shift_type) values (test.pid('sam@example.com'), test.cid(), test.svc('Pet care'), test.loc(), now() + interval '3 days', now() + interval '3 days 2 hours', 'draft', 'domestic')$$, 'nor after its end date');
reset role;
-- An older entry with no shift types set isn't restricted.
insert into public.client_services (client_id, program_id, label, start_date, location_id) values (test.cid(), test.prog('NDIS'), 'Older entry', current_date, test.loc());
select test.act_as('boss@example.com');
set role authenticated;
insert into public.shifts (worker_id, client_id, service_id, location_id, starts_at, ends_at, status, shift_type) values (test.pid('sam@example.com'), test.cid(), test.svc('Older entry'), test.loc(), now() + interval '4 days', now() + interval '4 days 2 hours', 'draft', 'gardening');
select test.ok((select count(*) from public.shifts) = 2, 'an older entry with no shift types set isn''t restricted');
reset role;
select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$update public.service_catalogue set description = 'x'$$, 'support workers can''t change the catalogue');
reset role;
\o
select 'All approved services tests passed.';
